import 'package:flutter/material.dart';
import 'document_impact_line.dart';

class DocumentsSummarySection extends StatelessWidget {
  final int documentsSold;
  final int documentsBought;
  final int documentsDonated;
  final int documentsRecycled;
  final int documentsAcquired;

  const DocumentsSummarySection({
    super.key,
    required this.documentsSold,
    required this.documentsBought,
    required this.documentsDonated,
    required this.documentsAcquired,
    required this.documentsRecycled,
  });

  @override
  Widget build(BuildContext context) {
    final int totalDocuments =
        documentsSold +
        documentsBought +
        documentsDonated +
        documentsRecycled +
        documentsAcquired;
    const brownColor = Color(0xFF904F26);
    const greenColor = Color(0xFF078723);

    return SizedBox(
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                BookImpactLine(
                  count: documentsSold,
                  prefix: "Documents ",
                  suffix: "sold.",
                  color: brownColor,
                  icon: Icons.sell_rounded,
                ),
                BookImpactLine(
                  count: documentsDonated,
                  prefix: "Documents ",
                  suffix: "donated.",
                  color: brownColor,
                  icon: Icons.volunteer_activism_rounded,
                ),
                BookImpactLine(
                  count: documentsBought,
                  prefix: "Documents ",
                  suffix: "bought.",
                  color: brownColor,
                  icon: Icons.shopping_bag_rounded,
                ),
                BookImpactLine(
                  count: documentsAcquired,
                  prefix: "Documents ",
                  suffix: "acquired.",
                  color: brownColor,
                  icon: Icons.volunteer_activism_outlined,
                ),
                BookImpactLine(
                  count: documentsRecycled,
                  prefix: "Documents ",
                  suffix: "recycled.",
                  color: greenColor,
                  icon: Icons.recycling_rounded,
                ),
              ],
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                totalDocuments.toString(),
                style: const TextStyle(
                  color: brownColor,
                  fontSize: 70,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
