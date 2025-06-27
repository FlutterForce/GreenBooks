import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:green_books/widgets/common/text_fields.dart';

class ChatPage extends StatefulWidget {
  final String chatId;
  final String currentUserId;
  final String otherUserId;
  final String otherUsername;

  const ChatPage({
    super.key,
    required this.chatId,
    required this.currentUserId,
    required this.otherUserId,
    required this.otherUsername,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode);
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final now = FieldValue.serverTimestamp();

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .add({
          'text': text,
          'senderId': widget.currentUserId,
          'timestamp': now,
          'readBy': [widget.currentUserId],
        });

    await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).set(
      {
        'participants': [widget.currentUserId, widget.otherUserId],
        'lastMessage': text,
        'timestamp': now,
        'lastSender': widget.currentUserId,
      },
    );

    _messageController.clear();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.otherUsername),
        backgroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('chats')
                    .doc(widget.chatId)
                    .collection('messages')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final messages = snapshot.data!.docs;

                  for (var doc in messages) {
                    final data = doc.data() as Map<String, dynamic>;
                    final senderId = data['senderId'];
                    final readBy = (data['readBy'] is List)
                        ? List<String>.from(data['readBy'])
                        : <String>[];

                    final isUnread =
                        senderId != widget.currentUserId &&
                        !readBy.contains(widget.currentUserId);

                    if (isUnread) {
                      doc.reference.update({
                        'readBy': FieldValue.arrayUnion([widget.currentUserId]),
                      });
                    }
                  }

                  String? lastSentMessageId;
                  for (var doc in messages) {
                    final data = doc.data() as Map<String, dynamic>;
                    if (data['senderId'] == widget.currentUserId) {
                      lastSentMessageId = doc.id;
                      break;
                    }
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final doc = messages[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final isMe = data['senderId'] == widget.currentUserId;
                      final readBy = (data['readBy'] is List)
                          ? List<String>.from(data['readBy'])
                          : <String>[];
                      final isReadByOther = readBy.contains(widget.otherUserId);
                      final isLastSent = doc.id == lastSentMessageId;

                      return Container(
                        alignment: isMe
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.7,
                          ),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.green[300] : Colors.grey[300],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                data['text'],
                                style: const TextStyle(fontSize: 16),
                              ),
                              if (isMe && isLastSent && isReadByOther)
                                const Padding(
                                  padding: EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    'Read',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.green,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: MyTextField(
                      controller: _messageController,
                      hintText: 'Type a message...',
                      readOnly: false,
                      enabled: true,
                      keyboardType: TextInputType.multiline,
                      focusNode: _focusNode, // Add focus node here
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send_rounded, size: 32),
                    onPressed: sendMessage,
                    color: Colors.green,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
