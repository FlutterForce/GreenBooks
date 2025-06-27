import 'package:flutter/material.dart';
import 'impact_metric_box.dart';

class ImpactMetricsSection extends StatelessWidget {
  final int totalPagesRecycled;

  const ImpactMetricsSection({super.key, required this.totalPagesRecycled});

  @override
  Widget build(BuildContext context) {
    // Constants based on user-provided data:
    // One tree produces 8333 sheets of A4 paper
    // One sheet weighs 5 grams
    // One ton (1,000,000 grams) saves:
    //   - 4100 kWh energy
    //   - 7000 gallons water
    //   - 1000 kg CO2 reduced (1 metric ton)

    const double sheetsPerTree = 8333.0;
    const double paperWeightPerSheetGrams = 5.0;
    const double gramsPerTon = 1e6;

    const double energySavedPerTonKWh = 4100.0;
    const double waterSavedPerTonGallons = 7000.0;
    const double co2ReducedPerTonKg = 1000.0;

    // Calculate total weight in tons
    final double totalWeightGrams =
        totalPagesRecycled * paperWeightPerSheetGrams;
    final double totalWeightTons = totalWeightGrams / gramsPerTon;

    // Calculate impacts
    final double treesSaved = totalPagesRecycled / sheetsPerTree;
    final double energySaved = totalWeightTons * energySavedPerTonKWh;
    final double waterSaved = totalWeightTons * waterSavedPerTonGallons;
    final double co2Reduced = totalWeightTons * co2ReducedPerTonKg;

    String formatDouble(double val) {
      if (val < 0.01) return '0';
      if (val < 1) return val.toStringAsFixed(2);
      return val.toStringAsFixed(1);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ImpactMetricBox(
                  title: "Trees Saved",
                  value: formatDouble(treesSaved),
                  textColor: Colors.black,
                  backgroundColor: const Color.fromARGB(15, 0, 0, 0),
                  fontSizeValue: 20,
                  fontSizeTitle: 18,
                  icon: const Icon(Icons.park, size: 32, color: Colors.black),
                ),
              ),
            ],
          ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: ImpactMetricBox(
                    title: "Paper Diverted",
                    value: "${(totalWeightGrams / 1000).toStringAsFixed(2)} kg",
                    // Converted grams to kg for display
                    textColor: Colors.black,
                    backgroundColor: const Color.fromARGB(15, 0, 0, 0),
                    fontSizeValue: 20,
                    fontSizeTitle: 18,
                    icon: const Icon(
                      Icons.description,
                      size: 32,
                      color: Colors.black,
                    ),
                  ),
                ),
                Expanded(
                  child: ImpactMetricBox(
                    title: "Energy Saved",
                    value: "${formatDouble(energySaved)} kWh",
                    textColor: Colors.black,
                    backgroundColor: const Color.fromARGB(15, 0, 0, 0),
                    fontSizeValue: 20,
                    fontSizeTitle: 18,
                    icon: const Icon(
                      Icons.flash_on,
                      size: 32,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: ImpactMetricBox(
                    title: "Water Saved",
                    value: "${formatDouble(waterSaved)} gal",
                    textColor: Colors.black,
                    backgroundColor: const Color.fromARGB(15, 0, 0, 0),
                    fontSizeValue: 20,
                    fontSizeTitle: 18,
                    icon: const Icon(
                      Icons.water_drop,
                      size: 32,
                      color: Colors.black,
                    ),
                  ),
                ),
                Expanded(
                  child: ImpactMetricBox(
                    title: "CO₂ Reduced",
                    value: "${formatDouble(co2Reduced)} kg",
                    textColor: Colors.black,
                    backgroundColor: const Color.fromARGB(15, 0, 0, 0),
                    fontSizeValue: 20,
                    fontSizeTitle: 18,
                    icon: const Icon(
                      Icons.cloud_off,
                      size: 32,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
