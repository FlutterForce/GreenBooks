// widgets/profile/edit_field_form.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:green_books/widgets/common/text_fields.dart';
import 'package:green_books/pages/auth/log_in.dart';

class EditFieldForm extends StatefulWidget {
  final String fieldLabel;
  final String firestoreKey;
  final String initialValue;
  final String fieldType;
  final List<String>? dropdownOptions;

  const EditFieldForm({
    super.key,
    required this.fieldLabel,
    required this.firestoreKey,
    required this.initialValue,
    required this.fieldType,
    this.dropdownOptions,
  });

  @override
  State<EditFieldForm> createState() => _EditFieldFormState();
}

class _EditFieldFormState extends State<EditFieldForm> {
  final TextEditingController controller = TextEditingController();
  final TextEditingController reenterEmailController = TextEditingController();

  bool isSaving = false;
  String errorText = '';
  late String? selectedDropdownValue;

  bool get isEmailChanged =>
      widget.fieldType == 'email' &&
      controller.text.trim() != widget.initialValue.trim();

  bool get isEmailMatch =>
      controller.text.trim() == reenterEmailController.text.trim();

  @override
  void initState() {
    super.initState();
    controller.text = widget.initialValue.isNotEmpty ? widget.initialValue : '';
    controller.addListener(() => setState(() {}));
    reenterEmailController.addListener(() => setState(() {}));
    if (widget.dropdownOptions != null) {
      selectedDropdownValue =
          (widget.initialValue.isNotEmpty &&
              widget.dropdownOptions!.contains(widget.initialValue))
          ? widget.initialValue
          : null;
    }
  }

  @override
  void dispose() {
    controller.dispose();
    reenterEmailController.dispose();
    super.dispose();
  }

  String getCustomHintText() {
    switch (widget.firestoreKey) {
      case 'username':
        return 'Choose a unique username';
      case 'email':
        return 'Enter your new email';
      case 'name':
        return 'Enter your name';
      case 'gender':
        return 'Choose your gender';
      case 'socialLinks':
        return 'Add your website or social media';
      default:
        return 'Enter your information';
    }
  }

  Future<void> saveChanges() async {
    final user = FirebaseAuth.instance.currentUser;
    final newValue = widget.dropdownOptions != null
        ? selectedDropdownValue ?? ''
        : controller.text.trim();

    if (user == null) return;

    final canBeEmpty = ['name', 'gender', 'socialLinks'];
    if (newValue.isEmpty && !canBeEmpty.contains(widget.firestoreKey)) return;

    if (widget.fieldType == 'email' && !isEmailMatch) {
      setState(() => errorText = 'Emails do not match');
      return;
    }

    setState(() {
      isSaving = true;
      errorText = '';
    });

    try {
      if (widget.fieldType == 'username') {
        final exists = await FirebaseFirestore.instance
            .collection('users')
            .where('username', isEqualTo: newValue)
            .get();
        if (!mounted) return;
        if (exists.docs.isNotEmpty && newValue != widget.initialValue) {
          setState(() => errorText = 'Username already taken');
          return;
        }
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({widget.firestoreKey: newValue});
        if (mounted) Navigator.pop(context);
        return;
      }

      if (widget.fieldType == 'email') {
        if (newValue != user.email) {
          try {
            await user.verifyBeforeUpdateEmail(newValue);
            if (!mounted) return;
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const LoginPage()),
            );
            return;
          } on FirebaseAuthException catch (e) {
            setState(() {
              errorText = e.message ?? 'Failed to update email';
            });
            return;
          }
        } else {
          if (mounted) Navigator.pop(context);
          return;
        }
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {widget.firestoreKey: newValue},
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => errorText = 'Something went wrong');
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canBeEmpty = ['name', 'gender', 'socialLinks'];
    final allowEmpty = canBeEmpty.contains(widget.firestoreKey);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isFilled = widget.dropdownOptions != null
        ? (selectedDropdownValue?.isNotEmpty ?? false)
        : controller.text.trim().isNotEmpty;
    final isReenterFilled = reenterEmailController.text.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.dropdownOptions != null) ...[
          DropdownButtonFormField<String>(
            value: selectedDropdownValue,
            hint: Text(getCustomHintText()),
            onChanged: (value) {
              if (value != null) {
                setState(() => selectedDropdownValue = value);
              }
            },
            items: widget.dropdownOptions!.map((option) {
              return DropdownMenuItem(value: option, child: Text(option));
            }).toList(),
            decoration: InputDecoration(
              filled: true,
              fillColor: isDark ? Colors.grey[800] : Colors.grey[200],
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ] else ...[
          MyTextField(controller: controller, hintText: getCustomHintText()),
          if (widget.fieldType == 'email') ...[
            const SizedBox(height: 9),
            MyTextField(
              controller: reenterEmailController,
              hintText: 'Re-enter new email',
            ),
            if (isEmailChanged)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'After clicking "Save Changes" you will need to:\n1. Verify your new email.\n2. Sign in again.',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ],
        if (errorText.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(errorText, style: const TextStyle(color: Colors.red)),
        ],
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed:
              ((isFilled || allowEmpty) &&
                  !isSaving &&
                  (widget.fieldType != 'email' ||
                      (isReenterFilled && isEmailMatch)))
              ? saveChanges
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFBC6C25),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: isSaving
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text(
                  'Save Changes',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}
