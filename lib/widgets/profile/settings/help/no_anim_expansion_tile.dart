import 'package:flutter/material.dart';

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
