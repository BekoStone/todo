import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'presentation/navigation/app_navigator.dart';

class PuzzleBoxApp extends StatelessWidget {
  const PuzzleBoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Puzzle Box',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      debugShowCheckedModeBanner: false,
      onGenerateRoute: AppNavigator.onGenerateRoute,
      initialRoute: AppNavigator.initialRoute,
    );
  }
}
