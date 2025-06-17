import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' as drift;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sesh_trainer/database/session_database.dart';
import 'package:sesh_trainer/models/info.dart';
import 'package:sesh_trainer/providers/dyno_data_provider.dart';
import 'package:sesh_trainer/providers/theme_provider.dart';
import 'package:sesh_trainer/widgets/weight_graph.dart';

// New enum to differentiate between training types
enum CircuitSessionType { pull, hangboard }

class CircuitTrainingScreen extends StatefulWidget {
  const CircuitTrainingScreen({Key? key}) : super(key: key);

  @override
  _CircuitTrainingScreenState createState() => _CircuitTrainingScreenState();
}

class _CircuitTrainingScreenState extends State<CircuitTrainingScreen> {
  int pullDuration = 10; // seconds
  int restDuration = 5; // seconds
  int numCircuits = 5;
  bool isRunning = false;
  Timer? timer;
  int currentTime = 0;
  bool isPullPhase = true;
  int currentCircuit = 0;
  List<double> maxWeights = [];
  List<CircuitData> circuitSessions = [];
  DateTime? sessionStartTime;
  late final SessionDatabase _database;

  // === New variables for Hangboard support and countdown ===
  CircuitSessionType sessionType = CircuitSessionType.pull;
  int pullEdge = 20; // Edge size in mm for hangboard

  // Small countdown before each phase (pull/rest)
  static const int _preCountdownSeconds = 3;
  bool isCountdown = false;
  int countdownTime = 0;

  @override
  void initState() {
    super.initState();
    _database = SessionDatabase();
    // Start scanning for devices when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DynoDataProvider>(context, listen: false).scanForDevices();
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void startCircuit() {
    if (isRunning) return;

    setState(() {
      isRunning = true;
      currentCircuit = 0;
      maxWeights = [];
      circuitSessions = [];
      sessionStartTime = DateTime.now();
      isPullPhase = true;
      // Start with a short countdown before the first pull/hold begins
      isCountdown = true;
      countdownTime = _preCountdownSeconds;
      currentTime = 0;
    });

    final dynoProvider = Provider.of<DynoDataProvider>(context, listen: false);
    // Only reset / start data when using the pull (scale) mode.
    if (sessionType == CircuitSessionType.pull) {
      dynoProvider.resetData();
    }
    _startTimer();
  }

  void stopCircuit({bool isComplete = false}) {
    timer?.cancel();
    setState(() {
      isRunning = false;
    });
    final dynoProvider = Provider.of<DynoDataProvider>(context, listen: false);
    if (sessionType == CircuitSessionType.pull) {
      dynoProvider.stopData();
    }

    if (isComplete && sessionStartTime != null) {
      _saveCircuitSession();
    }
  }

  void resetCircuit() {
    timer?.cancel();
    setState(() {
      isRunning = false;
      currentCircuit = 0;
      maxWeights = [];
      circuitSessions = [];
      sessionStartTime = null;
      isPullPhase = true;
      currentTime = 0;
      isCountdown = false;
      countdownTime = 0;
    });
    if (sessionType == CircuitSessionType.pull) {
      Provider.of<DynoDataProvider>(context, listen: false).resetData();
    }
  }

  void _startTimer() {
    final dynoProvider = Provider.of<DynoDataProvider>(context, listen: false);

    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        // Handle pre-phase countdown
        if (isCountdown) {
          if (countdownTime > 0) {
            countdownTime--;
          } else {
            // Countdown finished – start the actual phase timer
            isCountdown = false;

            // Start data collection only for pull mode during pull phase
            if (sessionType == CircuitSessionType.pull && isPullPhase) {
              dynoProvider.startData();
            }

            currentTime = isPullPhase ? pullDuration : restDuration;
          }
          return; // Skip the rest while in countdown
        }

        // Handle active phase timing
        if (currentTime > 0) {
          currentTime--;
          return;
        }

        // Phase finished – clean-up / transition
        if (isPullPhase) {
          // End of pull or hold phase
          double maxWeight = 0.0;
          List<FlSpot> graph = [];
          if (sessionType == CircuitSessionType.pull) {
            maxWeight = dynoProvider.maxWeights[dynoProvider.weightUnit] ?? 0;
            graph = List.from(dynoProvider.graphData);
            maxWeights.add(maxWeight);
            // Reset data for next phase
            dynoProvider.resetData();
          }

          circuitSessions.add(CircuitData(
            circuitNumber: currentCircuit + 1,
            maxWeight: maxWeight,
            graphData: graph,
            duration: pullDuration,
          ));

          isPullPhase = false;
        } else {
          // End of rest phase – advance circuit counter
          currentCircuit++;
          if (currentCircuit >= numCircuits) {
            stopCircuit(isComplete: true);
            return;
          }
          isPullPhase = true;
        }

        // Prepare for next phase with a countdown
        isCountdown = true;
        countdownTime = _preCountdownSeconds;

        // Stop recording during rest for pull mode
        if (sessionType == CircuitSessionType.pull && !isPullPhase) {
          dynoProvider.stopData();
        }
      });
    });
  }

  void _saveCircuitSession() async {
    if (sessionStartTime == null) return;

    final sessionName =
        'Circuit Training - ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.now())}';

    // Calculate total session duration
    final totalDuration = DateTime.now().difference(sessionStartTime!);

    // Create combined graph data from all circuits
    List<FlSpot> combinedGraphData = [];
    double timeOffset = 0;

    for (var circuit in circuitSessions) {
      for (var spot in circuit.graphData) {
        combinedGraphData.add(FlSpot(spot.x + timeOffset, spot.y));
      }
      timeOffset += circuit.duration + restDuration; // Add pull + rest duration
    }

    // Save session using database directly
    try {
      final newSession = SessionsCompanion(
        name: drift.Value(sessionName),
        email: drift.Value(''), // Keep empty for personal training
        elapsedTimeMs: drift.Value(totalDuration.inMilliseconds),
        weightUnit: drift.Value(Info.Kilogram), // Circuit training uses kg
        sessionTime: drift.Value(sessionStartTime!),
        graphData: drift.Value(jsonEncode(combinedGraphData
            .map((spot) => {'x': spot.x, 'y': spot.y})
            .toList())),
        data: drift.Value(jsonEncode({
          'type': 'circuit_training',
          'sessionType':
              sessionType == CircuitSessionType.pull ? 'pull' : 'hangboard',
          'pullDuration': pullDuration,
          'restDuration': restDuration,
          'numCircuits': numCircuits,
          'maxWeights': maxWeights,
          if (sessionType == CircuitSessionType.hangboard) 'edge': pullEdge,
        })),
      );

      await _database.insertSession(newSession);
      print('Circuit session saved: $sessionName');
    } catch (e) {
      print('Error saving circuit session: $e');
    }

    // Show completion dialog
    _showCompletionDialog(sessionName);
  }

  void _showCompletionDialog(String sessionName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 8),
              Text(
                'Circuit Complete!',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.grey[800],
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Session saved as:',
                style: TextStyle(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              SizedBox(height: 4),
              Text(
                sessionName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.grey[800],
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Circuits completed: $numCircuits',
                style: TextStyle(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              if (sessionType == CircuitSessionType.pull &&
                  maxWeights.isNotEmpty)
                Text(
                  'Best pull: ${maxWeights.reduce((a, b) => a > b ? a : b).toStringAsFixed(1)} kg',
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              if (sessionType == CircuitSessionType.hangboard)
                Text(
                  'Edge Size: ${pullEdge} mm',
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK', style: TextStyle(color: Colors.blue)),
            ),
          ],
        );
      },
    );
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
                Icons.timer,
                color: Colors.blue,
                size: 20,
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Circuit Training',
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
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Integrated status and data display section - fixed height
            Container(
              padding: EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Status bar integrated at top
                  _buildIntegratedStatusBar(context, isDarkMode),
                  SizedBox(height: 12),

                  // Main metrics in a more compact layout
                  if (isRunning)
                    _buildMainMetrics(context, isDarkMode, selectedUnit)
                  else
                    _buildConfigurationMetrics(context, isDarkMode),
                ],
              ),
            ),

            // Graph section - takes remaining space OR config section
            Expanded(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 12),
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
                child: isRunning
                    ? (sessionType == CircuitSessionType.pull
                        ? Consumer<DynoDataProvider>(
                            builder: (context, dynoDataProvider, child) {
                              final graphData =
                                  dynoDataProvider.graphData.map((spot) {
                                double convertedWeight = spot.y;
                                if (selectedUnit == Info.Pounds &&
                                    dynoDataProvider.weightUnit ==
                                        Info.Kilogram) {
                                  convertedWeight = convertKgToLbs(spot.y);
                                } else if (selectedUnit == Info.Kilogram &&
                                    dynoDataProvider.weightUnit ==
                                        Info.Pounds) {
                                  convertedWeight = convertLbsToKg(spot.y);
                                }
                                return FlSpot(spot.x, convertedWeight);
                              }).toList();
                              return WeightGraph(
                                graphData: graphData,
                                weightUnit: selectedUnit,
                              );
                            },
                          )
                        : _buildHangboardPlaceholder(isDarkMode))
                    : _buildConfigurationSection(isDarkMode),
              ),
            ),

            // Control buttons section - compact
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[850] : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDarkMode
                        ? Colors.black26
                        : Colors.grey.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: _buildControlButtons(context, isDarkMode),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntegratedStatusBar(BuildContext context, bool isDarkMode) {
    return Consumer<DynoDataProvider>(
      builder: (context, dynoDataProvider, child) {
        int lastDataReceivedTime = dynoDataProvider.lastDataReceivedTime;
        bool isDeviceConnected =
            DateTime.now().millisecondsSinceEpoch - lastDataReceivedTime <
                100000;
        bool isRecording = dynoDataProvider.recordData;

        return Row(
          children: [
            // Device connection status
            Expanded(
              child: _buildCompactStatusCard(
                context,
                isDeviceConnected
                    ? Icons.bluetooth_connected
                    : Icons.bluetooth_disabled,
                isDeviceConnected ? 'Connected' : 'Disconnected',
                isDeviceConnected ? Colors.green : Colors.red,
                isDarkMode,
                isActive: isDeviceConnected,
              ),
            ),
            SizedBox(width: 12),

            // Recording/Circuit status
            Expanded(
              child: _buildCompactStatusCard(
                context,
                isRunning
                    ? (isPullPhase
                        ? Icons.fitness_center
                        : Icons.pause_circle_outline)
                    : Icons.timer_outlined,
                isRunning ? (isPullPhase ? 'Pulling' : 'Resting') : 'Ready',
                isRunning
                    ? (isPullPhase ? Colors.blue : Colors.orange)
                    : Colors.grey,
                isDarkMode,
                isActive: isRunning,
                showPulse: isRunning && isPullPhase,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCompactStatusCard(
    BuildContext context,
    IconData icon,
    String title,
    Color color,
    bool isDarkMode, {
    bool isActive = false,
    bool showPulse = false,
  }) {
    final cardColor = isDarkMode ? Colors.grey[850] : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.grey[800];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isActive ? color.withOpacity(0.3) : Colors.grey.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainMetrics(
      BuildContext context, bool isDarkMode, String selectedUnit) {
    return Consumer<DynoDataProvider>(
      builder: (context, dynoDataProvider, child) {
        double? weight = dynoDataProvider.weight;

        // Convert weight to selected unit if necessary
        if (selectedUnit == Info.Pounds &&
            dynoDataProvider.weightUnit == Info.Kilogram) {
          weight = weight != null ? convertKgToLbs(weight) : null;
        } else if (selectedUnit == Info.Kilogram &&
            dynoDataProvider.weightUnit == Info.Pounds) {
          weight = weight != null ? convertLbsToKg(weight) : null;
        }

        double? maxWeight = maxWeights.isNotEmpty
            ? maxWeights.reduce((a, b) => a > b ? a : b)
            : 0.0;
        if (selectedUnit == Info.Pounds) {
          maxWeight = maxWeight != null ? convertKgToLbs(maxWeight) : null;
        }

        return Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                context,
                'Current Pull',
                '${weight?.toStringAsFixed(1) ?? '0.0'}',
                selectedUnit,
                Icons.trending_up,
                Colors.blue,
                isDarkMode,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                context,
                'Circuit Max',
                '${maxWeight?.toStringAsFixed(1) ?? '0.0'}',
                selectedUnit,
                Icons.emoji_events,
                Colors.orange,
                isDarkMode,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                context,
                isCountdown
                    ? 'Starting In'
                    : (sessionType == CircuitSessionType.pull
                        ? (isPullPhase ? 'Pull Time' : 'Rest Time')
                        : (isPullPhase ? 'Hold Time' : 'Rest Time')),
                isCountdown ? '$countdownTime' : '$currentTime',
                's',
                isPullPhase ? Icons.fitness_center : Icons.pause,
                isPullPhase ? Colors.blue : Colors.orange,
                isDarkMode,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildConfigurationMetrics(BuildContext context, bool isDarkMode) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            context,
            sessionType == CircuitSessionType.pull
                ? 'Pull Duration'
                : 'Hold Duration',
            '$pullDuration',
            's',
            Icons.fitness_center,
            Colors.blue,
            isDarkMode,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            context,
            'Rest Duration',
            '$restDuration',
            's',
            Icons.pause,
            Colors.orange,
            isDarkMode,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            context,
            'Circuits',
            '$numCircuits',
            '',
            Icons.repeat,
            Colors.green,
            isDarkMode,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String title,
    String value,
    String unit,
    IconData icon,
    Color color,
    bool isDarkMode,
  ) {
    final cardColor = isDarkMode ? Colors.grey[850] : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.grey[800];
    final subtitleColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode ? Colors.black26 : Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: subtitleColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    height: 1.0,
                  ),
                ),
                if (unit.isNotEmpty) ...[
                  SizedBox(width: 3),
                  Text(
                    unit,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: subtitleColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigurationSection(bool isDarkMode) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Compact header
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.timer,
                size: 28,
                color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
              ),
              SizedBox(width: 8),
              Text(
                'Circuit Setup',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          // Session type selector
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ChoiceChip(
                label: Text('Pull'),
                selected: sessionType == CircuitSessionType.pull,
                onSelected: (selected) {
                  if (selected)
                    setState(() => sessionType = CircuitSessionType.pull);
                },
              ),
              SizedBox(width: 8),
              ChoiceChip(
                label: Text('Hangboard'),
                selected: sessionType == CircuitSessionType.hangboard,
                onSelected: (selected) {
                  if (selected)
                    setState(() => sessionType = CircuitSessionType.hangboard);
                },
              ),
            ],
          ),

          SizedBox(height: 16),

          // Compact configuration grid
          _buildCompactConfigInput(
            sessionType == CircuitSessionType.pull
                ? 'Pull Duration'
                : 'Hold Duration',
            '$pullDuration s',
            pullDuration,
            (value) => setState(() => pullDuration = value),
            isDarkMode,
            Icons.fitness_center,
            Colors.blue,
          ),
          SizedBox(height: 12),
          _buildCompactConfigInput(
            'Rest Duration',
            '$restDuration s',
            restDuration,
            (value) => setState(() => restDuration = value),
            isDarkMode,
            Icons.pause,
            Colors.orange,
          ),
          SizedBox(height: 12),
          _buildCompactConfigSlider(
            'Circuits',
            '$numCircuits',
            numCircuits,
            1,
            20,
            (value) => setState(() => numCircuits = value.round()),
            isDarkMode,
            Icons.repeat,
            Colors.green,
          ),

          if (sessionType == CircuitSessionType.hangboard) ...[
            SizedBox(height: 12),
            _buildCompactConfigInput(
              'Edge Size',
              '$pullEdge mm',
              pullEdge,
              (value) => setState(() => pullEdge = value),
              isDarkMode,
              Icons.crop_square,
              Colors.purple,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompactConfigInput(
    String title,
    String subtitle,
    int value,
    Function(int) onChanged,
    bool isDarkMode,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : Colors.grey[800],
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
                onPressed: () {
                  if (value > 1) {
                    onChanged(value - 1);
                  }
                },
                icon: Icon(Icons.remove_circle_outline, size: 20),
                color: color,
              ),
              Container(
                width: 50,
                padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[700] : Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: color.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  value.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.grey[800],
                  ),
                ),
              ),
              IconButton(
                constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
                onPressed: () {
                  if (value < 300) {
                    onChanged(value + 1);
                  }
                },
                icon: Icon(Icons.add_circle_outline, size: 20),
                color: color,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfigInput(
    String title,
    String subtitle,
    int value,
    Function(int) onChanged,
    bool isDarkMode,
    IconData icon,
    Color color,
  ) {
    return StatefulBuilder(
      builder: (context, setLocalState) {
        final TextEditingController controller =
            TextEditingController(text: value.toString());

        return Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.white : Colors.grey[800],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      if (value > 1) {
                        final newValue = value - 1;
                        onChanged(newValue);
                        controller.text = newValue.toString();
                      }
                    },
                    icon: Icon(Icons.remove_circle_outline),
                    color: color,
                  ),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey[700] : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: color.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: controller,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.grey[800],
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                        ),
                        onChanged: (text) {
                          final newValue = int.tryParse(text);
                          if (newValue != null &&
                              newValue > 0 &&
                              newValue <= 300) {
                            onChanged(newValue);
                          }
                        },
                        onSubmitted: (text) {
                          final newValue = int.tryParse(text);
                          if (newValue != null &&
                              newValue > 0 &&
                              newValue <= 300) {
                            onChanged(newValue);
                          } else {
                            controller.text = value.toString();
                          }
                        },
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      if (value < 300) {
                        final newValue = value + 1;
                        onChanged(newValue);
                        controller.text = newValue.toString();
                      }
                    },
                    icon: Icon(Icons.add_circle_outline),
                    color: color,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompactConfigSlider(
    String title,
    String subtitle,
    int value,
    int min,
    int max,
    Function(double) onChanged,
    bool isDarkMode,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.white : Colors.grey[800],
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: color.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  value.toString(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: color,
              inactiveTrackColor: color.withOpacity(0.3),
              thumbColor: color,
              overlayColor: color.withOpacity(0.2),
              trackHeight: 4.0,
            ),
            child: Slider(
              value: value.toDouble(),
              min: min.toDouble(),
              max: max.toDouble(),
              divisions: max - min,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigSlider(
    String title,
    String subtitle,
    int value,
    int min,
    int max,
    Function(double) onChanged,
    bool isDarkMode,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: color,
              inactiveTrackColor: color.withOpacity(0.3),
              thumbColor: color,
              overlayColor: color.withOpacity(0.2),
            ),
            child: Slider(
              value: value.toDouble(),
              min: min.toDouble(),
              max: max.toDouble(),
              divisions: max - min,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons(BuildContext context, bool isDarkMode) {
    if (!isRunning) {
      return Row(
        children: [
          Expanded(
            child: _buildActionButton(
              'Start Circuit',
              Icons.play_arrow,
              Colors.green,
              startCircuit,
              isDarkMode,
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            'Stop',
            Icons.stop,
            Colors.red,
            stopCircuit,
            isDarkMode,
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _buildActionButton(
            'Reset',
            Icons.refresh,
            Colors.orange,
            resetCircuit,
            isDarkMode,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color,
      VoidCallback onPressed, bool isDarkMode) {
    return Container(
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.symmetric(vertical: 8),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18),
              SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Utility functions for weight conversion
  double convertKgToLbs(double kg) {
    return kg * 2.20462;
  }

  double convertLbsToKg(double lbs) {
    return lbs / 2.20462;
  }

  Widget _buildHangboardPlaceholder(bool isDarkMode) {
    return Center(
      child: Text(
        'Hangboard mode not supported in this view',
        style: TextStyle(
          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
        ),
      ),
    );
  }
}

// Data class to store circuit session information
class CircuitData {
  final int circuitNumber;
  final double maxWeight;
  final List<FlSpot> graphData;
  final int duration;

  CircuitData({
    required this.circuitNumber,
    required this.maxWeight,
    required this.graphData,
    required this.duration,
  });
}
