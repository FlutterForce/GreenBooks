import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:green_books/navigation/navigation_wrapper.dart';
import 'package:green_books/notifiers/profile_image_notifier.dart';
import 'package:green_books/pages/auth/sign_up_email_password.dart';
import 'package:green_books/widgets/common/custom_field_button.dart';
import 'package:green_books/widgets/common/text_fields.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LoginPage extends StatefulWidget {
  final void Function(bool)? onThemeChanged;
  final ThemeMode themeMode;

  const LoginPage({
    super.key,
    this.onThemeChanged,
    this.themeMode = ThemeMode.light,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final LocalAuthentication auth = LocalAuthentication();
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  bool rememberMe = false;
  Color buttonColor = const Color(0xFFDDA15E);

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();
    emailController.addListener(_updateButtonColor);
    passwordController.addListener(_updateButtonColor);
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('saved_email');
    final savedRemember = prefs.getBool('remember_me') ?? false;
    if (!mounted) return;
    if (savedEmail != null && savedRemember) {
      setState(() {
        emailController.text = savedEmail;
        rememberMe = true;
      });
    }
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (rememberMe) {
      await prefs.setString('saved_email', emailController.text.trim());
      await prefs.setBool('remember_me', true);
    } else {
      await prefs.remove('saved_email');
      await prefs.setBool('remember_me', false);
    }
  }

  void _updateButtonColor() {
    setState(() {
      buttonColor =
          (emailController.text.isNotEmpty &&
              passwordController.text.isNotEmpty)
          ? const Color(0xFFBC6C25)
          : const Color(0xFFDDA15E);
    });
  }

  Future<void> login() async {
    try {
      final email = emailController.text.trim();
      final password = passwordController.text.trim();

      await _savePreferences();

      await secureStorage.write(key: 'email', value: email);
      await secureStorage.write(key: 'password', value: password);

      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      final uid = userCredential.user?.uid;
      if (uid == null) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'User ID not found.',
        );
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (!userDoc.exists) {
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User data not found. Please sign up.')),
        );
        return;
      }

      final data = userDoc.data()!;
      final profileUrl = data['profilePicUrl'] as String?;
      profileImageNotifier.value = (profileUrl != null && profileUrl.isNotEmpty)
          ? profileUrl
          : null;

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => NavigationWrapper()),
      );

      final posts = await FirebaseFirestore.instance.collection('posts').get();
      for (final doc in posts.docs) {
        if (doc.data().containsKey('thumbnailUrl')) {
          await doc.reference.update({'thumbnailUrl': FieldValue.delete()});
          debugPrint('Deleted thumbnailUrl from ${doc.id}');
        }
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message ?? 'Login failed')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unexpected error: $e')));
    }
  }

  Future<void> _triggerBiometricLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final biometricEnabled = prefs.getBool('biometric_enabled') ?? false;

    if (!biometricEnabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Biometric login is disabled in Settings'),
        ),
      );
      return;
    }

    try {
      final canCheckBiometrics = await auth.canCheckBiometrics;
      if (!canCheckBiometrics) return;

      final isAuthenticated = await auth.authenticate(
        localizedReason: 'Login using fingerprint or face ID',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (!isAuthenticated || !mounted) return;

      final storedEmail = await secureStorage.read(key: 'email');
      final storedPassword = await secureStorage.read(key: 'password');

      if (!mounted) return;

      if (storedEmail != null && storedPassword != null) {
        emailController.text = storedEmail;
        passwordController.text = storedPassword;
        await login();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No saved credentials. Please login manually once.'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Biometric login error: $e')));
    }
  }

  void _forgotPassword() {
    if (emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email first')),
      );
      return;
    }

    FirebaseAuth.instance
        .sendPasswordResetEmail(email: emailController.text.trim())
        .then((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password reset email sent')),
          );
        })
        .catchError((error) {
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: ${error.message}')));
        });
  }

  void goToRegisterPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SignUpPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoginEnabled =
        emailController.text.isNotEmpty && passwordController.text.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 100),
              const Text(
                'Welcome to GreenBooks',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              MyTextField(controller: emailController, hintText: 'Email'),
              const SizedBox(height: 10),
              MyTextField(
                controller: passwordController,
                hintText: 'Password',
                obscureText: true,
              ),
              const SizedBox(height: 10),
              CustomFieldButton(
                onPressed: isLoginEnabled ? login : null,
                label: 'Login',
                backgroundColor: buttonColor,
                isEnabled: isLoginEnabled,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Checkbox(
                    value: rememberMe,
                    onChanged: (val) {
                      setState(() => rememberMe = val ?? false);
                    },
                  ),
                  const Text('Remember me'),
                  const Spacer(),
                  GestureDetector(
                    onTap: _forgotPassword,
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: Color(0xFFBC6C25),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(
                      Icons.fingerprint,
                      size: 32,
                      color: Color(0xFFBC6C25),
                    ),
                    onPressed: _triggerBiometricLogin,
                    tooltip: 'Login with biometrics',
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don't have an account? ",
                    style: TextStyle(color: Colors.black),
                  ),
                  GestureDetector(
                    onTap: goToRegisterPage,
                    child: const Text(
                      'Sign up',
                      style: TextStyle(
                        color: Color(0xFFBC6C25),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
