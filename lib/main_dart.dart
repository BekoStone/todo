import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:puzzle_box/app_dart.dart';
import 'package:puzzle_box/core/utils/responsive_utils.dart';
import 'injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize dependency injection FIRST
    await di.init();
    
    // Validate critical dependencies
    if (!di.validateDependencies()) {
      throw Exception('Critical dependencies missing');
    }
    
    // Set preferred orientations
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
    // Configure system UI
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.black12,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
    
    // Run the app
    runApp(const BoxHooksApp());
    
  } catch (e) {
    // Critical error - show error screen
    runApp(MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.red.shade900,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.white,
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                'Failed to Initialize App',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                e.toString(),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    ));
  }
}