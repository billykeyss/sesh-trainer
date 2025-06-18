import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../database/session_database.dart';
import '../providers/theme_provider.dart';
import 'session_details_page.dart';
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import '../utils/number.dart';
import '../models/info.dart';

class CalendarView extends StatefulWidget {
  @override
  _CalendarViewState createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  late final SessionDatabase _database;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Session>> _sessionsByDate = {};
  List<Session> _selectedDaySessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _database = SessionDatabase();
    _selectedDay = DateTime.now();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final sessions = await _database.getAllSessions();
      final Map<DateTime, List<Session>> sessionsByDate = {};

      for (var session in sessions) {
        final date = DateTime(
          session.sessionTime.year,
          session.sessionTime.month,
          session.sessionTime.day,
        );

        if (sessionsByDate[date] == null) {
          sessionsByDate[date] = [];
        }
        sessionsByDate[date]!.add(session);
      }

      setState(() {
        _sessionsByDate = sessionsByDate;
        _selectedDaySessions = _getSessionsForDay(_selectedDay!);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading sessions: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Session> _getSessionsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _sessionsByDate[normalizedDay] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        _selectedDaySessions = _getSessionsForDay(selectedDay);
      });
    }
  }

  void _viewSessionDetails(Session session) {
    final List<FlSpot> graphData = (jsonDecode(session.graphData) as List)
        .map((item) => FlSpot(item['x'], item['y']))
        .toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SessionDetailsPage(
          graphData: graphData,
          sessionStartTime: session.sessionTime,
          elapsedTimeMs: session.elapsedTimeMs,
          weightUnit: session.weightUnit,
          sessionName: session.name,
        ),
      ),
    );
  }

  double _getMaxWeight(Session session, String displayUnit) {
    final List<FlSpot> graphData = (jsonDecode(session.graphData) as List)
        .map((item) => FlSpot(item['x'], item['y']))
        .toList();

    if (graphData.isEmpty) return 0.0;

    double maxWeight =
        graphData.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);

    // Convert weight if necessary
    if (displayUnit == Info.Pounds && session.weightUnit == Info.Kilogram) {
      maxWeight = convertKgToLbs(maxWeight);
    } else if (displayUnit == Info.Kilogram &&
        session.weightUnit == Info.Pounds) {
      maxWeight = convertLbsToKg(maxWeight);
    }

    return maxWeight;
  }

  String _formatDuration(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }

  String _getDisplayName(Session session) {
    final lower = session.name.toLowerCase();
    if (lower.startsWith('session') || lower.startsWith('circuit training')) {
      return DateFormat('MMM d, yyyy – HH:mm').format(session.sessionTime);
    }
    return session.name;
  }

  String _getSessionType(Session session) {
    try {
      if (session.data != null && session.data.isNotEmpty) {
        final parsed = jsonDecode(session.data);
        if (parsed is Map<String, dynamic>) {
          final raw =
              (parsed['sessionType'] ?? parsed['type'] ?? 'pull').toString();
          switch (raw) {
            case 'pull':
              return 'Pull';
            case 'hangboard':
              return 'Hangboard';
            case 'circuit_training':
              return 'Circuit';
            default:
              return raw.toString();
          }
        }
      }
    } catch (_) {}
    return 'Pull';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final selectedUnit = themeProvider.unit;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.withOpacity(0.2),
                    Colors.purple.withOpacity(0.1)
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.calendar_today,
                color: Colors.blue,
                size: 20,
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Training Calendar',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : Colors.grey[800],
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadSessions,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            )
          : Column(
              children: [
                // Calendar widget
                Container(
                  margin: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[850] : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: isDarkMode
                            ? Colors.black26
                            : Colors.grey.withOpacity(0.1),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TableCalendar<Session>(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    calendarFormat: _calendarFormat,
                    eventLoader: _getSessionsForDay,
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    selectedDayPredicate: (day) {
                      return isSameDay(_selectedDay, day);
                    },
                    onDaySelected: _onDaySelected,
                    onFormatChanged: (format) {
                      if (_calendarFormat != format) {
                        setState(() {
                          _calendarFormat = format;
                        });
                      }
                    },
                    onPageChanged: (focusedDay) {
                      _focusedDay = focusedDay;
                    },
                    calendarStyle: CalendarStyle(
                      outsideDaysVisible: false,
                      weekendTextStyle: TextStyle(
                        color: isDarkMode ? Colors.red[300] : Colors.red[600],
                      ),
                      holidayTextStyle: TextStyle(
                        color: isDarkMode ? Colors.red[300] : Colors.red[600],
                      ),
                      selectedDecoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      todayDecoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      markerDecoration: BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                      markersMaxCount: 3,
                      canMarkersOverflow: true,
                      defaultTextStyle: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    headerStyle: HeaderStyle(
                      formatButtonVisible: true,
                      titleCentered: true,
                      formatButtonShowsNext: false,
                      formatButtonDecoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      formatButtonTextStyle: TextStyle(
                        color: Colors.white,
                      ),
                      titleTextStyle: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      leftChevronIcon: Icon(
                        Icons.chevron_left,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                      rightChevronIcon: Icon(
                        Icons.chevron_right,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ),

                // Sessions for selected day
                Expanded(
                  child: Container(
                    margin: EdgeInsets.fromLTRB(12, 0, 12, 12),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[850] : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: isDarkMode
                              ? Colors.black26
                              : Colors.grey.withOpacity(0.1),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header for selected day
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.blue.withOpacity(0.1),
                                Colors.purple.withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.fitness_center,
                                color: Colors.blue,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                _selectedDay != null
                                    ? DateFormat('EEEE, MMMM d, yyyy')
                                        .format(_selectedDay!)
                                    : 'Select a day',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode
                                      ? Colors.white
                                      : Colors.grey[800],
                                ),
                              ),
                              Spacer(),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${_selectedDaySessions.length} session${_selectedDaySessions.length != 1 ? 's' : ''}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Sessions list
                        Expanded(
                          child: _selectedDaySessions.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.event_busy,
                                        size: 48,
                                        color: isDarkMode
                                            ? Colors.grey[600]
                                            : Colors.grey[400],
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        'No training sessions',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: isDarkMode
                                              ? Colors.grey[400]
                                              : Colors.grey[600],
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Complete a training session to see it here',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: isDarkMode
                                              ? Colors.grey[500]
                                              : Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  padding: EdgeInsets.all(16),
                                  itemCount: _selectedDaySessions.length,
                                  itemBuilder: (context, index) {
                                    final session = _selectedDaySessions[index];
                                    final maxWeight =
                                        _getMaxWeight(session, selectedUnit);

                                    return Dismissible(
                                      key: ValueKey(session.id),
                                      direction: DismissDirection.endToStart,
                                      background: Container(
                                        alignment: Alignment.centerRight,
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 20),
                                        color: Colors.red,
                                        child: Icon(Icons.delete,
                                            color: Colors.white),
                                      ),
                                      confirmDismiss: (dir) async {
                                        return await showDialog(
                                          context: context,
                                          builder: (_) => AlertDialog(
                                            title: Text('Delete session?'),
                                            content: Text(
                                                'This action cannot be undone.'),
                                            actions: [
                                              TextButton(
                                                child: Text('Cancel'),
                                                onPressed: () =>
                                                    Navigator.of(context)
                                                        .pop(false),
                                              ),
                                              TextButton(
                                                child: Text('Delete'),
                                                onPressed: () =>
                                                    Navigator.of(context)
                                                        .pop(true),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                      onDismissed: (_) async {
                                        await _database
                                            .deleteSession(session.id);
                                        _loadSessions();
                                      },
                                      child: Container(
                                        margin: EdgeInsets.only(bottom: 12),
                                        decoration: BoxDecoration(
                                          color: isDarkMode
                                              ? Colors.grey[800]
                                              : Colors.grey[50],
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: Colors.blue.withOpacity(0.2),
                                            width: 1,
                                          ),
                                        ),
                                        child: ListTile(
                                          contentPadding: EdgeInsets.all(16),
                                          leading: Container(
                                            padding: EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  Colors.blue.withOpacity(0.2),
                                                  Colors.purple
                                                      .withOpacity(0.1),
                                                ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              Icons.trending_up,
                                              color: Colors.blue,
                                              size: 24,
                                            ),
                                          ),
                                          title: Text(
                                            _getDisplayName(session),
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: isDarkMode
                                                  ? Colors.white
                                                  : Colors.grey[800],
                                            ),
                                          ),
                                          subtitle: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.label,
                                                    size: 16,
                                                    color: Colors.green,
                                                  ),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    _getSessionType(session),
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Colors.green,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.schedule,
                                                    size: 16,
                                                    color: isDarkMode
                                                        ? Colors.grey[400]
                                                        : Colors.grey[600],
                                                  ),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    DateFormat('HH:mm').format(
                                                        session.sessionTime),
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: isDarkMode
                                                          ? Colors.grey[400]
                                                          : Colors.grey[600],
                                                    ),
                                                  ),
                                                  SizedBox(width: 16),
                                                  Icon(
                                                    Icons.timer,
                                                    size: 16,
                                                    color: isDarkMode
                                                        ? Colors.grey[400]
                                                        : Colors.grey[600],
                                                  ),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    _formatDuration(
                                                        session.elapsedTimeMs),
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: isDarkMode
                                                          ? Colors.grey[400]
                                                          : Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.fitness_center,
                                                    size: 16,
                                                    color: Colors.orange,
                                                  ),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    'Max: ${maxWeight.toStringAsFixed(1)} $selectedUnit',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Colors.orange,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          trailing: Icon(
                                            Icons.arrow_forward_ios,
                                            size: 16,
                                            color: isDarkMode
                                                ? Colors.grey[400]
                                                : Colors.grey[600],
                                          ),
                                          onTap: () =>
                                              _viewSessionDetails(session),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
