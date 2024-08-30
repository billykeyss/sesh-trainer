import 'package:ble_scale_app/providers/dyno_data_provider.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'screens/home_screen.dart';
import 'package:provider/provider.dart';
import 'providers/leaderboard_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'providers/theme_provider.dart'; // Import the ThemeProvider

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Check the platform before setting orientations
  if (Platform.isIOS) {
    // Set orientation preferences without using context
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => LeaderboardProvider()),
        ChangeNotifierProvider(create: (context) => DynoDataProvider()),
        ChangeNotifierProvider(create: (context) => ThemeProvider()), // Add ThemeProvider
      ],
      child: MyApp(),
    ),
  );
}

Future<void> deleteExistingDatabases() async {
  final dbFolder = await getApplicationDocumentsDirectory();
  final directory = Directory(dbFolder.path);
  final files = directory.listSync();

  for (final file in files) {
    if (file is File && file.path.endsWith('.sqlite')) {
      await file.delete();
      print('Deleted database: ${file.path}');
    }
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Use MediaQuery to determine if the device is an iPad
    final isIpad = _isRunningOnIpad(context);

    // Allow landscape mode if it's an iPad
    if (Platform.isIOS && isIpad) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Scale App',
          theme: ThemeData.light(), // Define light theme
          darkTheme: ThemeData.dark(), // Define dark theme
          themeMode: themeProvider.themeMode, // Apply current theme mode
          home: ScaleHomePage(),
        );
      },
    );
  }
}

bool _isRunningOnIpad(BuildContext context) {
  // Use MediaQueryData to determine the device size
  final mediaQuery = MediaQuery.of(context);
  return mediaQuery.size.shortestSide >= 600;
}
