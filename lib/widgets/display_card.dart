import 'package:flutter/material.dart';

class DisplayCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;

  DisplayCard({required this.title, required this.value, required this.unit});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
          ),
          Text(
            '$title $unit',
            style: TextStyle(fontSize: 24, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
