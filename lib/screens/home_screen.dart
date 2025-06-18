import 'dart:async';
import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:sesh_trainer/models/info.dart';
import 'package:sesh_trainer/providers/dyno_data_provider.dart';
import 'package:sesh_trainer/providers/theme_provider.dart';
import 'package:sesh_trainer/screens/calendar_view.dart';
import 'package:sesh_trainer/screens/insights_page.dart';
import 'package:sesh_trainer/screens/circuit_training_screen.dart';
import 'package:sesh_trainer/screens/insights_page_with_ai.dart';
import 'package:sesh_trainer/utils/number.dart';
import 'package:sesh_trainer/widgets/weight_graph.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  FlutterBlue flutterBlue = FlutterBlue.instance;
  BluetoothDevice? connectedDevice;
  String elapsedTime = '0:00';
  bool showTestButton = false;
  bool isPaused = false;

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);

  @override
  void initState() {
    super.initState();
    requestPermissions();
    Future.delayed(const Duration(seconds: 2), scanForDevices);

    // Set up auto-save notification callback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dynoDataProvider =
          Provider.of<DynoDataProvider>(context, listen: false);
      dynoDataProvider.onSessionAutoSaved = (String sessionName) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Session auto-saved: $sessionName'),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'View',
                textColor: Colors.white,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CalendarView(),
                    ),
                  );
                },
              ),
            ),
          );
        }
      };
    });
  }

  Future<void> requestPermissions() async {
    await Permission.bluetooth.request();
    await Permission.locationWhenInUse.request();
  }

  void scanForDevices() {
    Provider.of<DynoDataProvider>(context, listen: false).scanForDevices();
  }

  void resetData() {
    Provider.of<DynoDataProvider>(context, listen: false).resetData();
  }

  void stopData() {
    print("Stopping data");
    Provider.of<DynoDataProvider>(context, listen: false).stopData();
    setState(() => isPaused = false);
  }

  void startData() {
    print("Starting data");
    Provider.of<DynoDataProvider>(context, listen: false).startData();
    setState(() => isPaused = false);
  }

  void togglePause() {
    final provider = Provider.of<DynoDataProvider>(context, listen: false);
    if (isPaused) {
      provider.resumeData();
    } else {
      provider.pauseData();
    }
    setState(() => isPaused = !isPaused);
  }

  void _runTestSession() {
    final dynoDataProvider =
        Provider.of<DynoDataProvider>(context, listen: false);

    // Reset and start the session
    dynoDataProvider.resetData();
    dynoDataProvider.startData();

    // Simulate a realistic climbing pull session over 10 seconds
    Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (timer.tick <= 20) {
        // 20 ticks * 500ms = 10 seconds
        double timeInSeconds = timer.tick * 0.5;
        double randomWeight;

        // Simulate a realistic pull pattern
        if (timeInSeconds <= 2.0) {
          // Gradual increase phase (0-2 seconds)
          double baseWeight = 20 + (timeInSeconds / 2.0) * 60; // 20kg to 80kg
          randomWeight = baseWeight + (Random().nextDouble() - 0.5) * 10;
        } else if (timeInSeconds <= 6.0) {
          // Peak performance phase (2-6 seconds) - maintain high force
          double baseWeight =
              75 + (Random().nextDouble() - 0.5) * 25; // 62.5kg to 87.5kg
          randomWeight =
              baseWeight + sin(timeInSeconds * 2) * 15; // Add some variation
        } else if (timeInSeconds <= 8.0) {
          // Fatigue phase (6-8 seconds) - gradual decline
          double fatigueMultiplier = 1.0 - ((timeInSeconds - 6.0) / 2.0) * 0.3;
          double baseWeight = 70 * fatigueMultiplier;
          randomWeight = baseWeight + (Random().nextDouble() - 0.5) * 20;
        } else {
          // Final effort phase (8-10 seconds) - last push with more variation
          double baseWeight = 40 + (Random().nextDouble()) * 40; // 40kg to 80kg
          randomWeight = baseWeight + (Random().nextDouble() - 0.5) * 25;
        }

        // Ensure weight is never negative and add some noise
        randomWeight = (randomWeight + (Random().nextDouble() - 0.5) * 5)
            .clamp(0.0, 150.0);

        Info testInfo = Info(
          weight: randomWeight,
          unit: Info.WEIGHT_KGS,
          name: 'Test Session',
          device: null,
        );
        dynoDataProvider.updateGraphData(testInfo);

        print(
            'Test session - Time: ${timeInSeconds.toStringAsFixed(1)}s, Weight: ${randomWeight.toStringAsFixed(1)}kg');
      } else {
        // Stop the session after 10 seconds
        dynoDataProvider.stopData();
        timer.cancel();

        // Show completion message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test session completed and auto-saved!'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );

        print('Test session completed');
      }
    });
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
                Icons.fitness_center,
                color: Colors.blue,
                size: 20,
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Sesh Training',
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
      drawer:
          _buildModernDrawer(context, isDarkMode, selectedUnit, themeProvider),
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
                  _buildMainMetrics(context, isDarkMode, selectedUnit),
                ],
              ),
            ),

            // Graph section - takes remaining space
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
                child: Consumer<DynoDataProvider>(
                  builder: (context, dynoDataProvider, child) {
                    final graphData = dynoDataProvider.graphData.map((spot) {
                      double convertedWeight = spot.y;
                      if (selectedUnit == Info.Pounds &&
                          dynoDataProvider.weightUnit == Info.Kilogram) {
                        convertedWeight = convertKgToLbs(spot.y);
                      } else if (selectedUnit == Info.Kilogram &&
                          dynoDataProvider.weightUnit == Info.Pounds) {
                        convertedWeight = convertLbsToKg(spot.y);
                      }
                      return FlSpot(spot.x, convertedWeight);
                    }).toList();
                    return WeightGraph(
                      graphData: graphData,
                      weightUnit: selectedUnit,
                    );
                  },
                ),
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
              child: _buildImprovedControlButtons(context, isDarkMode),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernDrawer(BuildContext context, bool isDarkMode,
      String selectedUnit, ThemeProvider themeProvider) {
    return Drawer(
      backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
      child: Column(
        children: [
          // Modern drawer header
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue.shade600,
                  Colors.blue.shade800,
                  Colors.purple.shade700,
                ],
                stops: [0.0, 0.6, 1.0],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Container(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 20),
                height: 180,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // App icon with enhanced styling
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.fitness_center,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    SizedBox(height: 16),

                    // App title with enhanced styling
                    Text(
                      'Sesh Training',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.3),
                            offset: Offset(0, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 4),

                    // Subtitle with enhanced styling
                    Text(
                      'Strength Training Platform',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Navigation items
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildDrawerItem(
                  context,
                  Icons.calendar_today,
                  'Training Calendar',
                  'View sessions by date',
                  () => Navigator.push(context,
                      MaterialPageRoute(builder: (context) => CalendarView())),
                  isDarkMode,
                ),
                _buildDrawerItem(
                  context,
                  Icons.timer,
                  'Circuit Training',
                  'Interval training mode',
                  () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => CircuitTrainingScreen())),
                  isDarkMode,
                ),
                _buildDrawerItem(
                  context,
                  Icons.insights,
                  'Progress & Analytics',
                  'Track your improvement',
                  () => Navigator.push(context,
                      MaterialPageRoute(builder: (context) => InsightsPage())),
                  isDarkMode,
                ),
                _buildDrawerItem(
                  context,
                  Icons.insights,
                  'AI Insights',
                  'AI-powered insights',
                  () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => InsightsPageWithAI())),
                  isDarkMode,
                ),
                Divider(
                    color: isDarkMode ? Colors.grey[700] : Colors.grey[300]),

                // Settings section
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'SETTINGS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                _buildSettingItem(
                  context,
                  Icons.brightness_6,
                  'Dark Mode',
                  'Toggle theme',
                  GestureDetector(
                    onTap: () =>
                        themeProvider.toggleTheme(!themeProvider.isDarkMode),
                    child: Container(
                      width: 80,
                      height: 36,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: isDarkMode
                            ? Colors.blue.withOpacity(0.2)
                            : Colors.grey.withOpacity(0.2),
                      ),
                      child: Stack(
                        children: [
                          AnimatedPositioned(
                            duration: Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            left: themeProvider.isDarkMode ? 40 : 0,
                            child: Container(
                              width: 40,
                              height: 36,
                              child: Center(
                                child: Icon(
                                  themeProvider.isDarkMode
                                      ? Icons.dark_mode
                                      : Icons.light_mode,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: themeProvider.isDarkMode
                                    ? Colors.blue
                                    : Colors.grey[400],
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  isDarkMode,
                ),
                _buildSettingItem(
                  context,
                  Icons.swap_horiz,
                  'Weight Unit',
                  'Toggle between kg and lbs',
                  GestureDetector(
                    onTap: () => themeProvider
                        .toggleUnit(!(selectedUnit == Info.Pounds)),
                    child: Container(
                      width: 80,
                      height: 36,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: (selectedUnit == Info.Pounds)
                            ? Colors.blue.withOpacity(0.2)
                            : Colors.grey.withOpacity(0.2),
                      ),
                      child: Stack(
                        children: [
                          AnimatedPositioned(
                            duration: Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            left: (selectedUnit == Info.Pounds) ? 40 : 0,
                            child: Container(
                              width: 40,
                              height: 36,
                              child: Center(
                                child: Text(
                                  selectedUnit == Info.Pounds ? 'lbs' : 'kg',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: (selectedUnit == Info.Pounds)
                                    ? Colors.blue
                                    : Colors.grey[400],
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  isDarkMode,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, IconData icon, String title,
      String subtitle, VoidCallback onTap, bool isDarkMode) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.blue, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDarkMode ? Colors.white : Colors.grey[800],
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
        ),
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _buildSettingItem(BuildContext context, IconData icon, String title,
      String subtitle, Widget trailing, bool isDarkMode) {
    return ListTile(
      leading: Icon(icon,
          color: isDarkMode ? Colors.grey[400] : Colors.grey[600], size: 20),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: isDarkMode ? Colors.white : Colors.grey[800],
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
        ),
      ),
      trailing: trailing,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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

            // Recording status
            Expanded(
              child: _buildCompactStatusCard(
                context,
                isRecording
                    ? Icons.fiber_manual_record
                    : Icons.stop_circle_outlined,
                isRecording ? 'Recording' : 'Standby',
                isRecording ? Colors.blue : Colors.grey,
                isDarkMode,
                isActive: isRecording,
                showPulse: isRecording,
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
    return Consumer2<DynoDataProvider, ThemeProvider>(
      builder: (context, dynoDataProvider, themeProvider, child) {
        double? weight = dynoDataProvider.weight;
        final Map<String, double?> maxWeights = dynoDataProvider.maxWeights;
        final Stopwatch stopwatch = dynoDataProvider.stopwatch;

        // Convert weight to selected unit if necessary
        if (selectedUnit == Info.Pounds &&
            dynoDataProvider.weightUnit == Info.Kilogram) {
          weight = weight != null ? convertKgToLbs(weight) : null;
        } else if (selectedUnit == Info.Kilogram &&
            dynoDataProvider.weightUnit == Info.Pounds) {
          weight = weight != null ? convertLbsToKg(weight) : null;
        }

        double? maxWeight = maxWeights[dynoDataProvider.weightUnit];
        if (selectedUnit == Info.Pounds &&
            dynoDataProvider.weightUnit == Info.Kilogram) {
          maxWeight = maxWeight != null ? convertKgToLbs(maxWeight) : null;
        } else if (selectedUnit == Info.Kilogram &&
            dynoDataProvider.weightUnit == Info.Pounds) {
          maxWeight = maxWeight != null ? convertLbsToKg(maxWeight) : null;
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
                'Max Pull',
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
                'Session Time',
                formatElapsedTime(stopwatch.elapsed),
                '',
                Icons.timer,
                Colors.green,
                isDarkMode,
              ),
            ),
          ],
        );
      },
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

  Widget _buildImprovedControlButtons(BuildContext context, bool isDarkMode) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Primary actions row
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                isPaused ? 'Resume' : 'Start',
                isPaused ? Icons.play_arrow : Icons.play_arrow,
                Colors.green,
                isPaused ? togglePause : startData,
                isDarkMode,
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _buildActionButton(
                isPaused ? 'Pause' : 'Pause',
                isPaused ? Icons.pause : Icons.pause,
                Colors.blue,
                togglePause,
                isDarkMode,
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _buildActionButton(
                'Stop',
                Icons.stop,
                Colors.red,
                stopData,
                isDarkMode,
              ),
            ),
          ],
        ),
        if (showTestButton) ...[
          SizedBox(height: 8),
          // Test mode button - full width
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'Test Mode',
                  Icons.science,
                  Colors.purple,
                  _runTestSession,
                  isDarkMode,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color,
      VoidCallback onPressed, bool isDarkMode) {
    return Container(
      height: 56,
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
    );
  }

  // Utility functions for weight conversion
  double convertKgToLbs(double kg) {
    return kg * 2.20462;
  }

  double convertLbsToKg(double lbs) {
    return lbs / 2.20462;
  }
}
