import 'package:sesh_trainer/providers/dyno_data_provider.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'screens/home_screen.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force portrait orientation for all devices
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => DynoDataProvider()),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
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
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Training SESH',
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: themeProvider.themeMode,
          home: ScaleHomePage(),
        );
      },
    );
  }
}
