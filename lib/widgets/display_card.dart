import 'package:flutter/material.dart';

class DisplayCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;

  DisplayCard({required this.title, required this.value, required this.unit});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200, // Set maximum height here
      child: Card(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            Text(
              '$title $unit',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
