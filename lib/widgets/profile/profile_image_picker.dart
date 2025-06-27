import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProfileImagePicker extends StatelessWidget {
  final File? image;
  final String? profileUrl;
  final VoidCallback onPickImage;
  final double radius;

  const ProfileImagePicker({
    super.key,
    required this.image,
    required this.profileUrl,
    required this.onPickImage,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPickImage,
      child: CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey,
        foregroundImage: image != null
            ? FileImage(image!)
            : (profileUrl != null && profileUrl!.isNotEmpty
                  ? CachedNetworkImageProvider(profileUrl!)
                  : null),
        child: (image == null && (profileUrl == null || profileUrl!.isEmpty))
            ? const Icon(Icons.camera_alt, color: Colors.white, size: 30)
            : null,
      ),
    );
  }
}
