import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:green_books/widgets/posts/post_card.dart';

class MyOrdersPage extends StatefulWidget {
  const MyOrdersPage({super.key});

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> {
  final List<DocumentSnapshot> _orderPosts = [];
  final ScrollController _scrollController = ScrollController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDoc;
  final int _batchSize = 10;

  @override
  void initState() {
    super.initState();
    _fetchMoreOrders();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 300 &&
          !_isLoading &&
          _hasMore) {
        _fetchMoreOrders();
      }
    });
  }

  Future<void> _fetchMoreOrders() async {
    final user = _auth.currentUser;
    if (user == null || _isLoading || !_hasMore) return;

    setState(() => _isLoading = true);

    try {
      Query query = _firestore
          .collection('posts')
          .where('fulfilled', isEqualTo: true)
          .where('fulfilledWith', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .limit(_batchSize);

      if (_lastDoc != null) {
        query = query.startAfterDocument(_lastDoc!);
      }

      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        _hasMore = false;
      } else {
        setState(() {
          _orderPosts.addAll(snapshot.docs);
          _lastDoc = snapshot.docs.last;
          if (snapshot.docs.length < _batchSize) _hasMore = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching orders: $e');
      _hasMore = false;
    }

    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'My Purchases',
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
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(32, 24, 32, 8),
                child: Text(
                  'Purchased Posts',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            _orderPosts.isEmpty && !_isLoading
                ? const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 64,
                      ),
                      child: Center(
                        child: Text(
                          'You haven’t fulfilled any orders yet.',
                          style: TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => PostCard(doc: _orderPosts[index]),
                        childCount: _orderPosts.length,
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
            if (_isLoading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
