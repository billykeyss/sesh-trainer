import 'package:ble_scale_app/providers/dyno_data_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../utils/number.dart';
import 'display_card.dart';

class DynoDataDisplay extends StatelessWidget {
  final int crossAxisCount;

  DynoDataDisplay({
    required this.crossAxisCount,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<DynoDataProvider>(
      builder: (context, dynoDataProvider, child) {
        final double? weight = dynoDataProvider.weight;
        final String weightUnit = dynoDataProvider.weightUnit;
        final Map<String, double?> maxWeights = dynoDataProvider.maxWeights;
        final Stopwatch stopwatch = dynoDataProvider.stopwatch;

        return Expanded(
          flex: 3,
          child: GridView.count(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 1,
            padding: const EdgeInsets.all(8.0),
            children: [
              DisplayCard(
                title: 'Weight',
                value: '${weight?.toStringAsFixed(1) ?? '0.0'}',
                unit: weightUnit,
              ),
              DisplayCard(
                title: 'Max',
                value: '${maxWeights[weightUnit]?.toStringAsFixed(1) ?? '0.0'}',
                unit: weightUnit,
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
}
