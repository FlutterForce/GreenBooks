import 'package:flutter/material.dart';

// Custom expansion tile with no animation and no ripple effect
class NoAnimExpansionTile extends StatefulWidget {
  final Widget title;
  final List<Widget> children;

  const NoAnimExpansionTile({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  State<NoAnimExpansionTile> createState() => _NoAnimExpansionTileState();
}

class _NoAnimExpansionTileState extends State<NoAnimExpansionTile> {
  bool _isExpanded = false;

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: widget.title,
            trailing: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
            onTap: _toggleExpanded,
            contentPadding: EdgeInsets.zero,
          ),
          if (_isExpanded) ...widget.children,
        ],
      ),
    );
  }
}

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textColor = Colors.black;
    final subtitleColor = textColor.withAlpha((0.7 * 255).round());

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Help',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(32),
          children: [
            NoAnimExpansionTile(
              title: Text(
                'How do I sell books or papers?',
                style: TextStyle(color: textColor),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 12),
                  child: Text(
                    'Press the "+" icon and fill out the form to list your item.',
                    style: TextStyle(color: subtitleColor),
                  ),
                ),
              ],
            ),
            NoAnimExpansionTile(
              title: Text(
                'Where can I recycle old papers?',
                style: TextStyle(color: textColor),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 12),
                  child: Text(
                    'Use the map feature in the home page to find nearby recycling centers.',
                    style: TextStyle(color: subtitleColor),
                  ),
                ),
              ],
            ),
            NoAnimExpansionTile(
              title: Text(
                'How do I contact support?',
                style: TextStyle(color: textColor),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 12),
                  child: Text(
                    'You can email us at greenbooksegypt@gmail.com or reach out through the contact form.',
                    style: TextStyle(color: subtitleColor),
                  ),
                ),
              ],
            ),
            NoAnimExpansionTile(
              title: Text(
                'Can I change my account details?',
                style: TextStyle(color: textColor),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 12),
                  child: Text(
                    'Yes, under "My Account" you can update your profile and password.',
                    style: TextStyle(color: subtitleColor),
                  ),
                ),
              ],
            ),
            NoAnimExpansionTile(
              title: Text(
                'How do I turn on Dark Mode?',
                style: TextStyle(color: textColor),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 12),
                  child: Text(
                    'Go to Settings and use the toggle next to "Dark Mode" to switch themes.',
                    style: TextStyle(color: subtitleColor),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
