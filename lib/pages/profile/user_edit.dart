import 'package:flutter/material.dart';
import 'package:green_books/widgets/profile/edit_field_form.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditFieldPage extends StatefulWidget {
  final String fieldLabel;
  final String firestoreKey;
  final String fieldType; // 'username', 'email', 'dropdown', or default
  final List<String>? dropdownOptions;

  const EditFieldPage({
    super.key,
    required this.fieldLabel,
    required this.firestoreKey,
    required this.fieldType,
    this.dropdownOptions,
  });

  @override
  State<EditFieldPage> createState() => _EditFieldPageState();
}

class _EditFieldPageState extends State<EditFieldPage> {
  String initialValue = '';
  bool isLoading = true;

  Future<void> _fetchInitialValue() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      setState(() {
        initialValue = '';
        isLoading = false;
      });
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!mounted) return;
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          initialValue = (data[widget.firestoreKey] ?? '').toString();
          isLoading = false;
        });
      } else {
        setState(() {
          initialValue = '';
          isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        initialValue = '';
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchInitialValue();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 100),
                    Text(
                      'Edit ${widget.fieldLabel}',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    EditFieldForm(
                      fieldLabel: widget.fieldLabel,
                      firestoreKey: widget.firestoreKey,
                      initialValue: initialValue,
                      fieldType: widget.fieldType,
                      dropdownOptions: widget.dropdownOptions,
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
      ),
    );
  }
}
