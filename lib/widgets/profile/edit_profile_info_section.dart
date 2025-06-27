import 'package:flutter/material.dart';
import 'package:green_books/pages/profile/user_edit.dart';
import 'package:url_launcher/url_launcher.dart';

class EditProfileInfoSection extends StatefulWidget {
  final Map<String, dynamic> data;
  final Function() onRefresh;

  const EditProfileInfoSection({
    super.key,
    required this.data,
    required this.onRefresh,
  });

  @override
  State<EditProfileInfoSection> createState() => _EditProfileInfoSectionState();
}

class _EditProfileInfoSectionState extends State<EditProfileInfoSection> {
  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url.trim());
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch the link')),
      );
    }
  }

  Widget _buildEditableField(
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
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
          ),
          GestureDetector(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditFieldPage(
                    fieldLabel: label,
                    firestoreKey: firestoreKey,
                    fieldType: fieldType,
                    dropdownOptions: dropdownOptions,
                  ),
                ),
              );
              if (mounted) widget.onRefresh();
            },
            child: Icon(Icons.edit_rounded, size: 24, color: textColor),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildEditableField(
          'Name',
          widget.data['name'].isNotEmpty
              ? widget.data['name']
              : 'Choose your Name', // this is just for display on profile page
          Icons.badge_rounded,
          'name',
          'text',
        ),
        _buildEditableField(
          'Username',
          widget.data['username'],
          Icons.person,
          'username',
          'username',
        ),
        _buildEditableField(
          'Email',
          widget.data['email'],
          Icons.email,
          'email',
          'email',
        ),
        _buildEditableField(
          'Gender',
          widget.data['gender'].isNotEmpty
              ? widget.data['gender']
              : 'Choose your gender', // this is just for display on profile page
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

        _buildEditableField(
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
