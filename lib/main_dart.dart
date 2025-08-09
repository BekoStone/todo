import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:puzzle_box/app_dart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'injection_container.dart' as di;

/// Main entry point for the Box Hooks puzzle game application.
/// Initializes all necessary services and launches the app with proper error handling.
Future<void> main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set up global error handling
  _setupErrorHandling();
  
  // Configure system UI
  await _configureSystemUI();
  
  // Initialize dependency injection
  await _initializeDependencies();
  
  // Launch the application
  runApp(const BoxHooksApp());
}

/// Setup global error handling for the application
void _setupErrorHandling() {
  // Handle Flutter framework errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    
    if (kDebugMode) {
      // In debug mode, print to console
      debugPrint('Flutter Error: ${details.exception}');
      debugPrint('Stack trace: ${details.stack}');
    } else {
      // In release mode, log for crash reporting
      _logErrorToService(details.exception.toString(), details.stack);
    }
  };
  
  // Handle platform-specific errors
  PlatformDispatcher.instance.onError = (error, stack) {
    if (kDebugMode) {
      debugPrint('Platform Error: $error');
      debugPrint('Stack trace: $stack');
    } else {
      _logErrorToService(error.toString(), stack);
    }
    return true;
  };
  
  // Setup zone error handling for async operations
  runZonedGuarded(
    () {
      // Application will run in this zone
    },
    (error, stack) {
      if (kDebugMode) {
        debugPrint('Async Error: $error');
        debugPrint('Stack trace: $stack');
      } else {
        _logErrorToService(error.toString(), stack);
      }
    },
  );
}

/// Configure system UI overlay and orientation
Future<void> _configureSystemUI() async {
  try {
    // Set preferred orientations (portrait only for mobile)
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
    // Configure system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFF0F0E23), // AppColors.darkBackground
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    );
    
    // Enable edge-to-edge display
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: [SystemUiOverlay.top],
    );
    
    debugPrint('✅ System UI configured');
    
  } catch (e) {
    debugPrint('❌ Failed to configure system UI: $e');
    // Don't throw - this is not critical for app functionality
  }
}

/// Initialize all dependency injection and core services
Future<void> _initializeDependencies() async {
  try {
    debugPrint('🚀 Initializing Box Hooks application...');
    
    // Step 1: Initialize SharedPreferences (required for storage)
    debugPrint('📱 Initializing SharedPreferences...');
    final sharedPreferences = await SharedPreferences.getInstance();
    
    // Step 2: Register all dependencies
    debugPrint('🔧 Registering dependencies...');
    await di.init(sharedPreferences);
    
    // Step 3: Initialize core services
    debugPrint('⚙️ Initializing core services...');
    await di.initializeServices();
    
    // Step 4: Initialize state management
    debugPrint('🎮 Initializing state management...');
    await di.initializeStateManagement();
    
    // Step 5: Validate all dependencies
    debugPrint('✅ Validating dependencies...');
    if (!di.validateDependencies()) {
      throw Exception('Dependency validation failed');
    }
    
    // Debug info (only in debug mode)
    if (kDebugMode) {
      di.debugPrintDependencies();
    }
    
    debugPrint('🎯 Application initialization completed successfully!');
    
  } catch (e, stackTrace) {
    debugPrint('❌ Failed to initialize dependencies: $e');
    debugPrint('Stack trace: $stackTrace');
    
    // Show error dialog and exit
    await _showInitializationError(e.toString());
    rethrow;
  }
}

/// Log errors to external service (for production builds)
void _logErrorToService(String error, StackTrace? stackTrace) {
  // TODO: Implement crash reporting service (Firebase Crashlytics, Sentry, etc.)
  // For now, just log to debug console
  if (kDebugMode) {
    debugPrint('Error logged: $error');
    if (stackTrace != null) {
      debugPrint('Stack trace: $stackTrace');
    }
  }
}

/// Show initialization error dialog and exit app
Future<void> _showInitializationError(String error) async {
  return runApp(
    MaterialApp(
      title: 'Box Hooks - Initialization Error',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: InitializationErrorScreen(error: error),
    ),
  );
}

/// Error screen shown when app fails to initialize
class InitializationErrorScreen extends StatelessWidget {
  final String error;

  const InitializationErrorScreen({
    super.key,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0E23), // AppColors.darkBackground
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Error icon
              const Icon(
                Icons.error_outline_rounded,
                size: 80,
                color: Color(0xFFE57373), // AppColors.error
              ),
              
              const SizedBox(height: 24),
              
              // Title
              const Text(
                'Initialization Failed',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              // Error message
              Text(
                'The application failed to start properly. Please try restarting the app.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 32),
              
              // Error details (debug mode only)
              if (kDebugMode) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFE57373).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Error Details (Debug Mode):',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE57373),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.7),
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
              ],
              
              // Restart button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Restart the app by exiting
                    SystemNavigator.pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4ECDC4), // AppColors.primary
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Exit App',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Contact support button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    // TODO: Implement contact support functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Support contact feature coming soon'),
                        backgroundColor: Color(0xFF45B7D1), // AppColors.info
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Contact Support',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Application metadata for debugging and analytics
class AppMetadata {
  static const String version = '1.0.0';
  static const int buildNumber = 1;
  static const String buildDate = '2024-01-01';
  static const String environment = kDebugMode ? 'debug' : 'release';
  
  /// Get runtime information
  static Map<String, dynamic> getRuntimeInfo() {
    return {
      'version': version,
      'buildNumber': buildNumber,
      'buildDate': buildDate,
      'environment': environment,
      'dartVersion': Platform.version,
      'isDebugMode': kDebugMode,
      'isProfileMode': kProfileMode,
      'isReleaseMode': kReleaseMode,
    };
  }
}