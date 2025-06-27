import 'package:flutter/material.dart';

class CustomButtonStyles {
  static ButtonStyle uploadButtonStyle() {
    return ElevatedButton.styleFrom(
      elevation: 0,
      backgroundColor: Colors.grey[200],
      foregroundColor: Colors.black,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  static ButtonStyle confirmButtonStyle() {
    return ElevatedButton.styleFrom(
      elevation: 0,
      backgroundColor: Colors.green[600],
      foregroundColor: Colors.white,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }
}
