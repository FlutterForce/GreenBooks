import 'package:flutter/material.dart';

class BookImpactLine extends StatelessWidget {
  final int count;
  final String prefix;
  final String suffix;
  final Color color;
  final IconData icon;

  const BookImpactLine({
    super.key,
    required this.count,
    required this.prefix,
    required this.suffix,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text.rich(
            TextSpan(
              style: const TextStyle(
                fontSize: 18,
                decoration: TextDecoration.none,
              ),
              children: [
                TextSpan(
                  text: '$count $prefix',
                  style: const TextStyle(color: Colors.black),
                ),
                TextSpan(
                  text: suffix,
                  style: TextStyle(color: color),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
