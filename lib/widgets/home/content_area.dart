import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:green_books/widgets/common/dropdown_field.dart';
import '../posts/post_card.dart';
import 'package:green_books/widgets/common/custom_search_bar.dart';
import 'package:green_books/styles/custom_button.dart';

class ContentArea extends StatefulWidget {
  const ContentArea({super.key});

  @override
  State<ContentArea> createState() => _ContentAreaState();
}

class _ContentAreaState extends State<ContentArea> {
  final ScrollController _scrollController = ScrollController();

  final List<String> _academicFields = [
    'Chemistry',
    'Physics',
    'Mathematics',
    'Biology',
    'Computer Science',
    'Engineering',
    'Economics',
    'Medicine',
    'Law',
    'Arts',
    'History',
    'Geography',
    'Psychology',
    'Philosophy',
    'Religion',
    'Literature',
    'Arabic Studies',
    'French Studies',
    'German Studies',
    'Italian Studies',
    'Spanish Studies',
    'Others',
  ];

  String _selectedField = 'All';

  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<String> _searchQueryNotifier = ValueNotifier('');

  late Stream<QuerySnapshot> _postsStream;
  late final Future<Map<String, String>> _factOfTheDayFuture;

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      _searchQueryNotifier.value = _searchController.text.toLowerCase();
    });

    _factOfTheDayFuture = _fetchFactOfTheDay();
    _setPostsStream();
  }

  void _setPostsStream() {
    Query query = FirebaseFirestore.instance
        .collection('posts')
        .where('fulfilled', isEqualTo: false)
        .orderBy('createdAt', descending: true);

    if (_selectedField != 'All') {
      query = query.where('academicField', isEqualTo: _selectedField);
    }

    _postsStream = query.snapshots();
  }

  Future<Map<String, String>> _fetchFactOfTheDay() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('recyclingFacts')
        .get();

    final allFacts = snapshot.docs
        .map(
          (doc) => {
            'fact': doc['fact'] as String,
            'source': doc['source'] as String? ?? 'Unknown',
          },
        )
        .toList();

    if (allFacts.isEmpty) return {'fact': 'No fact available', 'source': ''};

    final dayIndex =
        DateTime.now().difference(DateTime(2024, 1, 1)).inDays %
        allFacts.length;

    return allFacts[dayIndex];
  }

  List<DocumentSnapshot> _filterPosts(
    List<DocumentSnapshot> docs,
    String query,
  ) {
    return docs.where((doc) {
      final title = (doc['title'] ?? '').toString().toLowerCase();
      return title.contains(query);
    }).toList();
  }

  Future<void> _showFilterModal() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        String? tempSelected = _selectedField == 'All' ? null : _selectedField;
        return DraggableScrollableSheet(
          initialChildSize: 0.3,
          minChildSize: 0.2,
          maxChildSize: 0.7,
          builder: (context, scrollController) => Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: ListView(
              controller: scrollController,
              children: [
                Text(
                  'Filter by Academic Field',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                MyDropdownField(
                  items: ['All', ..._academicFields],
                  value: tempSelected ?? 'All',
                  hintText: 'Select academic field',
                  onChanged: (value) {
                    tempSelected = value == 'All' ? null : value;
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(tempSelected ?? 'All');
                  },
                  style: CustomButtonStyles.confirmButtonStyle(),
                  child: const Text('Apply Filter'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null && selected != _selectedField) {
      setState(() {
        _selectedField = selected;
        _setPostsStream();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, String>>(
      future: _factOfTheDayFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final fact = snapshot.data!;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Fact of the Day',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          fact['fact'] ?? '',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          'Source: ${fact['source']}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: CustomSearchBar(controller: _searchController),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        height: 48,
                        width: 48,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          onPressed: _showFilterModal,
                          icon: const Icon(Icons.filter_list),
                          tooltip: 'Filter by Academic Field',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ValueListenableBuilder<String>(
                valueListenable: _searchQueryNotifier,
                builder: (context, query, _) {
                  return StreamBuilder<QuerySnapshot>(
                    stream: _postsStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }

                      final docs = snapshot.data?.docs ?? [];
                      final filteredPosts = _filterPosts(docs, query);

                      if (filteredPosts.isEmpty) {
                        if (query.isNotEmpty) {
                          return const Center(
                            child: Text('No posts match your search.'),
                          );
                        } else {
                          return const Center(
                            child: Text('No posts available at the moment.'),
                          );
                        }
                      }

                      return CustomScrollView(
                        controller: _scrollController,
                        slivers: [
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            sliver: SliverGrid(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) =>
                                    PostCard(doc: filteredPosts[index]),
                                childCount: filteredPosts.length,
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
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchQueryNotifier.dispose();
    super.dispose();
  }
}
