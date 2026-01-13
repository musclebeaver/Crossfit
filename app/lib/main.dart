import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'ui/styles/app_colors.dart';
import 'ui/screens/login_screen.dart';

void main() {
  runApp(const CrossfitApp());
}

class CrossfitApp extends StatelessWidget {
  const CrossfitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crossfit Platform',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          background: AppColors.background,
          surface: AppColors.surface,
          primary: AppColors.primary,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(color: AppColors.textPrimary),
          bodyLarge: TextStyle(color: AppColors.textPrimary),
          bodyMedium: TextStyle(color: AppColors.textSecondary),
        ),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}
