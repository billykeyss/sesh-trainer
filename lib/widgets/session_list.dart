import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/session_database.dart';
import 'session_list_item.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';
import '../utils/number.dart';
import '../providers/theme_provider.dart';
import '../models/info.dart';

class SessionList extends StatefulWidget {
  final List<Session> sessions;
  final void Function(Session) onViewDetails;
  final void Function(Session) onDelete;
  final void Function(Session) onRename;

  const SessionList({
    required this.sessions,
    required this.onViewDetails,
    required this.onDelete,
    required this.onRename,
  });

  @override
  _SessionListState createState() => _SessionListState();
}

class _SessionListState extends State<SessionList> {
  String _selectedSort = 'name'; // Default sorting option
  bool _isAscending = true; // Default sort order

  double _convertWeight(double weight, String fromUnit, String toUnit) {
    if (fromUnit == toUnit) return weight;
    if (fromUnit == Info.Kilogram && toUnit == Info.Pounds) {
      return convertKgToLbs(weight);
    } else if (fromUnit == Info.Pounds && toUnit == Info.Kilogram) {
      return convertLbsToKg(weight);
    }
    return weight; // Fallback, should never hit this if units are correct
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final iconColor = isDarkMode ? Colors.white : Colors.black;

    // Get the default unit from ThemeProvider
    final defaultUnit = Provider.of<ThemeProvider>(context).unit;

    // Sort sessions based on selected option and order
    List<Session> sortedSessions = List.from(widget.sessions);
    sortedSessions.sort((a, b) {
      int comparison;
      switch (_selectedSort) {
        case 'date':
          comparison = a.sessionTime.compareTo(b.sessionTime);
          break;
        case 'maxWeight':
          final aMaxWeight = _convertWeight(
              calculateMaxWeightFromJson(a.graphData), a.weightUnit, defaultUnit);
          final bMaxWeight = _convertWeight(
              calculateMaxWeightFromJson(b.graphData), b.weightUnit, defaultUnit);
          comparison = aMaxWeight.compareTo(bMaxWeight);
          break;
        case 'name':
        default:
          comparison = a.name.compareTo(b.name);
          break;
      }
      return _isAscending ? comparison : -comparison;
    });

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Sort by:', style: TextStyle(fontSize: 16.0)),
              DropdownButton<String>(
                value: _selectedSort,
                items: [
                  DropdownMenuItem(
                    value: 'name',
                    child: Text('Name'),
                  ),
                  DropdownMenuItem(
                    value: 'date',
                    child: Text('Date'),
                  ),
                  DropdownMenuItem(
                    value: 'maxWeight',
                    child: Text('Max Weight'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedSort = value!;
                  });
                },
                dropdownColor: isDarkMode ? Colors.grey[800] : Colors.white,
                style: TextStyle(
                  color: iconColor,
                  fontSize: 16.0,
                ),
                iconEnabledColor: iconColor, // Adjust icon color for dark mode
              ),
              IconButton(
                icon: Icon(
                  _isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  color: iconColor, // Adjust icon color for dark mode
                ),
                onPressed: () {
                  setState(() {
                    _isAscending = !_isAscending;
                  });
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: sortedSessions.length,
            itemBuilder: (context, index) {
              final session = sortedSessions[index];
              return SessionListItem(
                session: session,
                isDarkMode: isDarkMode,
                onViewDetails: widget.onViewDetails,
                onDelete: widget.onDelete,
                onRename: widget.onRename,
              );
            },
          ),
        ),
      ],
    );
  }
}
