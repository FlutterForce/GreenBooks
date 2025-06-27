import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:green_books/widgets/common/text_fields.dart';
import 'package:green_books/navigation/navigation_wrapper.dart';
import 'package:green_books/widgets/common/custom_field_button.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final usernameController = TextEditingController();

  bool showUsernameField = false;
  bool emailSent = false;
  bool attemptedFinalSignup = false;
  int resendCooldown = 0;
  Timer? resendTimer;

  static const int _resendCooldownDuration = 30;

  final Color _enabledColor = const Color(0xFFBC6C25);
  final Color _disabledColor = const Color(0xFFDDA15E);

  @override
  void initState() {
    super.initState();
    emailController.addListener(_onInputChanged);
    passwordController.addListener(_onInputChanged);
    confirmPasswordController.addListener(_onInputChanged);
    usernameController.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    usernameController.dispose();
    resendTimer?.cancel();
    super.dispose();
  }

  void _onInputChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _goToLoginPage() => Navigator.pop(context);

  bool get _canContinue =>
      emailController.text.isNotEmpty &&
      passwordController.text.isNotEmpty &&
      confirmPasswordController.text.isNotEmpty;

  bool get _canSubmitUsername => usernameController.text.isNotEmpty;

  Future<void> _handleContinue() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();
    final messenger = ScaffoldMessenger.of(context);

    if (password != confirmPassword) {
      messenger.showSnackBar(
        const SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await FirebaseAuth.instance.currentUser?.delete();

      if (!mounted) return;
      setState(() => showUsernameField = true);
    } on FirebaseAuthException catch (e) {
      final message = switch (e.code) {
        'email-already-in-use' => 'This email is already registered.',
        'weak-password' => 'The password is too weak.',
        _ => 'Sign-up failed',
      };
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _handleUsernameStep() async {
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    final username = usernameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    try {
      final existingUser = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (existingUser.docs.isNotEmpty) {
        messenger.showSnackBar(
          const SnackBar(content: Text("Username already taken")),
        );
        return;
      }

      User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        user = cred.user;
      }

      await user!.reload();
      user = FirebaseAuth.instance.currentUser;

      if (user == null || !user.emailVerified) {
        await user?.sendEmailVerification(); // safer
        setState(() {
          emailSent = true;
          resendCooldown = _resendCooldownDuration;
          attemptedFinalSignup = true;
        });
        _startResendCooldown();
        messenger.showSnackBar(
          const SnackBar(content: Text("Verification email sent")),
        );
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'name': '',
          'username': username,
          'gender': null,
          'profilePicUrl': '',
          'documentsBought': 0,
          'documentsSold': 0,
          'documentsAcquired': 0,
          'documentsDonated': 0,
          'documentsRecycled': 0,
          'pagesRecycled': 0,
          'socialLinks': '',
        });
      }

      nav.pushReplacement(
        MaterialPageRoute(builder: (_) => NavigationWrapper()),
      );
    } on FirebaseAuthException catch (e) {
      final message = switch (e.code) {
        'email-already-in-use' => 'This email is already registered.',
        'weak-password' => 'The password is too weak.',
        _ => 'Sign-up failed',
      };
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _resendVerificationEmail() async {
    final messenger = ScaffoldMessenger.of(context);
    final user = FirebaseAuth.instance.currentUser;

    if (user != null && !user.emailVerified && resendCooldown == 0) {
      await user.sendEmailVerification();
      messenger.showSnackBar(
        const SnackBar(content: Text("Verification email resent")),
      );
      setState(() => resendCooldown = _resendCooldownDuration);
      _startResendCooldown();
    }
  }

  void _startResendCooldown() {
    resendTimer?.cancel();
    resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      setState(() {
        if (resendCooldown > 0) {
          resendCooldown--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Column(
            children: [
              const SizedBox(height: 100),
              Text(
                showUsernameField
                    ? 'Choose a Username'
                    : 'Sign up to GreenBooks!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              if (!showUsernameField) ...[
                MyTextField(controller: emailController, hintText: 'Email'),
                const SizedBox(height: 10),
                MyTextField(
                  controller: passwordController,
                  hintText: 'Password',
                  obscureText: true,
                ),
                const SizedBox(height: 10),
                MyTextField(
                  controller: confirmPasswordController,
                  hintText: 'Confirm Password',
                  obscureText: true,
                ),
                const SizedBox(height: 10),
                CustomFieldButton(
                  onPressed: _handleContinue,
                  label: 'Continue',
                  backgroundColor: _canContinue
                      ? _enabledColor
                      : _disabledColor,
                  isEnabled: _canContinue,
                ),
              ] else ...[
                MyTextField(
                  controller: usernameController,
                  hintText: 'Username',
                ),
                const SizedBox(height: 10),
                if (emailSent || attemptedFinalSignup)
                  CustomFieldButton(
                    onPressed: _resendVerificationEmail,
                    label: resendCooldown == 0
                        ? 'Resend Verification Email'
                        : 'Resend available in $resendCooldown s',
                    backgroundColor: resendCooldown == 0
                        ? _enabledColor
                        : _disabledColor,
                    isEnabled: resendCooldown == 0,
                  ),
                if (emailSent || attemptedFinalSignup)
                  const SizedBox(height: 10),
                CustomFieldButton(
                  onPressed: _handleUsernameStep,
                  label: 'Sign Up',
                  backgroundColor: _canSubmitUsername
                      ? _enabledColor
                      : _disabledColor,
                  isEnabled: _canSubmitUsername,
                ),
              ],
              const SizedBox(height: 20),
              if (!showUsernameField)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: TextStyle(color: textColor),
                    ),
                    GestureDetector(
                      onTap: _goToLoginPage,
                      child: const Text(
                        'Login Now',
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
