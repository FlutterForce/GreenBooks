import 'package:flutter/material.dart';
import 'package:green_books/pages/auth/log_in.dart';
import 'package:green_books/pages/profile/settings/help.dart';
import 'package:green_books/pages/profile/settings/my_purchases.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final Color textColor = Colors.black;
  bool isBiometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadBiometricPreference();
  }

  Future<void> _loadBiometricPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isBiometricEnabled = prefs.getBool('biometric_enabled') ?? false;
    });
  }

  Future<void> _toggleBiometric(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_enabled', value);
    setState(() {
      isBiometricEnabled = value;
    });
  }

  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  // Slide from right route helper
  Route _createSlideRightRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.ease;

        final tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));

        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: ListView(
            children: [
              SwitchListTile(
                value: isBiometricEnabled,
                onChanged: _toggleBiometric,
                activeColor: Colors.green, // active color when ON
                inactiveThumbColor:
                    Colors.grey.shade400, // thumb color when OFF (grayscale)
                inactiveTrackColor: Colors
                    .grey
                    .shade200, // track color when OFF (lighter grayscale)
                title: Text(
                  'Enable Biometric Login',
                  style: TextStyle(color: textColor),
                ),
                subtitle: Text(
                  'Use fingerprint or face ID to log in',
                  style: TextStyle(color: textColor.withAlpha(179)),
                ),
                secondary: Icon(Icons.fingerprint, color: textColor),
              ),

              ListTile(
                leading: Icon(Icons.shopping_bag, color: textColor),
                title: Text('My Purchases', style: TextStyle(color: textColor)),
                subtitle: Text(
                  'Your Purchase History',
                  style: TextStyle(color: textColor.withAlpha(179)),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    _createSlideRightRoute(const MyOrdersPage()),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.help_outline, color: textColor),
                title: Text('Help', style: TextStyle(color: textColor)),
                subtitle: Text(
                  'Get Support or FAQs',
                  style: TextStyle(color: textColor.withAlpha(179)),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    _createSlideRightRoute(const HelpPage()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Log Out',
                  style: TextStyle(color: Colors.red),
                ),
                subtitle: Text(
                  'Log Out From The App',
                  style: TextStyle(color: Colors.red.withAlpha(179)),
                ),
                onTap: _logout, // Usually no transition on logout (removes all)
              ),
            ],
          ),
        ),
      ),
    );
  }
}
