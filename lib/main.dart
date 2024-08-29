import 'package:ble_scale_app/providers/dyno_data_provider.dart';
import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'package:provider/provider.dart';
import 'providers/leaderboard_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:path/path.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await deleteExistingDatabases();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => LeaderboardProvider()),
        ChangeNotifierProvider(create: (context) => DynoDataProvider()),
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
    return MaterialApp(
      title: 'Scale App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ScaleHomePage(),
    );
  }
}