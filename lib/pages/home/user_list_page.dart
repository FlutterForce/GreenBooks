import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:green_books/pages/home/chatpage.dart';
import 'package:green_books/widgets/common/custom_search_bar.dart';

class UserListPage extends StatefulWidget {
  const UserListPage({super.key});

  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  final Map<String, DocumentSnapshot> _userCache = {};
  final currentUserId = FirebaseAuth.instance.currentUser!.uid;
  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<String> _searchQueryNotifier = ValueNotifier<String>('');
  final Map<String, bool> _hasUnread = {};
  final Map<String, Timestamp?> _lastMessageTime = {};

  List<QueryDocumentSnapshot> chatDocsCache = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      _searchQueryNotifier.value = _searchController.text;
    });
  }

  @override
  void dispose() {
    _userCache.clear();
    _searchController.dispose();
    _searchQueryNotifier.dispose();
    super.dispose();
  }

  Future<List<DocumentSnapshot>> _getUsers(List<String> userIds) async {
    final uncachedIds = userIds
        .where((id) => !_userCache.containsKey(id))
        .toList();

    if (uncachedIds.isNotEmpty) {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where(FieldPath.documentId, whereIn: uncachedIds)
          .get();

      for (var doc in snapshot.docs) {
        _userCache[doc.id] = doc;
      }
    }

    return userIds.map((id) => _userCache[id]!).toList();
  }

  Set<String> _extractOtherUserIds(List<QueryDocumentSnapshot> chatDocs) {
    final otherUserIds = <String>{};

    for (var chatDoc in chatDocs) {
      final participants = List<String>.from(chatDoc['participants']);
      otherUserIds.addAll(participants.where((id) => id != currentUserId));
    }

    return otherUserIds;
  }

  Future<void> _fetchUnreadFlags(List<QueryDocumentSnapshot> chatDocs) async {
    final Map<String, bool> newUnread = {};
    final Map<String, Timestamp?> newTimes = {};

    for (var chatDoc in chatDocs) {
      final messagesSnapshot = await chatDoc.reference
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (messagesSnapshot.docs.isNotEmpty) {
        final msg = messagesSnapshot.docs.first.data();
        final readBy = List<String>.from(msg['readBy'] ?? []);
        final senderId = msg['senderId'];
        final timestamp = msg['timestamp'] as Timestamp?;

        final participants = List<String>.from(chatDoc['participants']);
        final otherUserId = participants.firstWhere(
          (id) => id != currentUserId,
        );

        newTimes[otherUserId] = timestamp;
        newUnread[otherUserId] =
            (senderId != currentUserId && !readBy.contains(currentUserId));
      }
    }

    if (mounted) {
      setState(() {
        _hasUnread.clear();
        _hasUnread.addAll(newUnread);
        _lastMessageTime.clear();
        _lastMessageTime.addAll(newTimes);
      });
    }
  }

  List<DocumentSnapshot> _filterAndSortUsers(
    List<DocumentSnapshot> users,
    String query,
  ) {
    final filteredUsers = users.where((user) {
      final username = (user['username'] ?? '').toLowerCase();
      return username.contains(query.toLowerCase());
    }).toList();

    filteredUsers.sort((a, b) {
      final timeA = _lastMessageTime[a.id]?.millisecondsSinceEpoch ?? 0;
      final timeB = _lastMessageTime[b.id]?.millisecondsSinceEpoch ?? 0;
      return timeB.compareTo(timeA);
    });

    return filteredUsers;
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

  Widget _buildUserList(List<DocumentSnapshot> users) {
    return ValueListenableBuilder<String>(
      valueListenable: _searchQueryNotifier,
      builder: (context, searchQuery, _) {
        final filteredUsers = _filterAndSortUsers(users, searchQuery);

        if (filteredUsers.isEmpty) {
          return const Center(child: Text('No users match your search.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: filteredUsers.length,
          itemBuilder: (context, index) {
            final user = filteredUsers[index];
            final username = user['username'] ?? 'Unnamed';
            final profilePicUrl = user['profilePicUrl']?.toString() ?? '';
            final selectedUserId = user.id;
            final chatId = getChatId(currentUserId, selectedUserId);
            final showDot = _hasUnread[selectedUserId] == true;

            return Card(
              elevation: 0,
              color: Colors.grey[200],
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                leading: _buildProfileAvatar(profilePicUrl),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        username,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (showDot)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () async {
                  await Navigator.push(
                    context,
                    _createSlideRightRoute(
                      ChatPage(
                        chatId: chatId,
                        currentUserId: currentUserId,
                        otherUserId: selectedUserId,
                        otherUsername: username,
                      ),
                    ),
                  );
                  _fetchUnreadFlags(chatDocsCache);
                },
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Chats',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: CustomSearchBar(controller: _searchController),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('chats')
                    .where('participants', arrayContains: currentUserId)
                    .snapshots(),
                builder: (context, chatSnapshot) {
                  if (!chatSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final chatDocs = chatSnapshot.data!.docs;
                  chatDocsCache = chatDocs;
                  final otherUserIds = _extractOtherUserIds(chatDocs);

                  if (otherUserIds.isEmpty) {
                    return const Center(child: Text('No active chats found.'));
                  }

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _fetchUnreadFlags(chatDocs);
                  });

                  return FutureBuilder<List<DocumentSnapshot>>(
                    future: _getUsers(otherUserIds.toList()),
                    builder: (context, userSnapshot) {
                      if (!userSnapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      return _buildUserList(userSnapshot.data!);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(String url) {
    if (url.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url,
        imageBuilder: (context, imageProvider) =>
            CircleAvatar(radius: 20, backgroundImage: imageProvider),
        placeholder: (context, url) => CircleAvatar(
          radius: 20,
          backgroundColor: Colors.grey[300],
          child: const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (context, url, error) => const CircleAvatar(
          radius: 20,
          backgroundColor: Colors.grey,
          child: Icon(Icons.error),
        ),
      );
    }

    return const CircleAvatar(
      radius: 20,
      backgroundColor: Colors.grey,
      child: Icon(Icons.person, color: Colors.white),
    );
  }

  String getChatId(String user1, String user2) {
    final users = [user1, user2]..sort();
    return '${users[0]}_${users[1]}';
  }
}
