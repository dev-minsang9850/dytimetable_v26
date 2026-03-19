// lib/core/app.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/home/home_screen.dart';
import '../features/setup/setup_screen.dart';

class TimetableWearApp extends StatelessWidget {
  const TimetableWearApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '학교 시간표',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.dark(
          primary: Colors.blueAccent,
          secondary: Colors.blueAccent,
        ),
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontSize: 12),
          bodyLarge: TextStyle(fontSize: 14),
        ),
      ),
      home: const RootScreen(),
    );
  }
}

/// 설정 여부에 따라 SetupScreen 또는 HomeScreen으로 분기
class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  bool _loading = true;
  bool _hasSetup = false;

  @override
  void initState() {
    super.initState();
    _checkSetup();
  }

  Future<void> _checkSetup() async {
    final prefs = await SharedPreferences.getInstance();
    final schoolCode = prefs.getString('schoolCode');
    final atptCode = prefs.getString('atptCode');
    final grade = prefs.getString('grade');
    final classNm = prefs.getString('classNm');

    setState(() {
      _hasSetup = schoolCode != null &&
          atptCode != null &&
          grade != null &&
          classNm != null;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_hasSetup) {
      return const HomeScreen();
    } else {
      return const SetupScreen();
    }
  }
}
