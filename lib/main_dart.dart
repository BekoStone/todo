import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:puzzle_box/app_dart.dart';
import 'injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize dependency injection first
    await di.init();
    
    // Validate critical dependencies
    if (!di.validateDependencies()) {
      throw Exception('Critical dependencies missing');
    }
    
    // Set preferred orientations for optimal game experience
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
    // Configure system UI for immersive experience
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF000000),
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    );
    
    // Enable edge-to-edge
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: [SystemUiOverlay.top],
    );
    
    // Run the app
    runApp(const BoxHooksApp());
    
  } catch (error, stackTrace) {
    // Critical error - show error screen with recovery options
    runApp(_buildErrorApp(error, stackTrace));
  }
}

/// Build error recovery app when critical initialization fails
Widget _buildErrorApp(dynamic error, StackTrace stackTrace) {
  return MaterialApp(
    title: 'Box Hooks - Error',
    home: Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFFF6B6B),
                size: 80,
              ),
              const SizedBox(height: 24),
              const Text(
                'App Initialization Failed',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'We encountered a problem starting Box Hooks.',
                style: TextStyle(
                  color: Color(0xFFB0B0B0),
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (error.toString().length < 100)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A3E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF3A3A4E),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    error.toString(),
                    style: const TextStyle(
                      color: Color(0xFFE0E0E0),
                      fontSize: 14,
                      fontFamily: 'monospace',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4ECDC4),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    // Restart the app
                    SystemChannels.platform.invokeMethod('SystemNavigator.pop');
                  },
                  child: const Text(
                    'Restart App',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  // Copy error to clipboard
                  Clipboard.setData(ClipboardData(
                    text: 'Box Hooks Error:\n$error\n\nStack Trace:\n$stackTrace',
                  ));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Error details copied to clipboard'),
                      backgroundColor: Color(0xFF4ECDC4),
                    ),
                  );
                },
                child: const Text(
                  'Copy Error Details',
                  style: TextStyle(
                    color: Color(0xFF4ECDC4),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}