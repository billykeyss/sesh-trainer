import 'package:ble_scale_app/providers/dyno_data_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/info.dart';

import '../utils/number.dart';
import 'display_card.dart';
import '../providers/theme_provider.dart'; // Import the ThemeProvider

class DynoDataDisplay extends StatelessWidget {
  final int crossAxisCount;

  DynoDataDisplay({
    required this.crossAxisCount,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<DynoDataProvider, ThemeProvider>(
      builder: (context, dynoDataProvider, themeProvider, child) {
        double? weight = dynoDataProvider.weight;
        final String selectedUnit = themeProvider.unit;
        final Map<String, double?> maxWeights = dynoDataProvider.maxWeights;
        final Stopwatch stopwatch = dynoDataProvider.stopwatch;

        // Convert weight to selected unit if necessary
        if (selectedUnit == Info.Pounds && dynoDataProvider.weightUnit == Info.Kilogram) {
          weight = weight != null ? convertKgToLbs(weight) : null;
        } else if (selectedUnit == Info.Kilogram && dynoDataProvider.weightUnit == Info.Pounds) {
          weight = weight != null ? convertLbsToKg(weight) : null;
        }

        double? maxWeight = maxWeights[dynoDataProvider.weightUnit];
        if (selectedUnit == Info.Pounds && dynoDataProvider.weightUnit == Info.Kilogram) {
          maxWeight = maxWeight != null ? convertKgToLbs(maxWeight) : null;
        } else if (selectedUnit == Info.Kilogram && dynoDataProvider.weightUnit == Info.Pounds) {
          maxWeight = maxWeight != null ? convertLbsToKg(maxWeight) : null;
        }

        return Flexible(
          child: GridView.count(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 1,
            padding: const EdgeInsets.all(8.0),
            children: [
              DisplayCard(
                title: 'Pull',
                value: '${weight?.toStringAsFixed(1) ?? '0.0'}',
                unit: selectedUnit,
              ),
              DisplayCard(
                title: 'Max',
                value: '${maxWeight?.toStringAsFixed(1) ?? '0.0'}',
                unit: selectedUnit,
              ),
              DisplayCard(
                title: 'Elapsed Time',
                value: formatElapsedTime(stopwatch.elapsed),
                unit: '',
              ),
            ],
          ),
        );
      },
    );
  }

  double convertKgToLbs(double kg) {
    return kg * 2.20462;
  }

  double convertLbsToKg(double lbs) {
    return lbs / 2.20462;
  }
}
