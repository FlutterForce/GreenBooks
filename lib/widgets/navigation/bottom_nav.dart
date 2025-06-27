import 'dart:io';
import 'package:flutter/material.dart';
import 'profile_nav_icon.dart';
import 'package:green_books/notifiers/profile_image_notifier.dart';
import 'package:green_books/notifiers/profile_image_file_notifier.dart';
import 'package:green_books/navigation/navigation_wrapper.dart';

class BottomNav extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTapped;

  const BottomNav({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  @override
  Widget build(BuildContext context) {
    final List<IconData> icons = [
      Icons.home_rounded,
      Icons.bar_chart_rounded,
      Icons.add_circle,
      Icons.recycling_rounded,
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ...List.generate(icons.length, (index) {
            return GestureDetector(
              onTap: () => widget.onItemTapped(index),
              child: Icon(
                icons[index],
                size: 40,
                color: widget.selectedIndex == index
                    ? Colors.green
                    : Colors.black,
              ),
            );
          }),
          ValueListenableBuilder<File?>(
            valueListenable: profileImageFileNotifier,
            builder: (context, fileImage, _) {
              return ValueListenableBuilder<String?>(
                valueListenable: profileImageNotifier,
                builder: (context, imageUrl, _) {
                  return ProfileNavIcon(
                    isSelected: widget.selectedIndex == AppTab.profile.index,
                    onTap: () => widget.onItemTapped(AppTab.profile.index),
                    profileImageUrl: imageUrl,
                    fileImage: fileImage,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
