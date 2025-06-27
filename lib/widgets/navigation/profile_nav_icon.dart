import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProfileNavIcon extends StatefulWidget {
  final bool isSelected;
  final VoidCallback onTap;
  final String? profileImageUrl;
  final File? fileImage;

  const ProfileNavIcon({
    super.key,
    required this.isSelected,
    required this.onTap,
    required this.profileImageUrl,
    this.fileImage,
  });

  @override
  State<ProfileNavIcon> createState() => _ProfileNavIconState();
}

class _ProfileNavIconState extends State<ProfileNavIcon> {
  ImageProvider? _imageProvider;

  @override
  void didUpdateWidget(ProfileNavIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    _setupImageProvider();
  }

  @override
  void initState() {
    super.initState();
    _setupImageProvider();
  }

  void _setupImageProvider() {
    if (widget.fileImage != null) {
      _imageProvider = FileImage(widget.fileImage!);
    } else if (widget.profileImageUrl != null &&
        widget.profileImageUrl!.isNotEmpty) {
      _imageProvider = CachedNetworkImageProvider(widget.profileImageUrl!);
    } else {
      _imageProvider = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: 40,
        height: 40,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: widget.isSelected ? Colors.green : Colors.grey,
            width: 3,
          ),
        ),
        child: CircleAvatar(
          radius: 17,
          backgroundImage: _imageProvider,
          backgroundColor: Colors.grey[300],
          child: _imageProvider == null
              ? Icon(
                  Icons.person,
                  size: 20,
                  color: widget.isSelected ? Colors.green : Colors.black,
                )
              : null,
        ),
      ),
    );
  }
}
