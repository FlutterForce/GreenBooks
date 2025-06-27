import 'dart:async';

import 'package:async/async.dart'; // for StreamGroup
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:green_books/widgets/navigation/icons_header.dart';
import 'package:green_books/widgets/home/content_area.dart';
import 'package:green_books/pages/home/user_list_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _hasUnread = false;
  StreamSubscription<QuerySnapshot>? _chatSubscription;

  @override
  void initState() {
    super.initState();
    _listenToChats();
  }

  @override
  void dispose() {
    _chatSubscription?.cancel();
    super.dispose();
  }

  void _listenToChats() async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    final chatSnapshot = await FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .get();

    final chatIds = chatSnapshot.docs.map((doc) => doc.id).toList();

    if (chatIds.isEmpty) return;

    // Create a list of streams (one per chat)
    final streams = chatIds.map((chatId) {
      return FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .snapshots();
    });

    // Merge all the streams into one
    _chatSubscription = StreamGroup.merge(streams).listen((_) {
      _checkUnreadMessages();
    });

    // Initial check
    _checkUnreadMessages();
  }

  Future<void> _checkUnreadMessages() async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    final chatSnapshot = await FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .get();

    bool foundUnread = false;

    for (var chatDoc in chatSnapshot.docs) {
      final messages = await chatDoc.reference
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (messages.docs.isNotEmpty) {
        final msg = messages.docs.first.data();
        final senderId = msg['senderId'];
        final readBy = List<String>.from(msg['readBy'] ?? []);

        if (senderId != currentUserId && !readBy.contains(currentUserId)) {
          foundUnread = true;
          break;
        }
      }
    }

    if (foundUnread != _hasUnread) {
      setState(() {
        _hasUnread = foundUnread;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            IconsHeader(
              titleWidget: Image.asset(
                'assets/icon.png',
                height: 40, // or size that fits well, you can tweak
                fit: BoxFit.contain,
              ),
              icons: [Icons.inbox_rounded],
              onIconTap: [
                () async {
                  await Navigator.push(
                    context,
                    _createSlideFromRightRoute(const UserListPage()),
                  );
                  _checkUnreadMessages(); // Re-check after coming back
                },
              ],
              iconBuilders: [
                (context, icon) => Stack(
                  clipBehavior: Clip.none,
                  children: [
                    icon,
                    if (_hasUnread)
                      const Positioned(
                        top: 9,
                        right: 9,
                        child: CircleAvatar(
                          radius: 5,
                          backgroundColor: Colors.red,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const Expanded(child: ContentArea()),
          ],
        ),
      ),
    );
  }
}

Route _createSlideFromRightRoute(Widget page) {
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
      final offsetAnimation = animation.drive(tween);

      return SlideTransition(position: offsetAnimation, child: child);
    },
  );
}
