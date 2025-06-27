import 'package:flutter/material.dart';

class RewardsPage extends StatelessWidget {
  final int points;

  const RewardsPage({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> rewards = [
      {
        "title": "Free Book Coupon",
        "cost": 100,
        "icon": Icons.book,
        "color": Colors.orange,
      },
      {
        "title": "Plant a Tree in Your Name",
        "cost": 150,
        "icon": Icons.park,
        "color": Colors.green,
      },
      {
        "title": "10% Off Next Purchase",
        "cost": 80,
        "icon": Icons.local_offer,
        "color": Colors.blue,
      },
      {
        "title": "Bookstore Gift Card",
        "cost": 120,
        "icon": Icons.card_giftcard,
        "color": Colors.purple,
      },
      {
        "title": "Digital Library Access (1 Month)",
        "cost": 90,
        "icon": Icons.wifi,
        "color": Colors.teal,
      },
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Rewards',
          style: TextStyle(
            color: Color(0xFF111611),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Text(
              'You have $points points',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: rewards.length,
                itemBuilder: (context, index) {
                  final reward = rewards[index];
                  final affordable = points >= reward['cost'];

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: CircleAvatar(
                        backgroundColor: reward['color'].withOpacity(0.15),
                        child: Icon(reward['icon'], color: reward['color']),
                      ),
                      title: Text(
                        reward['title'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('${reward['cost']} pts'),
                      trailing: affordable
                          ? ElevatedButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Redeemed "${reward['title']}"',
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF078723),
                              ),
                              child: const Text('Redeem'),
                            )
                          : const Text(
                              'Not enough points',
                              style: TextStyle(color: Colors.grey),
                            ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
