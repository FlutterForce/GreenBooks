import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:green_books/pages/post/view_post.dart';

class PostCard extends StatelessWidget {
  final DocumentSnapshot doc;

  const PostCard({super.key, required this.doc});

  String _timeAgo(Timestamp timestamp) {
    final now = DateTime.now();
    final created = timestamp.toDate();
    final diff = now.difference(created);

    if (diff.inDays >= 7) {
      final weeks = diff.inDays ~/ 7;
      return '$weeks week${weeks > 1 ? 's' : ''} ago';
    } else if (diff.inDays >= 1) {
      return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
    } else if (diff.inHours >= 1) {
      return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
    } else if (diff.inMinutes >= 1) {
      return '${diff.inMinutes} minute${diff.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  String _getSafeString(
    Map<String, dynamic>? data,
    String key,
    String fallback,
  ) {
    final value = data?[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return fallback;
  }

  void _onTap(BuildContext context) {
    Navigator.push(
      context,
      _createSlideFromRightRoute(PostPage(postId: doc.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>?;

    final title = _getSafeString(data, 'title', 'Untitled post');
    final academicField = _getSafeString(
      data,
      'academicField',
      'Unknown academic field',
    );
    final location = _getSafeString(data, 'location', 'Unknown location');
    final createdAt = data?['createdAt'] is Timestamp
        ? data!['createdAt'] as Timestamp
        : null;
    final fulfilledAt = data?['fulfilledAt'] is Timestamp
        ? data!['fulfilledAt'] as Timestamp
        : null;

    final userId = data?['userId'] as String?;
    if (userId == null) return const SizedBox();

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, userSnapshot) {
        String username = 'Unknown user';
        if (userSnapshot.hasData && userSnapshot.data!.exists) {
          final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
          username = _getSafeString(userData, 'username', 'Unknown user');
        }

        String? fulfillmentLabel;
        if (fulfilledAt != null && currentUserId != null) {
          final bool isPostOwner = userId == currentUserId;
          final status = (data?['status'] as String?)?.toLowerCase();

          if (isPostOwner) {
            fulfillmentLabel = (status == 'donate')
                ? 'Donated to @$username'
                : 'Sold to @$username';
          } else {
            fulfillmentLabel = (status == 'donate')
                ? 'Acquired from @$username'
                : 'Bought from @$username';
          }
        }

        return GestureDetector(
          onTap: () => _onTap(context),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF64B5F6), Color(0xFF1976D2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(32),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: constraints.maxHeight),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: fulfillmentLabel == null
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (fulfillmentLabel != null && fulfilledAt != null)
                        Text(
                          '$fulfillmentLabel (${_timeAgo(fulfilledAt)})',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                          softWrap: true,
                        ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            academicField,
                            style: const TextStyle(color: Colors.white),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            location,
                            style: const TextStyle(color: Colors.white),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            username,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (createdAt != null)
                            Text(
                              _timeAgo(createdAt),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

/// Slide-from-right route transition helper
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
