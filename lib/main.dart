import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ui/home_screen.dart';
import 'ui/styles.dart';

void main() {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(
    const ProviderScope(
      child: BeyondPerformanceApp(),
    ),
  );
}

class BeyondPerformanceApp extends StatelessWidget {
  const BeyondPerformanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BeyondPerformance',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: LabColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: LabColors.primary,
          brightness: Brightness.dark,
          surface: LabColors.background,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      ),
      home: const HomeScreen(),
    );
  }
}
