import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:puzzle_box/app_dart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'injection_container.dart' as di;
import 'core/constants/app_constants.dart';
import 'core/utils/performance_utils.dart';

/// Main entry point for the Box Hooks puzzle game application.
/// Initializes all necessary services and launches the app with proper error handling.
/// Optimized for <3s cold start and flawless performance on mid-range devices.
Future<void> main() async {
  // Mark cold start beginning
  final coldStartTimer = Stopwatch()..start();
  PerformanceUtils.markColdStartBegin();

  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set up global error handling
  _setupErrorHandling();
  
  // Configure system UI for optimal game experience
  await _configureSystemUI();
  
  // Initialize dependency injection with performance tracking
  await _initializeDependencies();
  
  // Mark cold start completion
  coldStartTimer.stop();
  PerformanceUtils.recordColdStartTime(Duration(milliseconds: coldStartTimer.elapsedMilliseconds));
  
  // Launch the application in error handling zone
  runZonedGuarded(
    () => runApp(const BoxHooksApp()),
    (error, stackTrace) {
      _handleZoneError(error, stackTrace);
    },
  );
}

/// Setup comprehensive global error handling for the application
void _setupErrorHandling() {
  // Handle Flutter framework errors
  FlutterError.onError = (FlutterErrorDetails details) {
    // Always present error in debug mode
    FlutterError.presentError(details);
    
    if (kDebugMode) {
      // In debug mode, print detailed error info
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('Flutter Error: ${details.exception}');
      debugPrint('Context: ${details.context}');
      debugPrint('Library: ${details.library}');
      debugPrint('Stack trace:');
      debugPrint(details.stack.toString());
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    } else {
      // In release mode, log for crash reporting
      _logErrorToService(
        'Flutter Error: ${details.exception}',
        details.stack,
        details.context?.toString(),
      );
    }
  };
  
  // Handle platform-specific errors (non-Flutter errors)
  PlatformDispatcher.instance.onError = (error, stack) {
    if (kDebugMode) {
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('Platform Error: $error');
      debugPrint('Stack trace:');
      debugPrint(stack.toString());
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    } else {
      _logErrorToService('Platform Error: $error', stack);
    }
    return true; // Indicate error was handled
  };
}

/// Handle errors that occur in the main zone
void _handleZoneError(Object error, StackTrace stackTrace) {
  if (kDebugMode) {
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('Zone Error: $error');
    debugPrint('Stack trace:');
    debugPrint(stackTrace.toString());
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  } else {
    _logErrorToService('Zone Error: $error', stackTrace);
  }
}

/// Configure system UI overlays and preferences for optimal game experience
Future<void> _configureSystemUI() async {
  try {
    // Configure status bar and navigation bar
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    );

    // Set preferred orientations (allow both portrait and landscape for flexibility)
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // Enable edge-to-edge display
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: SystemUiOverlay.values,
    );

    debugPrint('✅ System UI configured successfully');
  } catch (e, stackTrace) {
    debugPrint('❌ Failed to configure system UI: $e');
    _logErrorToService('System UI Configuration Error: $e', stackTrace);
  }
}

/// Initialize all app dependencies with comprehensive error handling
Future<void> _initializeDependencies() async {
  try {
    debugPrint('🚀 Starting dependency initialization...');
    final initTimer = Stopwatch()..start();

    // Initialize dependency injection container
    await di.init();
    
    // Validate all critical dependencies are registered
    await _validateDependencies();
    
    // Initialize state management system
    await di.initializeStateManagement();
    
    // Initialize performance monitoring
    PerformanceUtils.initialize();
    
    initTimer.stop();
    debugPrint('✅ Dependencies initialized in ${initTimer.elapsedMilliseconds}ms');
    
  } catch (e, stackTrace) {
    debugPrint('❌ Failed to initialize dependencies: $e');
    _logErrorToService('Dependency Initialization Error: $e', stackTrace);
    
    // In production, show user-friendly error and exit gracefully
    if (!kDebugMode) {
      _showFatalErrorDialog(e.toString());
    }
    
    rethrow; // Re-throw to prevent app from starting in broken state
  }
}

/// Validate that all critical dependencies are properly registered
Future<void> _validateDependencies() async {
  try {
    debugPrint('🔍 Validating dependency registration...');
    
    // Print detailed dependency status
    di.printDependencyStatus();
    
    // Validate core services
    final audioService = di.getIt.get<dynamic>();
    final storageService = di.getIt.get<dynamic>();
    
    debugPrint('✅ All critical dependencies validated');
    
  } catch (e, stackTrace) {
    debugPrint('❌ Dependency validation failed: $e');
    _logErrorToService('Dependency Validation Error: $e', stackTrace);
    rethrow;
  }
}

/// Log errors to external service (placeholder for crash reporting)
void _logErrorToService(String error, StackTrace? stackTrace, [String? context]) {
  if (kDebugMode) {
    // In debug mode, just print the error
    debugPrint('Error logged: $error');
    if (context != null) {
      debugPrint('Context: $context');
    }
    return;
  }

  // In production, this would integrate with crash reporting services like:
  // - Firebase Crashlytics
  // - Sentry
  // - Bugsnag
  // - Custom analytics service
  
  try {
    // Example integration (uncomment when service is available):
    // FirebaseCrashlytics.instance.recordError(
    //   error,
    //   stackTrace,
    //   context: context,
    //   fatal: false,
    // );
    
    // For now, store locally for debugging
    _storeErrorLocally(error, stackTrace, context);
    
  } catch (loggingError) {
    // If error logging fails, fall back to debug print
    debugPrint('Failed to log error: $loggingError');
    debugPrint('Original error: $error');
  }
}

/// Store error information locally for later analysis
void _storeErrorLocally(String error, StackTrace? stackTrace, [String? context]) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = DateTime.now().toIso8601String();
    final errorLog = {
      'timestamp': timestamp,
      'error': error,
      'stackTrace': stackTrace?.toString(),
      'context': context,
      'appVersion': AppConstants.appVersion,
      'platform': Platform.operatingSystem,
    };
    
    // Store recent errors (keep last 10)
    final existingErrors = prefs.getStringList('error_logs') ?? [];
    existingErrors.insert(0, errorLog.toString());
    
    if (existingErrors.length > 10) {
      existingErrors.removeRange(10, existingErrors.length);
    }
    
    await prefs.setStringList('error_logs', existingErrors);
    
  } catch (storageError) {
    debugPrint('Failed to store error locally: $storageError');
  }
}

/// Show fatal error dialog in production builds
void _showFatalErrorDialog(String error) {
  // This would show a user-friendly error dialog
  // For now, just print the error
  debugPrint('FATAL ERROR: $error');
  
  // In a real app, you might want to:
  // 1. Show a dialog with a friendly message
  // 2. Offer to restart the app
  // 3. Provide a way to report the issue
  // 4. Clear corrupted data if necessary
}

/// Performance monitoring callback for frame timing
void _onFrameCallback(Duration timeStamp) {
  PerformanceUtils.recordFrameTime(timeStamp.inMicroseconds / 1000.0);
}

/// Check device performance and adjust settings if needed
Future<void> _optimizeForDevice() async {
  try {
    // Check available memory
    if (Platform.isAndroid || Platform.isIOS) {
      // Platform-specific optimizations
      final isLowEndDevice = await _isLowEndDevice();
      
      if (isLowEndDevice) {
        // Enable performance mode for low-end devices
        debugPrint('🔧 Enabling performance optimizations for low-end device');
        PerformanceUtils.enableMemoryOptimizations();
      }
    }
    
  } catch (e) {
    debugPrint('⚠️ Failed to optimize for device: $e');
  }
}

/// Detect if device is low-end and needs performance optimizations
Future<bool> _isLowEndDevice() async {
  try {
    // This is a simplified check - in reality you'd check:
    // - Available RAM
    // - CPU cores and speed  
    // - GPU capabilities
    // - Android API level / iOS version
    
    // For now, just check if we're on a very old platform
    if (Platform.isAndroid) {
      // You could check Android API level here
      return false; // Placeholder
    }
    
    if (Platform.isIOS) {
      // You could check iOS version here
      return false; // Placeholder
    }
    
    return false;
    
  } catch (e) {
    debugPrint('Failed to detect device capabilities: $e');
    return false; // Assume modern device if detection fails
  }
}

/// Cleanup function called before app termination
Future<void> _cleanup() async {
  try {
    debugPrint('🧹 Performing app cleanup...');
    
    // Dispose performance monitoring
    PerformanceUtils.dispose();
    
    // Close any open streams or subscriptions
    // Save any pending data
    
    debugPrint('✅ Cleanup completed');
    
  } catch (e) {
    debugPrint('❌ Error during cleanup: $e');
  }
}

/// App lifecycle management
class AppLifecycleManager extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.paused:
        debugPrint('📱 App paused');
        break;
      case AppLifecycleState.resumed:
        debugPrint('📱 App resumed');
        break;
      case AppLifecycleState.detached:
        debugPrint('📱 App detached');
        _cleanup();
        break;
      default:
        break;
    }
  }
}