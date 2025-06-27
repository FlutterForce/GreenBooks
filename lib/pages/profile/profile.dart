import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:green_books/pages/profile/settings/settings.dart';
import 'package:image_picker/image_picker.dart';

import 'package:green_books/widgets/navigation/icons_header.dart';
import 'package:green_books/widgets/profile/profile_image_bar.dart';
import 'package:green_books/widgets/profile/profile_info_section.dart';
import 'package:green_books/widgets/profile/edit_profile_info_section.dart';
import 'package:green_books/widgets/profile/profile_image_picker.dart';
import 'package:green_books/notifiers/profile_image_notifier.dart';
import 'package:green_books/notifiers/profile_image_file_notifier.dart';
import 'package:green_books/widgets/posts/post_card.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  File? _image;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  final ScrollController _scrollController = ScrollController();

  bool _isEditing = false;
  bool _didEdit = false;

  bool _isLoadingProfile = true;

  // User info fields
  String name = '';
  String username = '';
  String email = '';
  String socialLinks = '';
  String gender = '';
  String? profileUrl;

  // Pagination state
  final List<DocumentSnapshot> _userPosts = [];
  bool _isLoadingPosts = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDoc;
  final int _batchSize = 10;

  // Debounce flag for scroll fetches (optional)
  bool _fetchingPosts = false;

  @override
  void initState() {
    super.initState();

    _fetchUserData();
    _fetchMoreUserPosts();

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 300 &&
        !_isLoadingPosts &&
        _hasMore &&
        !_isEditing &&
        !_fetchingPosts) {
      _fetchMoreUserPosts();
    }
  }

  Future<void> _fetchUserData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() {
      _isLoadingProfile = true;
    });

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists || !mounted) return;

      final data = userDoc.data()!;
      setState(() {
        name = data['name'] ?? '';
        username = data['username'] ?? '';
        socialLinks = data['socialLinks'] ?? '';
        gender = data['gender'] ?? '';
        profileUrl = data['profilePicUrl'] ?? '';
        email = user.email ?? '';
        _isLoadingProfile = false;
      });

      if (profileUrl != null && profileUrl!.isNotEmpty) {
        profileImageNotifier.value = profileUrl!;
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingProfile = false;
      });
      // Optional: Show error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load profile data')),
      );
    }
  }

  Future<void> _fetchMoreUserPosts() async {
    final user = _auth.currentUser;
    if (user == null || _isLoadingPosts || !_hasMore) return;

    setState(() {
      _isLoadingPosts = true;
      _fetchingPosts = true;
    });

    try {
      Query query = _firestore
          .collection('posts')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .limit(_batchSize);

      if (_lastDoc != null) {
        query = query.startAfterDocument(_lastDoc!);
      }

      final snapshot = await query.get();

      if (!mounted) return;

      if (snapshot.docs.isEmpty) {
        setState(() => _hasMore = false);
      } else {
        setState(() {
          _userPosts.addAll(snapshot.docs);
          _lastDoc = snapshot.docs.last;
          if (snapshot.docs.length < _batchSize) _hasMore = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _hasMore = false);
      // Optional: Show error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load user posts')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingPosts = false;
          _fetchingPosts = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    final file = File(pickedFile.path);
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    profileImageFileNotifier.value = file;

    setState(() {
      _image = file;
      profileUrl = null;
      _didEdit = true;
    });

    try {
      final storageRef = FirebaseStorage.instance.ref().child(
        'users/$uid/profile.jpg',
      );
      await storageRef.putFile(file);

      final downloadUrl = await storageRef.getDownloadURL();

      // Add cache busting param
      final separator = downloadUrl.contains('?') ? '&' : '?';
      final cacheBustingUrl =
          "$downloadUrl${separator}timestamp=${DateTime.now().millisecondsSinceEpoch}";

      await _firestore.collection('users').doc(uid).update({
        'profilePicUrl': downloadUrl,
      });

      if (!mounted) return;
      profileImageNotifier.value = cacheBustingUrl;

      // Optional success snackbar:
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile image updated')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to upload image.')));
    }
  }

  void _enterEditMode() => setState(() => _isEditing = true);

  void _exitEditMode() {
    setState(() {
      _isEditing = false;
    });

    if (_didEdit) {
      _didEdit = false;
      _userPosts.clear();
      _hasMore = true;
      _lastDoc = null;

      _fetchUserData();
      _fetchMoreUserPosts();

      _delayedImageClear();
    }
  }

  void _delayedImageClear() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _image = null);
      }
    });
  }

  Route _createSlideRightRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.ease;

        final tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));

        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Always white background as requested

    final userData = {
      'name': name,
      'username': username,
      'email': email,
      'gender': gender,
      'socialLinks': socialLinks,
    };

    List<IconData> icons;
    List<VoidCallback> onIconTap;

    if (_isEditing) {
      icons = [Icons.arrow_back];
      onIconTap = [_exitEditMode];
    } else {
      icons = [Icons.edit, Icons.settings];
      onIconTap = [
        _enterEditMode,
        () {
          Navigator.push(context, _createSlideRightRoute(const SettingsPage()));
        },
      ];
    }

    if (_isLoadingProfile) {
      return Container(
        color: Colors.white, // Paint behind status bar white here
        child: SafeArea(
          top: false, // Let Container color show behind status bar
          child: Scaffold(
            backgroundColor: Colors.white,
            body: const Center(child: CircularProgressIndicator()),
          ),
        ),
      );
    }

    return Container(
      color: Colors.white, // Paint behind status bar white here too
      child: SafeArea(
        top: false, // Let white show behind status bar
        child: Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Center(
              child: _isEditing
                  ? Column(
                      children: [
                        IconsHeader(
                          title: 'Edit Profile',
                          icons: icons,
                          onIconTap: onIconTap,
                        ),
                        Container(
                          height: 150,
                          margin: const EdgeInsets.symmetric(vertical: 16),
                          alignment: Alignment.center,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 100,
                                  height: 100,
                                  child: ProfileImagePicker(
                                    image: _image,
                                    profileUrl: profileUrl,
                                    onPickImage: () {}, // optional callback
                                    radius: 50,
                                  ),
                                ),
                                Positioned.fill(
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 30,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: EditProfileInfoSection(
                              data: userData,
                              onRefresh: () {
                                setState(() => _didEdit = true);
                              },
                            ),
                          ),
                        ),
                      ],
                    )
                  : CustomScrollView(
                      controller: _scrollController,
                      slivers: [
                        SliverToBoxAdapter(
                          child: IconsHeader(
                            title: 'Profile',
                            icons: icons,
                            onIconTap: onIconTap,
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Container(
                            height: 150,
                            margin: const EdgeInsets.symmetric(vertical: 16),
                            alignment: Alignment.center,
                            child: ProfileImageBar(radius: 50),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: ProfileInfoSection(
                              data: userData,
                              onRefresh: _fetchUserData,
                            ),
                          ),
                        ),
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(32, 24, 32, 8),
                            child: Text(
                              'My Posts',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        if (_userPosts.isEmpty && !_isLoadingPosts)
                          const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 32,
                              ),
                              child: Center(
                                child: Text(
                                  'No posts have been made yet.',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            sliver: SliverGrid(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) =>
                                    PostCard(doc: _userPosts[index]),
                                childCount: _userPosts.length,
                              ),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    mainAxisSpacing: 8,
                                    crossAxisSpacing: 8,
                                    childAspectRatio: 0.7,
                                  ),
                            ),
                          ),
                        if (_isLoadingPosts)
                          const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                          ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
