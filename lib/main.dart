// main.dart
// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'thumbnails_page.dart';
import 'config.dart'; // Import your config file
import 'package:dart_openai/dart_openai.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  OpenAI.apiKey = Config.openAIKey; // Set the OpenAI API key
  runApp(const MyApp());
  print('DEBUG: app starts');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Screenshot Reader',
      home: const ThumbnailsPage(),
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
    );
  }
}
