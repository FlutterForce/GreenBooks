import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:green_books/notifiers/profile_image_file_notifier.dart';
import 'package:green_books/notifiers/profile_image_notifier.dart';

class ProfileImageBar extends StatelessWidget {
  final double radius;

  const ProfileImageBar({super.key, required this.radius});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<File?>(
      valueListenable: profileImageFileNotifier,
      builder: (context, file, _) {
        if (file != null) {
          return CircleAvatar(radius: radius, backgroundImage: FileImage(file));
        }

        return ValueListenableBuilder<String?>(
          valueListenable: profileImageNotifier,
          builder: (context, url, _) {
            if (url != null && url.isNotEmpty) {
              return CachedNetworkImage(
                imageUrl: url,
                imageBuilder: (context, imageProvider) => CircleAvatar(
                  radius: radius,
                  backgroundImage: imageProvider,
                ),
                placeholder: (context, url) => CircleAvatar(
                  radius: radius,
                  backgroundColor: Colors.grey[300],
                  child: const CircularProgressIndicator(strokeWidth: 2),
                ),
                errorWidget: (context, url, error) => CircleAvatar(
                  radius: radius,
                  backgroundColor: Colors.grey,
                  child: const Icon(Icons.error),
                ),
              );
            }

            return CircleAvatar(
              radius: radius,
              backgroundColor: Colors.grey,
              child: const Icon(Icons.person),
            );
          },
        );
      },
    );
  }
}
