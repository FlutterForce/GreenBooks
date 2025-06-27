import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileInfoSection extends StatefulWidget {
  final Map<String, dynamic> data;
  final Function() onRefresh;

  const ProfileInfoSection({
    super.key,
    required this.data,
    required this.onRefresh,
  });

  @override
  State<ProfileInfoSection> createState() => _ProfileInfoSectionState();
}

class _ProfileInfoSectionState extends State<ProfileInfoSection> {
  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url.trim());
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch the link')),
      );
    }
  }

  Widget _buildField(
    String label,
    String value,
    IconData icon,
    String firestoreKey,
    String fieldType, {
    List<String>? dropdownOptions,
    bool isLink = false,
  }) {
    final textColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black;
    final subtitleColor = textColor.withAlpha(179);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: textColor),
        title: Text(label, style: TextStyle(color: subtitleColor)),
        subtitle: isLink
            ? InkWell(
                onTap: () => _launchURL(value),
                child: Text(
                  value,
                  style: const TextStyle(
                    color: Colors.brown,
                    decoration: TextDecoration.underline,
                  ),
                ),
              )
            : Text(value, style: TextStyle(color: textColor)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildField(
          'Name',
          widget.data['name'].isNotEmpty
              ? widget.data['name']
              : 'Choose your Name', // this is just for display on profile page
          Icons.badge_rounded,
          'name',
          'text',
        ),
        _buildField(
          'Username',
          widget.data['username'],
          Icons.person,
          'username',
          'username',
        ),
        _buildField(
          'Email',
          widget.data['email'],
          Icons.email,
          'email',
          'email',
        ),
        _buildField(
          'Gender',
          widget.data['gender'].isNotEmpty
              ? widget.data['gender']
              : 'Choose your gender',

          Icons.transgender_rounded,
          'gender',
          'dropdown',
          dropdownOptions: const [
            'Male',
            'Female',
            'Non-binary',
            'Prefer not to say',
            'Other',
          ],
        ),
        _buildField(
          'Social Links',
          widget.data['socialLinks'].isNotEmpty
              ? widget.data['socialLinks']
              : 'Add Social links',
          Icons.link,
          'socialLinks',
          'text',
          isLink: widget.data['socialLinks'].isNotEmpty,
        ),
      ],
    );
  }
}
