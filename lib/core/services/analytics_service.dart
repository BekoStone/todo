// File: lib/core/services/analytics_service.dart

import 'dart:async';
import 'dart:developer' as developer;


/// Analytics events for tracking user behavior
enum AnalyticsEvent {
  // Game Events
  gameStarted,
  gameEnded,
  gameRestarted,
  gamePaused,
  gameResumed,
  
  // Gameplay Events
  blockPlaced,
  lineCleared,
  comboAchieved,
  perfectClear,
  gameOver,
  
  // Power-up Events
  powerUpUsed,
  powerUpPurchased,
  powerUpEarned,
  
  // Achievement Events
  achievementUnlocked,
  achievementProgress,
  
  // Economy Events
  coinsEarned,
  coinsSpent,
  dailyRewardClaimed,
  adWatched,
  
  // UI Events
  screenViewed,
  buttonClicked,
  settingChanged,
  
  // Social Events
  scoreShared,
  gameShared,
  ratingGiven,
  
  // Performance Events
  performanceIssue,
  crashReported,
  errorOccurred,
  
  // Engagement Events
  sessionStarted,
  sessionEnded,
  retentionCheck,
  
  // Tutorial Events
  tutorialStarted,
  tutorialCompleted,
  tutorialSkipped,
  
  // Store Events
  storeViewed,
  itemPurchased,
  purchaseRestored,
}

/// Priority levels for analytics events
enum EventPriority {
  low,
  normal,
  high,
  critical,
}

/// Analytics event data structure
class AnalyticsEventData {
  final AnalyticsEvent event;
  final Map<String, dynamic> parameters;
  final EventPriority priority;
  final DateTime timestamp;
  final String? userId;
  final String? sessionId;

  const AnalyticsEventData({
    required this.event,
    required this.parameters,
    this.priority = EventPriority.normal,
    required this.timestamp,
    this.userId,
    this.sessionId,
  });

  Map<String, dynamic> toMap() => {
    'event': event.name,
    'parameters': parameters,
    'priority': priority.name,
    'timestamp': timestamp.millisecondsSinceEpoch,
    'userId': userId,
    'sessionId': sessionId,
  };
}

/// Analytics service interface
abstract class AnalyticsService {
  /// Initialize the analytics service
  Future<void> initialize();

  /// Track an analytics event
  Future<void> trackEvent(
    AnalyticsEvent event, {
    Map<String, dynamic>? parameters,
    EventPriority priority = EventPriority.normal,
  });

  /// Set user properties
  Future<void> setUserProperties(Map<String, dynamic> properties);

  /// Set user ID for tracking
  Future<void> setUserId(String userId);

  /// Set current screen/page
  Future<void> setCurrentScreen(String screenName);

  /// Log error/crash
  Future<void> logError(
    String error, {
    String? stackTrace,
    Map<String, dynamic>? additionalData,
  });

  /// Set custom properties for this session
  Future<void> setSessionProperties(Map<String, dynamic> properties);

  /// Enable/disable analytics tracking
  Future<void> setAnalyticsEnabled(bool enabled);

  /// Clear all analytics data
  Future<void> clearAnalyticsData();

  /// Get analytics configuration
  Map<String, dynamic> getConfiguration();

  /// Dispose of resources
  Future<void> dispose();
}

/// Default analytics service implementation
class DefaultAnalyticsService implements AnalyticsService {
  bool _isInitialized = false;
  bool _isEnabled = true;
  String? _currentUserId;
  String? _currentSessionId;
  String? _currentScreen;
  final Map<String, dynamic> _sessionProperties = {};
  final Map<String, dynamic> _userProperties = {};
  final List<AnalyticsEventData> _eventQueue = [];
  Timer? _flushTimer;

  static const int _maxQueueSize = 1000;
  static const Duration _flushInterval = Duration(seconds: 30);

  @override
  Future<void> initialize() async {
    try {
      if (_isInitialized) return;

      // Generate session ID
      _currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();

      // Start periodic flush timer
      _flushTimer = Timer.periodic(_flushInterval, (_) => _flushEvents());

      // Track session started
      await trackEvent(
        AnalyticsEvent.sessionStarted,
        parameters: {
          'session_id': _currentSessionId,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
        priority: EventPriority.high,
      );

      _isInitialized = true;
      developer.log('AnalyticsService initialized', name: 'Analytics');
    } catch (e) {
      throw InitializationException('Failed to initialize analytics service: $e');
    }
  }

  @override
  Future<void> trackEvent(
    AnalyticsEvent event, {
    Map<String, dynamic>? parameters,
    EventPriority priority = EventPriority.normal,
  }) async {
    if (!_isEnabled || !_isInitialized) return;

    try {
      final eventData = AnalyticsEventData(
        event: event,
        parameters: {
          ...?parameters,
          'screen': _currentScreen,
          'session_properties': _sessionProperties,
          'user_properties': _userProperties,
        },
        priority: priority,
        timestamp: DateTime.now(),
        userId: _currentUserId,
        sessionId: _currentSessionId,
      );

      _eventQueue.add(eventData);

      // Maintain queue size
      if (_eventQueue.length > _maxQueueSize) {
        _eventQueue.removeAt(0);
      }

      // Immediate flush for critical events
      if (priority == EventPriority.critical) {
        await _flushEvents();
      }

      developer.log(
        'Event tracked: ${event.name}',
        name: 'Analytics',
        time: eventData.timestamp,
      );
    } catch (e) {
      developer.log('Failed to track event: $e', name: 'Analytics');
    }
  }

  @override
  Future<void> setUserProperties(Map<String, dynamic> properties) async {
    if (!_isEnabled) return;

    try {
      _userProperties.addAll(properties);
      developer.log('User properties set: $properties', name: 'Analytics');
    } catch (e) {
      developer.log('Failed to set user properties: $e', name: 'Analytics');
    }
  }

  @override
  Future<void> setUserId(String userId) async {
    if (!_isEnabled) return;

    try {
      _currentUserId = userId;
      await trackEvent(
        AnalyticsEvent.sessionStarted,
        parameters: {'user_id_set': userId},
        priority: EventPriority.high,
      );
      developer.log('User ID set: $userId', name: 'Analytics');
    } catch (e) {
      developer.log('Failed to set user ID: $e', name: 'Analytics');
    }
  }

  @override
  Future<void> setCurrentScreen(String screenName) async {
    if (!_isEnabled) return;

    try {
      final previousScreen = _currentScreen;
      _currentScreen = screenName;

      await trackEvent(
        AnalyticsEvent.screenViewed,
        parameters: {
          'screen_name': screenName,
          'previous_screen': previousScreen,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
        priority: EventPriority.normal,
      );

      developer.log('Screen set: $screenName', name: 'Analytics');
    } catch (e) {
      developer.log('Failed to set current screen: $e', name: 'Analytics');
    }
  }

  @override
  Future<void> logError(
    String error, {
    String? stackTrace,
    Map<String, dynamic>? additionalData,
  }) async {
    if (!_isEnabled) return;

    try {
      await trackEvent(
        AnalyticsEvent.errorOccurred,
        parameters: {
          'error_message': error,
          'stack_trace': stackTrace,
          'additional_data': additionalData,
          'screen': _currentScreen,
          'user_id': _currentUserId,
          'session_id': _currentSessionId,
        },
        priority: EventPriority.critical,
      );

      developer.log('Error logged: $error', name: 'Analytics');
    } catch (e) {
      developer.log('Failed to log error: $e', name: 'Analytics');
    }
  }

  @override
  Future<void> setSessionProperties(Map<String, dynamic> properties) async {
    if (!_isEnabled) return;

    try {
      _sessionProperties.addAll(properties);
      developer.log('Session properties set: $properties', name: 'Analytics');
    } catch (e) {
      developer.log('Failed to set session properties: $e', name: 'Analytics');
    }
  }

  @override
  Future<void> setAnalyticsEnabled(bool enabled) async {
    _isEnabled = enabled;
    
    if (!enabled) {
      await clearAnalyticsData();
    }

    developer.log('Analytics enabled: $enabled', name: 'Analytics');
  }

  @override
  Future<void> clearAnalyticsData() async {
    try {
      _eventQueue.clear();
      _userProperties.clear();
      _sessionProperties.clear();
      _currentUserId = null;
      _currentScreen = null;

      developer.log('Analytics data cleared', name: 'Analytics');
    } catch (e) {
      developer.log('Failed to clear analytics data: $e', name: 'Analytics');
    }
  }

  @override
  Map<String, dynamic> getConfiguration() {
    return {
      'is_initialized': _isInitialized,
      'is_enabled': _isEnabled,
      'current_user_id': _currentUserId,
      'current_session_id': _currentSessionId,
      'current_screen': _currentScreen,
      'queue_size': _eventQueue.length,
      'max_queue_size': _maxQueueSize,
      'flush_interval_seconds': _flushInterval.inSeconds,
      'session_properties_count': _sessionProperties.length,
      'user_properties_count': _userProperties.length,
    };
  }

  @override
  Future<void> dispose() async {
    try {
      // Track session ended
      if (_isEnabled && _isInitialized) {
        await trackEvent(
          AnalyticsEvent.sessionEnded,
          parameters: {
            'session_duration': DateTime.now().millisecondsSinceEpoch - 
                               (int.tryParse(_currentSessionId ?? '0') ?? 0),
            'events_tracked': _eventQueue.length,
          },
          priority: EventPriority.high,
        );
      }

      // Flush remaining events
      await _flushEvents();

      // Cancel timer
      _flushTimer?.cancel();

      // Clear resources
      await clearAnalyticsData();

      _isInitialized = false;
      developer.log('AnalyticsService disposed', name: 'Analytics');
    } catch (e) {
      developer.log('Failed to dispose analytics service: $e', name: 'Analytics');
    }
  }

  /// Flush queued events
  Future<void> _flushEvents() async {
    if (_eventQueue.isEmpty) return;

    try {
      final eventsToFlush = List<AnalyticsEventData>.from(_eventQueue);
      _eventQueue.clear();

      // In a real implementation, you would send these to your analytics provider
      // For now, we'll just log them
      for (final event in eventsToFlush) {
        developer.log(
          'Flushed event: ${event.event.name}',
          name: 'Analytics',
          time: event.timestamp,
        );
      }

      developer.log('Flushed ${eventsToFlush.length} events', name: 'Analytics');
    } catch (e) {
      developer.log('Failed to flush events: $e', name: 'Analytics');
    }
  }
}

/// Game-specific analytics tracking extensions
extension GameAnalytics on AnalyticsService {
  /// Track game session metrics
  Future<void> trackGameSession({
    required int score,
    required int level,
    required int linesCleared,
    required Duration duration,
    required int blocksPlaced,
    required int powerUpsUsed,
    required bool completedWithoutUndo,
  }) async {
    await trackEvent(
      AnalyticsEvent.gameEnded,
      parameters: {
        'final_score': score,
        'level_reached': level,
        'lines_cleared': linesCleared,
        'session_duration_seconds': duration.inSeconds,
        'blocks_placed': blocksPlaced,
        'power_ups_used': powerUpsUsed,
        'completed_without_undo': completedWithoutUndo,
        'score_per_minute': duration.inMinutes > 0 ? score / duration.inMinutes : 0,
        'average_score_per_block': blocksPlaced > 0 ? score / blocksPlaced : 0,
      },
      priority: EventPriority.high,
    );
  }

  /// Track power-up usage
  Future<void> trackPowerUpUsage({
    required String powerUpType,
    required String source, // earned, purchased, etc.
    required Map<String, dynamic> gameState,
  }) async {
    await trackEvent(
      AnalyticsEvent.powerUpUsed,
      parameters: {
        'power_up_type': powerUpType,
        'source': source,
        'game_state': gameState,
      },
    );
  }

  /// Track achievement unlock
  Future<void> trackAchievementUnlock({
    required String achievementId,
    required String achievementName,
    required int coinReward,
    required Map<String, dynamic> progressData,
  }) async {
    await trackEvent(
      AnalyticsEvent.achievementUnlocked,
      parameters: {
        'achievement_id': achievementId,
        'achievement_name': achievementName,
        'coin_reward': coinReward,
        'progress_data': progressData,
      },
      priority: EventPriority.high,
    );
  }

  /// Track economy actions
  Future<void> trackEconomyAction({
    required String action, // earned, spent, purchased
    required int amount,
    required String source,
    required Map<String, dynamic> context,
  }) async {
    await trackEvent(
      action == 'earned' ? AnalyticsEvent.coinsEarned : AnalyticsEvent.coinsSpent,
      parameters: {
        'action': action,
        'amount': amount,
        'source': source,
        'context': context,
      },
    );
  }

  /// Track performance metrics
  Future<void> trackPerformance({
    required double frameRate,
    required int memoryUsage,
    required Duration renderTime,
    required Map<String, dynamic> deviceInfo,
  }) async {
    await trackEvent(
      AnalyticsEvent.performanceIssue,
      parameters: {
        'frame_rate': frameRate,
        'memory_usage_mb': memoryUsage,
        'render_time_ms': renderTime.inMilliseconds,
        'device_info': deviceInfo,
      },
      priority: frameRate < 30 ? EventPriority.high : EventPriority.normal,
    );
  }
}