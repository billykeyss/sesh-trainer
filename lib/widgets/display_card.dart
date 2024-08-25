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
              style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            Text(
              '$title $unit',
              style: TextStyle(fontSize: 24, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
