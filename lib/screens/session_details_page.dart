import 'dart:typed_data';
import 'package:sesh_trainer/widgets/weight_graph.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import '../utils/number.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:math';
import '../database/session_database.dart';
import '../models/info.dart';
import 'package:drift/drift.dart' as drift;
import '../providers/theme_provider.dart';

// Enums and data classes for modern UI
enum TrendType { positive, negative, neutral }

class _MetricData {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final TrendType trend;

  _MetricData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.trend,
  });
}

class SessionDetailsPage extends StatefulWidget {
  final List<FlSpot> graphData;
  final DateTime sessionStartTime;
  final int elapsedTimeMs;
  final String weightUnit;
  final String sessionName;

  SessionDetailsPage({
    required this.graphData,
    required this.sessionStartTime,
    required this.elapsedTimeMs,
    required this.weightUnit,
    required this.sessionName,
  });

  @override
  _SessionDetailsPageState createState() => _SessionDetailsPageState();
}

class _SessionDetailsPageState extends State<SessionDetailsPage> {
  final ScreenshotController screenshotController = ScreenshotController();
  final TextEditingController _nameController = TextEditingController();
  late final SessionDatabase _database;
  bool _isEditingName = false;

  @override
  void initState() {
    super.initState();
    _database = SessionDatabase();
    _nameController.text = widget.sessionName;
    _checkAndSaveSession();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _checkAndSaveSession() async {
    final sessionExists = await _sessionExists(widget.sessionName);
    if (!sessionExists) {
      _saveSessionDetails(context, widget.sessionName);
    }
  }

  Future<bool> _sessionExists(String name) async {
    final sessions = await _database.getAllSessions();
    return sessions.any((session) => session.name == name);
  }

  void _renameSession(BuildContext context, String newName) async {
    try {
      final sessionExists = await _sessionExists(widget.sessionName);
      if (sessionExists) {
        final sessions = await _database.getAllSessions();
        final session =
            sessions.firstWhere((s) => s.name == widget.sessionName);
        await _database.insertSession(
          SessionsCompanion(
            id: drift.Value(session.id),
            name: drift.Value(newName),
            email: drift.Value(session.email),
            elapsedTimeMs: drift.Value(session.elapsedTimeMs),
            weightUnit: drift.Value(session.weightUnit),
            sessionTime: drift.Value(session.sessionTime),
            graphData: drift.Value(session.graphData),
            data: drift.Value(session.data),
          ),
        );
        await _database.deleteSession(session.id);
      } else {
        _saveSessionDetails(context, newName);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
            child: Text('Session renamed to "$newName" successfully!'),
          ),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
            child: Text('Error renaming session: $e'),
          ),
        ),
      );
    }
  }

  double calculateForceVariability(List<FlSpot> graphData) {
    List<double> weights =
        graphData.where((spot) => spot.y > 0).map((spot) => spot.y).toList();
    if (weights.isEmpty) return 0.0;
    double meanWeight = weights.reduce((a, b) => a + b) / weights.length;
    double variance = weights
            .map((weight) => (weight - meanWeight) * (weight - meanWeight))
            .reduce((a, b) => a + b) /
        weights.length;
    double standardDeviation = sqrt(variance);
    return standardDeviation;
  }

  // Peak Force Rate - Rate of force development (force/time)
  double calculatePeakForceRate(List<FlSpot> graphData) {
    if (graphData.length < 2) return 0.0;

    double maxRate = 0.0;
    for (int i = 1; i < graphData.length; i++) {
      double timeDelta = graphData[i].x - graphData[i - 1].x;
      if (timeDelta > 0) {
        double forceDelta = graphData[i].y - graphData[i - 1].y;
        double rate = forceDelta / timeDelta;
        if (rate > maxRate) {
          maxRate = rate;
        }
      }
    }
    return maxRate;
  }

  // Hold Duration at % of Max - Time spent above percentage thresholds
  Map<String, double> calculateHoldDurations(List<FlSpot> graphData) {
    if (graphData.isEmpty) return {'80%': 0.0, '60%': 0.0, '40%': 0.0};

    double maxForce = graphData.map((spot) => spot.y).reduce(max);
    double threshold80 = maxForce * 0.8;
    double threshold60 = maxForce * 0.6;
    double threshold40 = maxForce * 0.4;

    double time80 = 0.0, time60 = 0.0, time40 = 0.0;

    for (int i = 1; i < graphData.length; i++) {
      double timeDelta = graphData[i].x - graphData[i - 1].x;
      double force = graphData[i].y;

      if (force >= threshold80) time80 += timeDelta;
      if (force >= threshold60) time60 += timeDelta;
      if (force >= threshold40) time40 += timeDelta;
    }

    return {
      '80%': time80,
      '60%': time60,
      '40%': time40,
    };
  }

  // Fatigue Index - Performance drop within session
  double calculateFatigueIndex(List<FlSpot> graphData) {
    if (graphData.length < 10) return 0.0;

    // Compare first 25% vs last 25% of session
    int quarterLength = (graphData.length * 0.25).round();

    List<double> firstQuarter = graphData
        .take(quarterLength)
        .map((spot) => spot.y)
        .where((y) => y > 0)
        .toList();

    List<double> lastQuarter = graphData
        .skip(graphData.length - quarterLength)
        .map((spot) => spot.y)
        .where((y) => y > 0)
        .toList();

    if (firstQuarter.isEmpty || lastQuarter.isEmpty) return 0.0;

    double avgFirst =
        firstQuarter.reduce((a, b) => a + b) / firstQuarter.length;
    double avgLast = lastQuarter.reduce((a, b) => a + b) / lastQuarter.length;

    // Return percentage drop (positive = fatigue, negative = improvement)
    return ((avgFirst - avgLast) / avgFirst) * 100;
  }

  // Time in Force Zones - Distribution across intensity zones
  Map<String, double> calculateTimeInZones(List<FlSpot> graphData) {
    if (graphData.isEmpty)
      return {'Light': 0.0, 'Moderate': 0.0, 'Heavy': 0.0, 'Max': 0.0};

    double maxForce = graphData.map((spot) => spot.y).reduce(max);
    double timeLight = 0.0, timeMod = 0.0, timeHeavy = 0.0, timeMax = 0.0;

    for (int i = 1; i < graphData.length; i++) {
      double timeDelta = graphData[i].x - graphData[i - 1].x;
      double forcePercent = (graphData[i].y / maxForce) * 100;

      if (forcePercent >= 90) {
        timeMax += timeDelta;
      } else if (forcePercent >= 70) {
        timeHeavy += timeDelta;
      } else if (forcePercent >= 40) {
        timeMod += timeDelta;
      } else if (forcePercent >= 10) {
        timeLight += timeDelta;
      }
    }

    return {
      'Light (10-40%)': timeLight,
      'Moderate (40-70%)': timeMod,
      'Heavy (70-90%)': timeHeavy,
      'Max (90%+)': timeMax,
    };
  }

  // Recovery Metrics - Analyze recovery between efforts
  Map<String, double> calculateRecoveryMetrics(List<FlSpot> graphData) {
    if (graphData.length < 20)
      return {'avgRecoveryTime': 0.0, 'recoveryEfficiency': 0.0};

    double maxForce = graphData.map((spot) => spot.y).reduce(max);
    double threshold = maxForce * 0.3; // Consider below 30% as "rest"

    List<double> recoveryTimes = [];
    bool inEffort = false;
    double effortStartTime = 0.0;

    for (int i = 0; i < graphData.length; i++) {
      double force = graphData[i].y;
      double time = graphData[i].x;

      if (!inEffort && force > threshold) {
        // Starting an effort
        inEffort = true;
        effortStartTime = time;
      } else if (inEffort && force <= threshold) {
        // Ending an effort, look for next effort to calculate recovery
        inEffort = false;

        // Find next effort start
        for (int j = i + 1; j < graphData.length; j++) {
          if (graphData[j].y > threshold) {
            double recoveryTime = graphData[j].x - time;
            if (recoveryTime > 1.0) {
              // Only count recoveries > 1 second
              recoveryTimes.add(recoveryTime);
            }
            break;
          }
        }
      }
    }

    double avgRecoveryTime = recoveryTimes.isEmpty
        ? 0.0
        : recoveryTimes.reduce((a, b) => a + b) / recoveryTimes.length;

    // Recovery efficiency: shorter recoveries = better efficiency
    double recoveryEfficiency =
        avgRecoveryTime > 0 ? (60.0 / avgRecoveryTime) * 10 : 0.0;
    recoveryEfficiency = recoveryEfficiency.clamp(0.0, 100.0);

    return {
      'avgRecoveryTime': avgRecoveryTime,
      'recoveryEfficiency': recoveryEfficiency,
    };
  }

  // Session Volume Trends - Compare with recent sessions
  Future<Map<String, String>> calculateVolumeTrends() async {
    try {
      final allSessions = await _database.getAllSessions();
      if (allSessions.length < 2) {
        return {
          'weeklyTrend': 'Insufficient data',
          'monthlyTrend': 'Insufficient data',
        };
      }

      // Sort sessions by date (newest first)
      allSessions.sort((a, b) => b.sessionTime.compareTo(a.sessionTime));

      final currentSession = allSessions.firstWhere(
        (session) => session.name == widget.sessionName,
        orElse: () => allSessions.first,
      );

      final currentTime = currentSession.sessionTime;
      final oneWeekAgo = currentTime.subtract(Duration(days: 7));
      final oneMonthAgo = currentTime.subtract(Duration(days: 30));

      // Calculate current session volume (total load)
      final currentVolume = calculateTotalLoad(widget.graphData);

      // Get sessions from last week and month
      final weekSessions = allSessions
          .where((session) =>
              session.sessionTime.isAfter(oneWeekAgo) &&
              session.sessionTime.isBefore(currentTime))
          .toList();

      final monthSessions = allSessions
          .where((session) =>
              session.sessionTime.isAfter(oneMonthAgo) &&
              session.sessionTime.isBefore(currentTime))
          .toList();

      // Calculate average volumes
      double weeklyAvg = 0.0;
      if (weekSessions.isNotEmpty) {
        double totalWeeklyVolume = 0.0;
        for (var session in weekSessions) {
          final sessionData = (jsonDecode(session.graphData) as List)
              .map((item) => FlSpot(item['x'], item['y']))
              .toList();
          totalWeeklyVolume += calculateTotalLoad(sessionData);
        }
        weeklyAvg = totalWeeklyVolume / weekSessions.length;
      }

      double monthlyAvg = 0.0;
      if (monthSessions.isNotEmpty) {
        double totalMonthlyVolume = 0.0;
        for (var session in monthSessions) {
          final sessionData = (jsonDecode(session.graphData) as List)
              .map((item) => FlSpot(item['x'], item['y']))
              .toList();
          totalMonthlyVolume += calculateTotalLoad(sessionData);
        }
        monthlyAvg = totalMonthlyVolume / monthSessions.length;
      }

      // Calculate trends
      String weeklyTrend = 'No recent data';
      String monthlyTrend = 'No recent data';

      if (weeklyAvg > 0) {
        double weeklyChange = ((currentVolume - weeklyAvg) / weeklyAvg) * 100;
        if (weeklyChange > 10) {
          weeklyTrend = '+${weeklyChange.toStringAsFixed(0)}% vs last week';
        } else if (weeklyChange < -10) {
          weeklyTrend = '${weeklyChange.toStringAsFixed(0)}% vs last week';
        } else {
          weeklyTrend = 'Similar to last week';
        }
      }

      if (monthlyAvg > 0) {
        double monthlyChange =
            ((currentVolume - monthlyAvg) / monthlyAvg) * 100;
        if (monthlyChange > 15) {
          monthlyTrend = '+${monthlyChange.toStringAsFixed(0)}% vs last month';
        } else if (monthlyChange < -15) {
          monthlyTrend = '${monthlyChange.toStringAsFixed(0)}% vs last month';
        } else {
          monthlyTrend = 'Similar to last month';
        }
      }

      return {
        'weeklyTrend': weeklyTrend,
        'monthlyTrend': monthlyTrend,
      };
    } catch (e) {
      return {
        'weeklyTrend': 'Error calculating',
        'monthlyTrend': 'Error calculating',
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 768;

    // Modern color scheme inspired by SaaS dashboards
    final backgroundColor =
        isDarkMode ? const Color(0xFF0A0A0B) : const Color(0xFFFAFAFA);
    final surfaceColor = isDarkMode ? const Color(0xFF1A1A1B) : Colors.white;
    final borderColor =
        isDarkMode ? const Color(0xFF2A2A2B) : const Color(0xFFE5E5E5);
    final textPrimary =
        isDarkMode ? const Color(0xFFFFFFFF) : const Color(0xFF1A1A1B);
    final textSecondary =
        isDarkMode ? const Color(0xFFB3B3B3) : const Color(0xFF6B6B6B);
    final accentColor =
        isDarkMode ? const Color(0xFF3B82F6) : const Color(0xFF2563EB);

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        String selectedUnit = themeProvider.unit;
        // Convert graph data to selected unit if necessary
        List<FlSpot> convertedGraphData = widget.graphData.map((spot) {
          double yValue = spot.y;
          if (selectedUnit == Info.Pounds &&
              widget.weightUnit == Info.Kilogram) {
            yValue = convertKgToLbs(yValue);
          } else if (selectedUnit == Info.Kilogram &&
              widget.weightUnit == Info.Pounds) {
            yValue = convertLbsToKg(yValue);
          }
          return FlSpot(spot.x, yValue);
        }).toList();

        final maxWeight = calculateMaxWeight(convertedGraphData);
        final averageWeight = calculateAverageWeight(convertedGraphData);
        final totalLoad = calculateTotalLoad(convertedGraphData);

        // Calculate advanced metrics
        final peakForceRate = calculatePeakForceRate(convertedGraphData);
        final holdDurations = calculateHoldDurations(convertedGraphData);
        final fatigueIndex = calculateFatigueIndex(convertedGraphData);
        final timeInZones = calculateTimeInZones(convertedGraphData);
        final recoveryMetrics = calculateRecoveryMetrics(convertedGraphData);

        return Scaffold(
          backgroundColor: backgroundColor,
          body: CustomScrollView(
            slivers: [
              // Modern SliverAppBar with glass morphism effect
              SliverAppBar(
                expandedHeight: 120.0,
                floating: false,
                pinned: true,
                elevation: 0,
                backgroundColor: surfaceColor.withOpacity(0.8),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          accentColor.withOpacity(0.1),
                          accentColor.withOpacity(0.05),
                        ],
                      ),
                    ),
                  ),
                  title: _buildModernTitle(textPrimary, textSecondary),
                  titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                ),
                actions: [
                  _buildModernActionButton(
                    icon: Icons.edit_outlined,
                    onPressed: () => _toggleNameEdit(),
                    tooltip: 'Edit session name',
                  ),
                  _buildModernActionButton(
                    icon: Icons.share_outlined,
                    onPressed: () => _shareSessionDetails(context),
                    tooltip: 'Share session',
                  ),
                  const SizedBox(width: 8),
                ],
              ),

              // Main content
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 32.0 : 16.0,
                    vertical: 24.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hero metrics cards
                      _buildHeroMetricsGrid(
                        maxWeight: maxWeight,
                        averageWeight: averageWeight,
                        totalLoad: totalLoad,
                        selectedUnit: selectedUnit,
                        surfaceColor: surfaceColor,
                        borderColor: borderColor,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        accentColor: accentColor,
                        isTablet: isTablet,
                      ),

                      const SizedBox(height: 32),

                      // Graph section with modern styling
                      _buildModernGraphSection(
                        convertedGraphData: convertedGraphData,
                        selectedUnit: selectedUnit,
                        surfaceColor: surfaceColor,
                        borderColor: borderColor,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),

                      const SizedBox(height: 32),

                      // Session info section
                      _buildModernSection(
                        title: 'Session Overview',
                        icon: Icons.info_outline,
                        children: [
                          _buildModernMetricCard(
                            title: 'Session Date',
                            value: DateFormat('MMM d, yyyy')
                                .format(widget.sessionStartTime),
                            subtitle: DateFormat('h:mm a')
                                .format(widget.sessionStartTime),
                            icon: Icons.calendar_today_outlined,
                            surfaceColor: surfaceColor,
                            borderColor: borderColor,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                          ),
                          _buildModernMetricCard(
                            title: 'Duration',
                            value: formatElapsedTimeIntToString(
                                widget.elapsedTimeMs),
                            subtitle: 'Total session time',
                            icon: Icons.timer_outlined,
                            surfaceColor: surfaceColor,
                            borderColor: borderColor,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                          ),
                        ],
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        accentColor: accentColor,
                      ),

                      const SizedBox(height: 32),

                      // Performance metrics in responsive grid
                      _buildModernSection(
                        title: 'Performance Analysis',
                        icon: Icons.trending_up_outlined,
                        children: [
                          _buildMetricsGrid([
                            _MetricData(
                              title: 'Peak Force Rate',
                              value:
                                  '${peakForceRate.toStringAsFixed(1)} $selectedUnit/s',
                              subtitle: 'Rate of force development',
                              icon: Icons.speed_outlined,
                              trend: peakForceRate > 50
                                  ? TrendType.positive
                                  : TrendType.neutral,
                            ),
                            _MetricData(
                              title: 'Force Consistency',
                              value:
                                  '${calculateForceVariability(convertedGraphData).toStringAsFixed(2)}',
                              subtitle: 'Standard deviation',
                              icon: Icons.show_chart_outlined,
                              trend: calculateForceVariability(
                                          convertedGraphData) <
                                      10
                                  ? TrendType.positive
                                  : TrendType.neutral,
                            ),
                            _MetricData(
                              title: 'Fatigue Index',
                              value: '${fatigueIndex.toStringAsFixed(1)}%',
                              subtitle: _getFatigueDescription(fatigueIndex),
                              icon: Icons.battery_charging_full_outlined,
                              trend: fatigueIndex < 5
                                  ? TrendType.positive
                                  : fatigueIndex > 15
                                      ? TrendType.negative
                                      : TrendType.neutral,
                            ),
                          ], surfaceColor, borderColor, textPrimary,
                              textSecondary, accentColor, isTablet),
                        ],
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        accentColor: accentColor,
                      ),

                      const SizedBox(height: 32),

                      // Endurance analysis
                      _buildModernSection(
                        title: 'Endurance Breakdown',
                        icon: Icons.fitness_center_outlined,
                        children: [
                          _buildEnduranceChart(
                              holdDurations,
                              surfaceColor,
                              borderColor,
                              textPrimary,
                              textSecondary,
                              accentColor),
                        ],
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        accentColor: accentColor,
                      ),

                      const SizedBox(height: 32),

                      // Training zones
                      _buildModernSection(
                        title: 'Training Intensity Zones',
                        icon: Icons.donut_small_outlined,
                        children: [
                          _buildIntensityZones(
                              timeInZones,
                              surfaceColor,
                              borderColor,
                              textPrimary,
                              textSecondary,
                              accentColor),
                        ],
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        accentColor: accentColor,
                      ),

                      const SizedBox(height: 32),

                      // Recovery analysis
                      _buildModernSection(
                        title: 'Recovery Analysis',
                        icon: Icons.restore_outlined,
                        children: [
                          _buildMetricsGrid([
                            _MetricData(
                              title: 'Avg Recovery Time',
                              value:
                                  '${recoveryMetrics['avgRecoveryTime']!.toStringAsFixed(1)}s',
                              subtitle: 'Time between efforts',
                              icon: Icons.timer_outlined,
                              trend: recoveryMetrics['avgRecoveryTime']! < 30
                                  ? TrendType.positive
                                  : TrendType.neutral,
                            ),
                            _MetricData(
                              title: 'Recovery Efficiency',
                              value:
                                  '${recoveryMetrics['recoveryEfficiency']!.toStringAsFixed(0)}%',
                              subtitle: 'Recovery quality score',
                              icon: Icons.trending_up_outlined,
                              trend: recoveryMetrics['recoveryEfficiency']! > 70
                                  ? TrendType.positive
                                  : TrendType.neutral,
                            ),
                          ], surfaceColor, borderColor, textPrimary,
                              textSecondary, accentColor, isTablet),
                        ],
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        accentColor: accentColor,
                      ),

                      const SizedBox(height: 32),

                      // Volume trends
                      FutureBuilder<Map<String, String>>(
                        future: calculateVolumeTrends(),
                        builder: (context, snapshot) {
                          return _buildModernSection(
                            title: 'Progress Tracking',
                            icon: Icons.analytics_outlined,
                            children: [
                              if (snapshot.hasData) ...[
                                _buildTrendCard(
                                  title: 'Weekly Trend',
                                  value: snapshot.data!['weeklyTrend']!,
                                  subtitle: 'vs last 7 days',
                                  icon: Icons.calendar_view_week_outlined,
                                  surfaceColor: surfaceColor,
                                  borderColor: borderColor,
                                  textPrimary: textPrimary,
                                  textSecondary: textSecondary,
                                  accentColor: accentColor,
                                ),
                                _buildTrendCard(
                                  title: 'Monthly Trend',
                                  value: snapshot.data!['monthlyTrend']!,
                                  subtitle: 'vs last 30 days',
                                  icon: Icons.calendar_view_month_outlined,
                                  surfaceColor: surfaceColor,
                                  borderColor: borderColor,
                                  textPrimary: textPrimary,
                                  textSecondary: textSecondary,
                                  accentColor: accentColor,
                                ),
                              ] else ...[
                                _buildLoadingCard(
                                    surfaceColor, borderColor, textSecondary),
                              ],
                            ],
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                            accentColor: accentColor,
                          );
                        },
                      ),

                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModernTitle(Color textPrimary, Color textSecondary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isEditingName)
          SizedBox(
            width: 200,
            child: TextField(
              controller: _nameController,
              style: TextStyle(
                color: textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                border: UnderlineInputBorder(
                  borderSide: BorderSide(color: textSecondary),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: textPrimary),
                ),
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onSubmitted: (newName) {
                if (newName.isNotEmpty) {
                  _renameSession(context, newName);
                }
                setState(() => _isEditingName = false);
              },
              autofocus: true,
            ),
          )
        else
          GestureDetector(
            onTap: _toggleNameEdit,
            child: Text(
              _nameController.text,
              style: TextStyle(
                color: textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
              ),
            ),
          ),
        const SizedBox(height: 4),
        Text(
          'Training Session',
          style: TextStyle(
            color: textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildModernActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              size: 20,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroMetricsGrid({
    required double maxWeight,
    required double averageWeight,
    required double totalLoad,
    required String selectedUnit,
    required Color surfaceColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    required Color accentColor,
    required bool isTablet,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = isTablet ? 3 : 1;
        final childAspectRatio = isTablet ? 1.2 : 2.5;

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: childAspectRatio,
          children: [
            _buildHeroMetricCard(
              title: 'Max Pull',
              value: maxWeight.toStringAsFixed(1),
              unit: selectedUnit,
              icon: Icons.trending_up,
              gradient: [accentColor, accentColor.withOpacity(0.7)],
              surfaceColor: surfaceColor,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
            _buildHeroMetricCard(
              title: 'Average Pull',
              value: averageWeight.toStringAsFixed(1),
              unit: selectedUnit,
              icon: Icons.show_chart,
              gradient: [Colors.orange, Colors.orange.withOpacity(0.7)],
              surfaceColor: surfaceColor,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
            _buildHeroMetricCard(
              title: 'Total Load',
              value: totalLoad.toStringAsFixed(0),
              unit: '${selectedUnit}·s',
              icon: Icons.fitness_center,
              gradient: [Colors.green, Colors.green.withOpacity(0.7)],
              surfaceColor: surfaceColor,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeroMetricCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required List<Color> gradient,
    required Color surfaceColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradient),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                color: textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    unit,
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernGraphSection({
    required List<FlSpot> convertedGraphData,
    required String selectedUnit,
    required Color surfaceColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(
                  Icons.analytics_outlined,
                  color: textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Force Over Time',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 300,
            padding: const EdgeInsets.only(left: 8, right: 20, bottom: 20),
            child: WeightGraph(
              graphData: convertedGraphData,
              weightUnit: selectedUnit,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
    required Color textPrimary,
    required Color textSecondary,
    required Color accentColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: accentColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildModernMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color surfaceColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: textSecondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: textSecondary,
                size: 18,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsGrid(
    List<_MetricData> metrics,
    Color surfaceColor,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
    Color accentColor,
    bool isTablet,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = isTablet ? 3 : 1;
        final childAspectRatio = isTablet ? 1.1 : 2.8;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: metrics.length,
          itemBuilder: (context, index) {
            final metric = metrics[index];
            return _buildMetricCard(
              metric: metric,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              accentColor: accentColor,
            );
          },
        );
      },
    );
  }

  Widget _buildMetricCard({
    required _MetricData metric,
    required Color surfaceColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    required Color accentColor,
  }) {
    Color trendColor = textSecondary;
    IconData? trendIcon;

    switch (metric.trend) {
      case TrendType.positive:
        trendColor = Colors.green;
        trendIcon = Icons.trending_up;
        break;
      case TrendType.negative:
        trendColor = Colors.red;
        trendIcon = Icons.trending_down;
        break;
      case TrendType.neutral:
        trendColor = textSecondary;
        trendIcon = Icons.trending_flat;
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  metric.icon,
                  color: textSecondary,
                  size: 20,
                ),
                const Spacer(),
                if (trendIcon != null)
                  Icon(
                    trendIcon,
                    color: trendColor,
                    size: 16,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              metric.title,
              style: TextStyle(
                color: textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              metric.value,
              style: TextStyle(
                color: textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              metric.subtitle,
              style: TextStyle(
                color: textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnduranceChart(
    Map<String, double> holdDurations,
    Color surfaceColor,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
    Color accentColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: holdDurations.entries.map((entry) {
            final percentage = entry.key;
            final time = entry.value;
            final maxTime = holdDurations.values.reduce(max);
            final progress = maxTime > 0 ? time / maxTime : 0.0;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Time at $percentage Max',
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${time.toStringAsFixed(1)}s',
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: borderColor,
                    valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                    minHeight: 6,
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildIntensityZones(
    Map<String, double> timeInZones,
    Color surfaceColor,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
    Color accentColor,
  ) {
    final colors = [
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.purple,
    ];

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: timeInZones.entries.toList().asMap().entries.map((entry) {
            final index = entry.key;
            final zoneEntry = entry.value;
            final zoneName = zoneEntry.key;
            final time = zoneEntry.value;
            final color = colors[index % colors.length];

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      zoneName,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    '${time.toStringAsFixed(1)}s',
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTrendCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color surfaceColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    required Color accentColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: accentColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingCard(
      Color surfaceColor, Color borderColor, Color textSecondary) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(textSecondary),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              'Calculating trends...',
              style: TextStyle(
                color: textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleNameEdit() {
    setState(() {
      _isEditingName = !_isEditingName;
    });
  }

  String _getFatigueDescription(double fatigueIndex) {
    if (fatigueIndex > 15) return 'High fatigue detected';
    if (fatigueIndex > 5) return 'Moderate fatigue';
    if (fatigueIndex < -5) return 'Performance improved';
    return 'Consistent performance';
  }

  void _saveSessionDetails(BuildContext context, String name) async {
    try {
      final newSession = SessionsCompanion(
        name: drift.Value(name),
        email: drift.Value(''), // Keep empty for personal training
        elapsedTimeMs: drift.Value(widget.elapsedTimeMs),
        weightUnit: drift.Value(widget.weightUnit),
        sessionTime: drift.Value(widget.sessionStartTime),
        graphData: drift.Value(jsonEncode(widget.graphData
            .map((spot) => {'x': spot.x, 'y': spot.y})
            .toList())),
        data: drift.Value(''),
      );
      await _database.insertSession(newSession);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
            child: Text('Session "$name" saved successfully!'),
          ),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
            child: Text('Error saving session: $e'),
          ),
        ),
      );
    }
  }

  void _shareSessionDetails(BuildContext context) async {
    try {
      final Uint8List? screenshot = await screenshotController.capture();
      if (screenshot == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
              child: Text('Failed to capture screenshot.'),
            ),
          ),
        );
        return;
      }

      final directory = await Directory.systemTemp.createTemp();
      final imagePath = '${directory.path}/screenshot.png';
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(screenshot);

      await Share.shareXFiles([XFile(imagePath)],
          text: 'Check out my climbing training session!');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
            child: Text('Error sharing session: $e'),
          ),
        ),
      );
    }
  }
}
