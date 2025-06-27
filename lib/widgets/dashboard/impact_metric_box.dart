import 'package:flutter/material.dart';

class ImpactMetricBox extends StatelessWidget {
  final String title;
  final String value;
  final Color textColor;
  final Color backgroundColor;
  final double fontSizeValue;
  final double fontSizeTitle;
  final Widget icon;

  const ImpactMetricBox({
    super.key,
    required this.title,
    required this.value,
    required this.textColor,
    required this.backgroundColor,
    required this.fontSizeValue,
    required this.fontSizeTitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          icon,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: fontSizeTitle,
                    color: textColor.withOpacity(0.7),
                    fontWeight: FontWeight.w600,
                  ),
                  softWrap: true,
                  overflow: TextOverflow.visible,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: fontSizeValue,
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                  softWrap: true,
                  overflow: TextOverflow.visible,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
