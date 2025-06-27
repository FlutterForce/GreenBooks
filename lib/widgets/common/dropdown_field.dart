import 'package:flutter/material.dart';

class MyDropdownField extends StatelessWidget {
  final List<String> items;
  final String? value;
  final String hintText;
  final void Function(String?) onChanged;

  const MyDropdownField({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
    this.hintText = 'Select an option',
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true, // ✅ Prevents overflow
      items: items
          .map(
            (item) => DropdownMenuItem(
              value: item,
              child: Text(
                item,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                  color: Colors.black,
                ),
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: Colors.grey[200],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 20,
        ),
      ),
      dropdownColor: Colors.grey[200],
      borderRadius: BorderRadius.circular(20),
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: Colors.black,
      ),
    );
  }
}
