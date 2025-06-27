import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:green_books/widgets/dashboard/impact_metrics_section.dart';
import 'package:green_books/widgets/dashboard/community_recycle_progress_card.dart';
import 'package:green_books/widgets/dashboard/document_summary_section.dart';
import 'package:green_books/widgets/dashboard/point_summary_card.dart';
import 'package:green_books/widgets/navigation/icons_header.dart';

class Dashboard extends StatelessWidget {
  static const Color darkGreen = Color(0xFF111611);

  const Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const IconsHeader(title: 'Dashboard'),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Community progress card (Live)
                    Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('posts')
                            .where('fulfilled', isEqualTo: true)
                            .snapshots(),
                        builder: (context, fulfilledSnapshot) {
                          if (!fulfilledSnapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          return StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('users')
                                .snapshots(),
                            builder: (context, usersSnapshot) {
                              if (!usersSnapshot.hasData) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }

                              int recycledTotal = 0;
                              for (final doc in usersSnapshot.data!.docs) {
                                final data = doc.data() as Map<String, dynamic>;
                                recycledTotal +=
                                    (data['documentsRecycled'] ?? 0) as int;
                              }

                              final combinedTotal =
                                  fulfilledSnapshot.data!.docs.length +
                                  recycledTotal;

                              return FutureBuilder<DocumentSnapshot>(
                                future: FirebaseFirestore.instance
                                    .collection('CommunityGoal')
                                    .limit(1)
                                    .get()
                                    .then((snap) => snap.docs.first),
                                builder: (context, goalSnapshot) {
                                  final goal =
                                      (goalSnapshot.data?.data()
                                          as Map<
                                            String,
                                            dynamic
                                          >?)?['currentGoal'] ??
                                      1000;

                                  return CommunityRecycleProgressCard(
                                    currentProgress: combinedTotal,
                                    communityGoal: goal,
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),

                    // User contribution heading
                    Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      child: const Text(
                        "Your Contribution",
                        style: TextStyle(
                          color: darkGreen,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    // User contributions (Live)
                    if (user != null)
                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData || !snapshot.data!.exists) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 32),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          final userData =
                              snapshot.data!.data() as Map<String, dynamic>;

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Column(
                              children: [
                                DocumentsSummarySection(
                                  documentsSold: userData['documentsSold'] ?? 0,
                                  documentsBought:
                                      userData['documentsBought'] ?? 0,
                                  documentsDonated:
                                      userData['documentsDonated'] ?? 0,
                                  documentsAcquired:
                                      userData['documentsAcquired'] ?? 0,
                                  documentsRecycled:
                                      userData['documentsRecycled'] ?? 0,
                                ),
                                const SizedBox(height: 16),
                                PointsSummaryCard(
                                  documentsSold: userData['documentsSold'] ?? 0,
                                  documentsBought:
                                      userData['documentsBought'] ?? 0,
                                  documentsDonated:
                                      userData['documentsDonated'] ?? 0,
                                  documentsRecycled:
                                      userData['documentsRecycled'] ?? 0,
                                ),
                              ],
                            ),
                          );
                        },
                      )
                    else
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 32),
                        child: Text("Not logged in."),
                      ),

                    // Community's impact heading
                    Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      child: const Text(
                        "Community's Impact",
                        style: TextStyle(
                          color: darkGreen,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    // Community impact metrics (Live)
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('posts')
                          .where('status', isEqualTo: 'Donate')
                          .where('fulfilled', isEqualTo: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        int totalPages = 0;

                        for (final doc in snapshot.data!.docs) {
                          final data = doc.data() as Map<String, dynamic>;
                          final num pageCount = data['pageCount'] ?? 0;
                          totalPages += pageCount.toInt();
                        }

                        return ImpactMetricsSection(
                          totalPagesRecycled: totalPages,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
