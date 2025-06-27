import 'package:flutter/material.dart';
import 'package:green_books/pages/dashboard/rewards.dart';

class PointsSummaryCard extends StatelessWidget {
  final int documentsSold;
  final int documentsBought;
  final int documentsDonated;
  final int documentsRecycled;

  const PointsSummaryCard({
    super.key,
    required this.documentsSold,
    required this.documentsBought,
    required this.documentsDonated,
    required this.documentsRecycled,
  });

  int calculatePoints() {
    return (documentsRecycled * 15) +
        (documentsDonated * 10) +
        (documentsSold * 5) +
        (documentsBought * 2);
  }

  @override
  Widget build(BuildContext context) {
    final int totalPoints = calculatePoints();

    return SizedBox(
      height: 180,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFE0F7E9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            const Icon(Icons.emoji_events, color: Color(0xFF078723), size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Points Earned',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2F3A1F),
                    ),
                  ),
                  TweenAnimationBuilder<int>(
                    tween: IntTween(begin: 0, end: totalPoints),
                    duration: const Duration(seconds: 1),
                    builder: (context, value, _) {
                      return Text(
                        '$value pts',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF078723),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Recycling gives the most points!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black.withOpacity(0.6),
                    ),
                  ),
                  const Spacer(),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                RewardsPage(points: totalPoints),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.card_giftcard,
                        color: Color(0xFF078723),
                      ),
                      label: const Text(
                        'Spend Points',
                        style: TextStyle(
                          color: Color(0xFF078723),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        minimumSize: Size.zero,
                      ),
                    ),
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
