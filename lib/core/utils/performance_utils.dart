import 'dart:async';
import 'dart:collection';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../constants/app_constants.dart';

/// Performance monitoring and optimization utilities.
/// Provides frame rate monitoring, memory tracking, and performance optimizations.
/// Essential for maintaining 60 FPS on mid-range devices with <3s cold start.
class PerformanceUtils {
  // Private constructor
  PerformanceUtils._();

  // Performance monitoring state
  static bool _isMonitoring = false;
  static Timer? _monitoringTimer;
  static final List<Duration> _frameTimes = [];
  static final Queue<double> _fpsHistory = Queue<double>();
  static DateTime? _appStartTime;
  static DateTime? _coldStartComplete;

  // Memory tracking
  static int _peakMemoryUsage = 0;
  static int _currentMemoryUsage = 0;
  static final Map<String, int> _memorySnapshots = {};

  // Performance metrics
  static double _averageFPS = 60.0;
  static double _worstFrameTime = 0.0;
  static int _droppedFrames = 0;
  static int _totalFrames = 0;

  // Object pools for memory optimization
  static final Map<Type, Queue<Object>> _objectPools = {};
  static final Set<String> _activeAssets = {};

  // Performance settings
  static bool _enableAdvancedOptimizations = false;
  static bool _enableMemoryOptimizations = true;
  static bool _enableFrameRateMonitoring = kDebugMode;

  // ========================================
  // INITIALIZATION
  // ========================================

  /// Initialize performance monitoring
  static void initialize() {
    if (_isMonitoring) return;

    _appStartTime = DateTime.now();
    developer.log('Performance monitoring initialized', name: 'Performance');

    _setupFrameRateMonitoring();
    _setupMemoryMonitoring();
    _initializeObjectPools();

    _isMonitoring = true;
  }

  /// Mark cold start as complete
  static void markColdStartComplete() {
    if (_coldStartComplete == null && _appStartTime != null) {
      _coldStartComplete = DateTime.now();
      final coldStartTime = _coldStartComplete!.difference(_appStartTime!);
      
      developer.log(
        'Cold start completed in ${coldStartTime.inMilliseconds}ms',
        name: 'Performance',
      );

      // Validate cold start performance
      if (coldStartTime.inMilliseconds > AppConstants.maxColdStartMs) {
        developer.log(
          'WARNING: Cold start exceeded target (${AppConstants.maxColdStartMs}ms)',
          name: 'Performance',
        );
      }
    }
  }

  /// Dispose performance monitoring
  static void dispose() {
    _monitoringTimer?.cancel();
    _frameTimes.clear();
    _fpsHistory.clear();
    _clearObjectPools();
    _isMonitoring = false;
    
    developer.log('Performance monitoring disposed', name: 'Performance');
  }

  // ========================================
  // FRAME RATE MONITORING
  // ========================================

  /// Setup frame rate monitoring
  static void _setupFrameRateMonitoring() {
    if (!_enableFrameRateMonitoring) return;

    SchedulerBinding.instance.addPersistentFrameCallback((timeStamp) {
      _recordFrameTime(timeStamp);
    });

    // Start periodic FPS calculation
    _monitoringTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _calculateFPS();
      _checkPerformanceThresholds();
    });
  }

  /// Record frame time for analysis
  static void _recordFrameTime(Duration timeStamp) {
    if (_frameTimes.isNotEmpty) {
      final frameTime = timeStamp - _frameTimes.last;
      final frameTimeMs = frameTime.inMicroseconds / 1000.0;

      // Track worst frame time
      if (frameTimeMs > _worstFrameTime) {
        _worstFrameTime = frameTimeMs;
      }

      // Count dropped frames (>16.67ms for 60 FPS)
      if (frameTimeMs > 16.67) {
        _droppedFrames++;
      }

      _totalFrames++;

      // Keep only recent frame times (last 60 frames)
      if (_frameTimes.length >= 60) {
        _frameTimes.removeAt(0);
      }
    }

    _frameTimes.add(timeStamp);
  }

  /// Calculate current FPS
  static void _calculateFPS() {
    if (_frameTimes.length < 2) return;

    final totalTime = _frameTimes.last - _frameTimes.first;
    final frameCount = _frameTimes.length - 1;
    final fps = frameCount / (totalTime.inMicroseconds / 1000000.0);

    _averageFPS = fps;
    _fpsHistory.add(fps);

    // Keep only last 60 seconds of FPS data
    if (_fpsHistory.length > 60) {
      _fpsHistory.removeFirst();
    }
  }

  /// Check performance thresholds and log warnings
  static void _checkPerformanceThresholds() {
    // Check FPS threshold
    if (_averageFPS < AppConstants.minTargetFPS) {
      developer.log(
        'WARNING: FPS below target (${_averageFPS.toStringAsFixed(1)} < ${AppConstants.minTargetFPS})',
        name: 'Performance',
      );
      _suggestOptimizations();
    }

    // Check memory usage
    if (_currentMemoryUsage > AppConstants.maxMemoryUsageMB * 1024 * 1024) {
      developer.log(
        'WARNING: Memory usage high (${(_currentMemoryUsage / 1024 / 1024).toStringAsFixed(1)}MB)',
        name: 'Performance',
      );
      _triggerMemoryOptimization();
    }
  }

  // ========================================
  // MEMORY MONITORING
  // ========================================

  /// Setup memory monitoring
  static void _setupMemoryMonitoring() {
    Timer.periodic(const Duration(seconds: 5), (_) {
      _updateMemoryUsage();
    });
  }

  /// Update current memory usage
  static void _updateMemoryUsage() {
    if (Platform.isAndroid || Platform.isIOS) {
      // Platform-specific memory tracking would go here
      // For now, use a simple estimation based on active assets
      _currentMemoryUsage = _estimateMemoryUsage();
      
      if (_currentMemoryUsage > _peakMemoryUsage) {
        _peakMemoryUsage = _currentMemoryUsage;
      }
    }
  }

  /// Estimate memory usage based on tracked objects
  static int _estimateMemoryUsage() {
    int estimated = 0;
    
    // Base app memory
    estimated += 20 * 1024 * 1024; // 20MB base
    
    // Asset memory
    estimated += _activeAssets.length * 100 * 1024; // ~100KB per asset
    
    // Object pool memory
    for (final pool in _objectPools.values) {
      estimated += pool.length * 1024; // ~1KB per pooled object
    }
    
    return estimated;
  }

  /// Take memory snapshot
  static void takeMemorySnapshot(String label) {
    _updateMemoryUsage();
    _memorySnapshots[label] = _currentMemoryUsage;
    
    developer.log(
      'Memory snapshot "$label": ${(_currentMemoryUsage / 1024 / 1024).toStringAsFixed(1)}MB',
      name: 'Performance',
    );
  }

  /// Trigger memory optimization
  static void _triggerMemoryOptimization() {
    if (!_enableMemoryOptimizations) return;

    // Clear unused object pools
    _clearUnusedPooledObjects();
    
    // Unload inactive assets
    _unloadInactiveAssets();
    
    // Force garbage collection (use sparingly)
    _forceGarbageCollection();
    
    developer.log('Memory optimization triggered', name: 'Performance');
  }

  // ========================================
  // OBJECT POOLING
  // ========================================

  /// Initialize object pools for common objects
  static void _initializeObjectPools() {
    // Initialize pools for common game objects
    _objectPools[Vector2] = Queue<Object>();
    _objectPools[Offset] = Queue<Object>();
    _objectPools[Size] = Queue<Object>();
    _objectPools[Rect] = Queue<Object>();
    _objectPools[Paint] = Queue<Object>();
  }

  /// Get object from pool or create new one
  static T getPooledObject<T extends Object>(T Function() factory) {
    final pool = _objectPools[T];
    if (pool != null && pool.isNotEmpty) {
      return pool.removeFirst() as T;
    }
    return factory();
  }

  /// Return object to pool for reuse
  static void returnToPool<T extends Object>(T object) {
    final pool = _objectPools[T];
    if (pool != null && pool.length < 100) { // Limit pool size
      pool.add(object);
    }
  }

  /// Clear unused pooled objects
  static void _clearUnusedPooledObjects() {
    for (final pool in _objectPools.values) {
      if (pool.length > 50) {
        // Keep only half the objects
        final keepCount = pool.length ~/ 2;
        while (pool.length > keepCount) {
          pool.removeFirst();
        }
      }
    }
  }

  /// Clear all object pools
  static void _clearObjectPools() {
    for (final pool in _objectPools.values) {
      pool.clear();
    }
  }

  // ========================================
  // ASSET MANAGEMENT
  // ========================================

  /// Track active asset
  static void trackAsset(String assetPath) {
    _activeAssets.add(assetPath);
  }

  /// Untrack asset
  static void untrackAsset(String assetPath) {
    _activeAssets.remove(assetPath);
  }

  /// Unload inactive assets
  static void _unloadInactiveAssets() {
    // This would integrate with your asset management system
    // For now, just clear the tracking
    if (_activeAssets.length > 100) {
      final assetsToRemove = _activeAssets.take(_activeAssets.length ~/ 2).toList();
      for (final asset in assetsToRemove) {
        _activeAssets.remove(asset);
      }
    }
  }

  // ========================================
  // OPTIMIZATION SUGGESTIONS
  // ========================================

  /// Suggest optimizations based on performance metrics
  static void _suggestOptimizations() {
    final suggestions = <String>[];

    if (_averageFPS < 45) {
      suggestions.add('Consider reducing particle effects');
      suggestions.add('Lower animation quality');
    }

    if (_droppedFrames > _totalFrames * 0.1) {
      suggestions.add('Optimize rendering pipeline');
      suggestions.add('Reduce complex widget rebuilds');
    }

    if (_currentMemoryUsage > 100 * 1024 * 1024) {
      suggestions.add('Enable memory optimizations');
      suggestions.add('Reduce cached assets');
    }

    for (final suggestion in suggestions) {
      developer.log('OPTIMIZATION: $suggestion', name: 'Performance');
    }
  }

  // ========================================
  // PERFORMANCE UTILITIES
  // ========================================

  /// Force garbage collection (use sparingly)
  static void _forceGarbageCollection() {
    // This is a hint to the GC, not a guarantee
    if (kDebugMode) {
      developer.log('Forcing garbage collection', name: 'Performance');
    }
  }

  /// Reduce widget rebuilds by providing stable keys
  static Key getStableKey(String identifier) {
    return ValueKey('stable_$identifier');
  }

  /// Optimize list scrolling performance
  static Widget optimizedListBuilder({
    required int itemCount,
    required Widget Function(BuildContext, int) itemBuilder,
    double? itemExtent,
  }) {
    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: itemBuilder,
      itemExtent: itemExtent,
      cacheExtent: 500, // Limit cache for memory
      physics: const ClampingScrollPhysics(),
    );
  }

  /// Debounce function calls to reduce CPU usage
  static void Function() debounce(
    void Function() function,
    Duration delay,
  ) {
    Timer? timer;
    return () {
      timer?.cancel();
      timer = Timer(delay, function);
    };
  }

  /// Throttle function calls to limit frequency
  static void Function() throttle(
    void Function() function,
    Duration interval,
  ) {
    bool canExecute = true;
    return () {
      if (canExecute) {
        function();
        canExecute = false;
        Timer(interval, () {
          canExecute = true;
        });
      }
    };
  }

  // ========================================
  // PERFORMANCE METRICS
  // ========================================

  /// Get current performance metrics
  static PerformanceMetrics getMetrics() {
    return PerformanceMetrics(
      averageFPS: _averageFPS,
      worstFrameTime: _worstFrameTime,
      droppedFrames: _droppedFrames,
      totalFrames: _totalFrames,
      currentMemoryMB: _currentMemoryUsage / 1024 / 1024,
      peakMemoryMB: _peakMemoryUsage / 1024 / 1024,
      coldStartTime: _coldStartComplete?.difference(_appStartTime ?? DateTime.now()),
      activeAssets: _activeAssets.length,
      pooledObjects: _objectPools.values.fold(0, (sum, pool) => sum + pool.length),
    );
  }

  /// Get performance settings
  static PerformanceSettings getSettings() {
    return PerformanceSettings(
      enableAdvancedOptimizations: _enableAdvancedOptimizations,
      enableMemoryOptimizations: _enableMemoryOptimizations,
      enableFrameRateMonitoring: _enableFrameRateMonitoring,
    );
  }

  /// Update performance settings
  static void updateSettings(PerformanceSettings settings) {
    _enableAdvancedOptimizations = settings.enableAdvancedOptimizations;
    _enableMemoryOptimizations = settings.enableMemoryOptimizations;
    _enableFrameRateMonitoring = settings.enableFrameRateMonitoring;
    
    developer.log('Performance settings updated', name: 'Performance');
  }

  /// Get performance report for debugging
  static String getPerformanceReport() {
    final metrics = getMetrics();
    final buffer = StringBuffer();
    
    buffer.writeln('=== PERFORMANCE REPORT ===');
    buffer.writeln('Average FPS: ${metrics.averageFPS.toStringAsFixed(1)}');
    buffer.writeln('Worst Frame: ${metrics.worstFrameTime.toStringAsFixed(1)}ms');
    buffer.writeln('Dropped Frames: ${metrics.droppedFrames}/${metrics.totalFrames}');
    buffer.writeln('Memory Usage: ${metrics.currentMemoryMB.toStringAsFixed(1)}MB');
    buffer.writeln('Peak Memory: ${metrics.peakMemoryMB.toStringAsFixed(1)}MB');
    
    if (metrics.coldStartTime != null) {
      buffer.writeln('Cold Start: ${metrics.coldStartTime!.inMilliseconds}ms');
    }
    
    buffer.writeln('Active Assets: ${metrics.activeAssets}');
    buffer.writeln('Pooled Objects: ${metrics.pooledObjects}');
    buffer.writeln('========================');
    
    return buffer.toString();
  }
}

/// Performance metrics data class
class PerformanceMetrics {
  final double averageFPS;
  final double worstFrameTime;
  final int droppedFrames;
  final int totalFrames;
  final double currentMemoryMB;
  final double peakMemoryMB;
  final Duration? coldStartTime;
  final int activeAssets;
  final int pooledObjects;

  const PerformanceMetrics({
    required this.averageFPS,
    required this.worstFrameTime,
    required this.droppedFrames,
    required this.totalFrames,
    required this.currentMemoryMB,
    required this.peakMemoryMB,
    this.coldStartTime,
    required this.activeAssets,
    required this.pooledObjects,
  });

  bool get isPerformanceGood {
    return averageFPS >= AppConstants.minTargetFPS &&
           currentMemoryMB <= AppConstants.maxMemoryUsageMB &&
           (coldStartTime?.inMilliseconds ?? 0) <= AppConstants.maxColdStartMs;
  }

  double get frameDropPercentage {
    return totalFrames > 0 ? (droppedFrames / totalFrames) * 100 : 0;
  }
}

/// Performance settings data class
class PerformanceSettings {
  final bool enableAdvancedOptimizations;
  final bool enableMemoryOptimizations;
  final bool enableFrameRateMonitoring;

  const PerformanceSettings({
    required this.enableAdvancedOptimizations,
    required this.enableMemoryOptimizations,
    required this.enableFrameRateMonitoring,
  });

  PerformanceSettings copyWith({
    bool? enableAdvancedOptimizations,
    bool? enableMemoryOptimizations,
    bool? enableFrameRateMonitoring,
  }) {
    return PerformanceSettings(
      enableAdvancedOptimizations: enableAdvancedOptimizations ?? this.enableAdvancedOptimizations,
      enableMemoryOptimizations: enableMemoryOptimizations ?? this.enableMemoryOptimizations,
      enableFrameRateMonitoring: enableFrameRateMonitoring ?? this.enableFrameRateMonitoring,
    );
  }
}

/// Vector2 class for object pooling (if not available from Flame)
class Vector2 {
  double x;
  double y;
  
  Vector2(this.x, this.y);
  
  Vector2.zero() : x = 0, y = 0;
  
  void setValues(double x, double y) {
    this.x = x;
    this.y = y;
  }
  
  void setZero() {
    x = 0;
    y = 0;
  }
}