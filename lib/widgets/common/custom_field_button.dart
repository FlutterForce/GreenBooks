import 'package:flutter/material.dart';

class CustomFieldButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final Color backgroundColor;
  final bool isEnabled;

  const CustomFieldButton({
    super.key,
    required this.onPressed,
    required this.label,
    required this.backgroundColor,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity, // Ensures full width
      child: ElevatedButton(
        onPressed: isEnabled ? onPressed : null,
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
            return backgroundColor;
          }),
          foregroundColor: WidgetStateProperty.all(Colors.white),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(vertical: 16),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
        ),
        child: Text(label, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}
