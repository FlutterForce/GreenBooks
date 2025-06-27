import 'package:flutter/material.dart';

class CommunityRecycleProgressCard extends StatelessWidget {
  final int currentProgress;
  final int communityGoal;

  const CommunityRecycleProgressCard({
    super.key,
    required this.currentProgress,
    required this.communityGoal,
  });

  @override
  Widget build(BuildContext context) {
    final progress = currentProgress / communityGoal;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF5B6F39),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(16),
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Documents recycled\nthis week",
                  style: TextStyle(
                    color: Color.fromRGBO(47, 58, 31, 1),
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Community goal: $communityGoal',
                  style: const TextStyle(
                    color: Color.fromRGBO(47, 58, 31, 0.7),
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 8,
                        backgroundColor: const Color(0xFF7C8A60).withAlpha(77),
                        valueColor: const AlwaysStoppedAnimation(
                          Color(0xFF2F3A1F),
                        ),
                      ),
                    ),
                    Text(
                      '$currentProgress',
                      style: const TextStyle(
                        color: Color(0xFF2F3A1F),
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
