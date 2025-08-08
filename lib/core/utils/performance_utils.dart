import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class PerformanceUtils {
  static final Map<String, Stopwatch> _timers = {};
  static final Queue<double> _frameTimes = Queue<double>();
  static int _frameCount = 0;
  static double _averageFrameTime = 0.0;
  
  // Performance monitoring
  static void startTimer(String name) {
    _timers[name] ??= Stopwatch();
    _timers[name]!.start();
  }
  
  static double stopTimer(String name) {
    final timer = _timers[name];
    if (timer == null || !timer.isRunning) return 0.0;
    
    timer.stop();
    final elapsed = timer.elapsedMicroseconds / 1000.0; // Convert to milliseconds
    timer.reset();
    
    if (AppConstants.enableDebugLogging) {
      debugPrint('⏱️ $name: ${elapsed.toStringAsFixed(2)}ms');
    }
    
    return elapsed;
  }
  
  // Frame rate monitoring
  static void recordFrameTime(double deltaTime) {
    _frameCount++;
    _frameTimes.add(deltaTime * 1000); // Convert to milliseconds
    
    // Keep only last 60 frames for rolling average
    if (_frameTimes.length > 60) {
      _frameTimes.removeFirst();
    }
    
    // Calculate average frame time
    _averageFrameTime = _frameTimes.reduce((a, b) => a + b) / _frameTimes.length;
    
    // Log performance warnings
    if (deltaTime > AppConstants.frameTimeThreshold && AppConstants.enableDebugLogging) {
      debugPrint('⚠️ Frame time spike: ${(deltaTime * 1000).toStringAsFixed(2)}ms');
    }
  }
  
  static double get averageFrameTime => _averageFrameTime;
  static double get currentFPS => _averageFrameTime > 0 ? 1000 / _averageFrameTime : 0;
  static int get frameCount => _frameCount;
  
  // Memory monitoring
  static void logMemoryUsage(String context) {
    if (!AppConstants.enableDebugLogging) return;
    
    // Note: Actual memory monitoring would require platform-specific implementations
    debugPrint('📊 Memory check: $context (frame $_frameCount)');
  }
  
  // Object pooling helper
  static final Map<Type, Queue<Object>> _objectPools = {};
  
  static T getFromPool<T>(Type type, T Function() factory) {
    _objectPools[type] ??= Queue<Object>();
    final pool = _objectPools[type]!;
    
    if (pool.isNotEmpty) {
      return pool.removeFirst() as T;
    }
    
    return factory();
  }
  
  static void returnToPool<T>(Type type, T object) {
    _objectPools[type] ??= Queue<Object>();
    final pool = _objectPools[type]!;
    
    // Limit pool size to prevent memory leaks
    if (pool.length < AppConstants.objectPoolSize) {
      pool.add(object as Object);
    }
  }
  
  // Component optimization
  static void optimizeComponent(Component component) {
    // Disable debugging for performance
    if (kReleaseMode) {
      component.debugMode = false;
    }
  }
  
  // Batch operations for better performance
  static void batchAddComponents(HasChildren parent, List<Component> components) {
    startTimer('batch_add_components');
    
    for (final component in components) {
      optimizeComponent(component);
      parent.add(component);
    }
    
    stopTimer('batch_add_components');
  }
  
  static void batchRemoveComponents(HasChildren parent, List<Component> components) {
    startTimer('batch_remove_components');
    
    for (final component in components) {
      parent.remove(component);
    }
    
    stopTimer('batch_remove_components');
  }
  
  // Throttling utility
  static final Map<String, DateTime> _lastExecution = {};
  
  static bool shouldExecute(String key, Duration interval) {
    final now = DateTime.now();
    final lastTime = _lastExecution[key];
    
    if (lastTime == null || now.difference(lastTime) >= interval) {
      _lastExecution[key] = now;
      return true;
    }
    
    return false;
  }
  
  // Performance report
  static Map<String, dynamic> getPerformanceReport() {
    return {
      'frameCount': _frameCount,
      'averageFrameTime': _averageFrameTime,
      'currentFPS': currentFPS,
      'activeTimers': _timers.keys.toList(),
      'pooledTypes': _objectPools.keys.map((e) => e.toString()).toList(),
      'poolSizes': _objectPools.map((k, v) => MapEntry(k.toString(), v.length)),
    };
  }
  
  // Cleanup
  static void cleanup() {
    _timers.clear();
    _frameTimes.clear();
    _objectPools.clear();
    _lastExecution.clear();
    _frameCount = 0;
    _averageFrameTime = 0.0;
    
    if (AppConstants.enableDebugLogging) {
      debugPrint('🧹 Performance utils cleaned up');
    }
  }
  
  // Debug overlay data
  static Map<String, String> getDebugInfo() {
    if (!kDebugMode) return {};
    
    return {
      'FPS': currentFPS.toStringAsFixed(1),
      'Frame Time': '${_averageFrameTime.toStringAsFixed(1)}ms',
      'Frame Count': _frameCount.toString(),
      'Active Timers': _timers.length.toString(),
      'Pool Count': _objectPools.length.toString(),
    };
  }
}

// Performance-optimized widget builder
class PerformantBuilder extends StatelessWidget {
  final Widget Function(BuildContext context) builder;
  final String? debugLabel;
  
  const PerformantBuilder({
    super.key,
    required this.builder,
    this.debugLabel,
  });
  
  @override
  Widget build(BuildContext context) {
    if (AppConstants.enableDebugLogging && debugLabel != null) {
      PerformanceUtils.startTimer('widget_build_$debugLabel');
    }
    
    final widget = builder(context);
    
    if (AppConstants.enableDebugLogging && debugLabel != null) {
      PerformanceUtils.stopTimer('widget_build_$debugLabel');
    }
    
    return widget;
  }
}