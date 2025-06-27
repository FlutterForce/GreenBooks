import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:green_books/pages/home/chatpage.dart';
import 'package:green_books/widgets/common/dropdown_field.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PostPage extends StatefulWidget {
  final String postId;

  const PostPage({super.key, required this.postId});

  @override
  State<PostPage> createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  static const EdgeInsets _sectionContentPadding = EdgeInsets.symmetric(
    horizontal: 32,
    vertical: 8,
  );

  bool showFulfillInput = false;
  String? fulfillErrorText;
  List<Map<String, dynamic>> chatUsers = [];
  String? selectedUserId;

  bool _isLoading = true;
  DocumentSnapshot? _postDoc;
  DocumentSnapshot? _fulfilledUserDoc;

  @override
  void initState() {
    super.initState();
    _loadChatUsers();
    _loadPost();
  }

  Future<void> _loadPost() async {
    final postRef = FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId);
    final doc = await postRef.get();

    if (!doc.exists) {
      setState(() {
        _postDoc = null;
        _isLoading = false;
      });
      return;
    }

    final data = doc.data();
    final fulfilled = data?['fulfilled'] == true;
    final posterId = data?['userId'];
    final fulfilledWith = data?['fulfilledWith'] as String?;
    final isPostOwner = posterId == FirebaseAuth.instance.currentUser?.uid;

    DocumentSnapshot? fulfilledUserDoc;
    if (fulfilled && (isPostOwner ? fulfilledWith : posterId) != null) {
      final userId = isPostOwner ? fulfilledWith : posterId;
      fulfilledUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
    }

    setState(() {
      _postDoc = doc;
      _fulfilledUserDoc = fulfilledUserDoc;
      _isLoading = false;
    });
  }

  Future<void> _loadChatUsers() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    final chatsSnapshot = await FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .get();

    final partnerIds = <String>{};
    for (final doc in chatsSnapshot.docs) {
      final participants = List<String>.from(doc['participants']);
      for (final p in participants) {
        if (p != currentUserId) {
          partnerIds.add(p);
        }
      }
    }

    if (partnerIds.isEmpty) {
      setState(() {
        chatUsers = [];
        selectedUserId = null;
      });
      return;
    }

    final usersSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where(FieldPath.documentId, whereIn: partnerIds.toList())
        .get();

    final usersList = usersSnapshot.docs
        .map(
          (doc) => {'userId': doc.id, 'username': doc['username'] ?? 'Unknown'},
        )
        .toList();

    setState(() {
      chatUsers = usersList;
      selectedUserId = null;
      fulfillErrorText = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Post',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _postDoc == null
            ? const Center(child: Text('Post not found.'))
            : _buildPostContentFromDoc(),
      ),
    );
  }

  Widget _buildPostContentFromDoc() {
    final data = _postDoc!.data() as Map<String, dynamic>?;
    final title = (data?['title'] as String?)?.trim();
    final pdfUrl = data?['pdfUrl'] as String?;
    final description = (data?['description'] as String?)?.trim();
    final location = (data?['location'] as String?)?.trim();
    final price = data?['price'];
    final posterId = data?['userId'];
    final status = (data?['status'] as String?) ?? '';
    final fulfilled = data?['fulfilled'] == true;
    final isPostOwner = posterId == FirebaseAuth.instance.currentUser?.uid;
    final fulfilledUsername =
        (_fulfilledUserDoc?.data() as Map<String, dynamic>?)?['username'] ??
        'Unknown';

    return _buildPostContent(
      context,
      title: title,
      pdfUrl: pdfUrl,
      description: description,
      location: location,
      price: price,
      status: status,
      isPostOwner: isPostOwner,
      fulfilled: fulfilled,
      fulfilledUsername: fulfilledUsername,
      posterId: posterId,
    );
  }

  Widget _buildPostContent(
    BuildContext context, {
    required String? title,
    required String? pdfUrl,
    required String? description,
    required String? location,
    required dynamic price,
    required String status,
    required bool isPostOwner,
    required bool fulfilled,
    required String? fulfilledUsername,
    required String? posterId,
  }) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (pdfUrl != null && pdfUrl.isNotEmpty) ...[
            _sectionTitle(context, 'Preview'),
            Padding(
              padding: _sectionContentPadding,
              child: SizedBox(
                height: 300,
                child: SfPdfViewer.network(
                  pdfUrl,
                  canShowScrollStatus: false,
                  canShowPaginationDialog: false,
                ),
              ),
            ),
          ],
          if (description != null && description.isNotEmpty) ...[
            _sectionTitle(context, 'Description'),
            Padding(
              padding: _sectionContentPadding,
              child: Text(
                description,
                style: const TextStyle(fontSize: 15, height: 1.5),
              ),
            ),
          ],
          if (location != null && location.isNotEmpty) ...[
            _sectionTitle(context, 'Location'),
            Padding(
              padding: _sectionContentPadding,
              child: Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 20),
                  const SizedBox(width: 6),
                  Text(location),
                ],
              ),
            ),
          ],
          if (price != null) ...[
            _sectionTitle(context, 'Price'),
            Padding(
              padding: _sectionContentPadding,
              child: Text('$price EGP', style: const TextStyle(fontSize: 15)),
            ),
          ],
          const SizedBox(height: 16),
          Padding(
            padding: _sectionContentPadding,
            child: Builder(
              builder: (context) {
                if (fulfilled) {
                  final label = status.toLowerCase() == 'donate'
                      ? isPostOwner
                            ? 'Donated to @$fulfilledUsername'
                            : 'Acquired from @$fulfilledUsername'
                      : isPostOwner
                      ? 'Sold to @$fulfilledUsername'
                      : 'Bought from @$fulfilledUsername';
                  return _fulfilledButton(label);
                }

                if (isPostOwner) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton(
                        onPressed: () =>
                            setState(() => showFulfillInput = true),
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: Colors.grey[300],
                          foregroundColor: Colors.black87,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          status.toLowerCase() == 'donate'
                              ? 'Mark as Donated'
                              : 'Mark as Sold',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (showFulfillInput) ...[
                        const SizedBox(height: 12),
                        MyDropdownField(
                          items: chatUsers
                              .map((u) => u['username'] as String)
                              .toList(),
                          value: selectedUserId != null
                              ? chatUsers.firstWhere(
                                  (u) => u['userId'] == selectedUserId,
                                )['username']
                              : null,
                          hintText: 'Select user to fulfill with',
                          onChanged: (username) {
                            final selected = chatUsers.firstWhere(
                              (user) => user['username'] == username,
                              orElse: () => {'userId': null},
                            );
                            setState(() {
                              selectedUserId = selected['userId'];
                              fulfillErrorText = null;
                            });
                          },
                        ),
                        if (fulfillErrorText != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            fulfillErrorText!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ],
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => _handleFulfill(posterId, status),
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: Colors.grey[300],
                            foregroundColor: Colors.black87,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Confirm Fulfillment',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  );
                }

                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _dmAuthor(posterId),
                    icon: const Icon(Icons.message),
                    label: const Text('Message Author'),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: Colors.grey[200],
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _fulfilledButton(String label) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: Colors.grey[300],
          foregroundColor: Colors.black87,
          disabledBackgroundColor: Colors.grey[300],
          disabledForegroundColor: Colors.black54,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Future<void> _handleFulfill(String? posterId, String status) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (selectedUserId == null || currentUserId == null || posterId == null) {
      setState(() => fulfillErrorText = 'Please select a user.');
      return;
    }

    final userExists = chatUsers.any(
      (user) => user['userId'] == selectedUserId,
    );
    if (!userExists) {
      setState(
        () => fulfillErrorText = 'Selected user is not in your chat list.',
      );
      return;
    }

    final isDonate = status.toLowerCase() == 'donate';
    final posterRef = FirebaseFirestore.instance
        .collection('users')
        .doc(posterId);
    final recipientRef = FirebaseFirestore.instance
        .collection('users')
        .doc(selectedUserId);
    final postRef = FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId);

    final postData = _postDoc?.data() as Map<String, dynamic>?;
    final pageCount = postData?['pageCount'] is int
        ? postData!['pageCount'] as int
        : 0;

    final batch = FirebaseFirestore.instance.batch();

    batch.update(postRef, {
      'fulfilled': true,
      'fulfilledWith': selectedUserId,
      'fulfilledAt': FieldValue.serverTimestamp(),
    });

    if (currentUserId == posterId) {
      batch.update(posterRef, {
        isDonate ? 'documentsDonated' : 'documentsSold': FieldValue.increment(
          1,
        ),
        'pagesRecycled': FieldValue.increment(pageCount),
      });
    }

    batch.update(recipientRef, {
      isDonate ? 'documentsAcquired' : 'documentsBought': FieldValue.increment(
        1,
      ),
      'pagesRecycled': FieldValue.increment(pageCount),
    });

    await batch.commit();
    await _loadPost(); // Refresh after fulfillment

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isDonate ? 'Post marked as donated!' : 'Post marked as sold!',
        ),
      ),
    );

    setState(() {
      showFulfillInput = false;
      fulfillErrorText = null;
      selectedUserId = null;
    });
  }

  Future<void> _dmAuthor(String? posterId) async {
    if (posterId == null) return;
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || posterId == currentUser.uid) return;

    final currentUserId = currentUser.uid;
    final chatId = _getChatId(currentUserId, posterId);
    final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);
    final chatDoc = await chatRef.get();

    if (!chatDoc.exists) {
      await chatRef.set({
        'chatId': chatId,
        'participants': [currentUserId, posterId],
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(posterId)
        .get();
    final otherUsername = userDoc['username'] ?? 'Unknown';

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatPage(
          chatId: chatId,
          currentUserId: currentUserId,
          otherUserId: posterId,
          otherUsername: otherUsername,
        ),
      ),
    );
  }

  String _getChatId(String user1, String user2) {
    final users = [user1, user2]..sort();
    return '${users[0]}_${users[1]}';
  }
}
