import 'package:flutter/material.dart';
import 'package:green_books/pages/home/home.dart';
import 'package:green_books/pages/dashboard/dashboard.dart';
import 'package:green_books/pages/post/upload_scan/scan_and_uploud.dart';
import 'package:green_books/pages/centers/nearby_centers.dart';
import 'package:green_books/pages/profile/profile.dart';
import 'package:green_books/widgets/navigation/bottom_nav.dart';

enum AppTab { home, dashboard, scan, centers, profile }

class NavigationWrapper extends StatefulWidget {
  final int initialIndex;

  NavigationWrapper({super.key, this.initialIndex = 0})
    : assert(
        initialIndex >= 0 && initialIndex < AppTab.values.length,
        'initialIndex out of range',
      );

  static NavigationWrapperState? of(BuildContext context) {
    return context.findAncestorStateOfType<NavigationWrapperState>();
  }

  @override
  State<NavigationWrapper> createState() => NavigationWrapperState();
}

class NavigationWrapperState extends State<NavigationWrapper> {
  late AppTab _currentTab;

  final Map<AppTab, Widget> _pagesCache = {};

  final Map<AppTab, Widget Function()> _pageBuilders = {
    AppTab.home: () => const HomePage(),
    AppTab.dashboard: () => const Dashboard(),
    AppTab.scan: () => const ScanAndUploadPage(),
    AppTab.centers: () => const NearbyCenters(),
    AppTab.profile: () => const ProfilePage(),
  };

  @override
  void initState() {
    super.initState();
    _currentTab = AppTab.values[widget.initialIndex];
  }

  Widget _buildPage(AppTab tab) {
    return _pagesCache.putIfAbsent(tab, () => _pageBuilders[tab]!());
  }

  void navigateToTab(AppTab tab) {
    if (_currentTab != tab) {
      setState(() {
        _currentTab = tab;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabs = AppTab.values;

    return Scaffold(
      body: IndexedStack(
        index: _currentTab.index,
        children: tabs.map(_buildPage).toList(),
      ),
      bottomNavigationBar: BottomNav(
        selectedIndex: _currentTab.index,
        onItemTapped: (index) => navigateToTab(tabs[index]),
      ),
    );
  }
}
