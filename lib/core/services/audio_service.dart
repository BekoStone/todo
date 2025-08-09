import 'dart:async';
import 'dart:developer' as developer;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// AudioService manages all audio playback in the application.
/// Handles music, sound effects, volume control, and audio state management.
/// Provides optimized audio performance with proper resource management.
class AudioService {
  // Audio players
  late AudioPlayer _musicPlayer;
  late AudioPlayer _sfxPlayer;
  
  // Audio cache
  final Map<String, String> _audioCache = {};
  
  // State tracking
  bool _isInitialized = false;
  bool _musicEnabled = true;
  bool _sfxEnabled = true;
  double _musicVolume = 0.7;
  double _sfxVolume = 0.8;
  
  // Current audio state
  String? _currentMusicTrack;
  bool _isMusicPlaying = false;
  bool _isMusicPaused = false;
  
  // Timers for audio management
  Timer? _fadeTimer;
  Timer? _sfxCooldownTimer;
  
  // SFX cooldown tracking to prevent spam
  final Map<String, DateTime> _sfxCooldowns = {};
  
  // Audio file paths
  static const Map<String, String> _musicTracks = {
    'menu': 'audio/music/menu_theme.mp3',
    'game_background': 'audio/music/game_theme.mp3',
    'victory': 'audio/music/victory_theme.mp3',
    'ambient': 'audio/music/ambient_theme.mp3',
  };
  
  static const Map<String, String> _soundEffects = {
    // UI Sounds
    'ui_click': 'audio/sfx/ui_click.wav',
    'ui_navigate': 'audio/sfx/ui_navigate.wav',
    'ui_toggle': 'audio/sfx/ui_toggle.wav',
    'ui_success': 'audio/sfx/ui_success.wav',
    'ui_error': 'audio/sfx/ui_error.wav',
    'achievement_unlock': 'audio/sfx/achievement_unlock.wav',
    'achievement_unlocked': 'audio/sfx/achievement_unlock.wav',
    
    // Game Sounds
    'block_place': 'audio/sfx/block_place.wav',
    'block_drag': 'audio/sfx/block_drag.wav',
    'block_snap': 'audio/sfx/block_snap.wav',
    'line_clear_single': 'audio/sfx/line_clear_single.wav',
    'line_clear_double': 'audio/sfx/line_clear_double.wav',
    'line_clear_triple': 'audio/sfx/line_clear_triple.wav',
    'line_clear_quad': 'audio/sfx/line_clear_quad.wav',
    'line_clear_mega': 'audio/sfx/line_clear_mega.wav',
    'combo_1': 'audio/sfx/combo_1.wav',
    'combo_2': 'audio/sfx/combo_2.wav',
    'combo_3': 'audio/sfx/combo_3.wav',
    'combo_4': 'audio/sfx/combo_4.wav',
    'combo_5': 'audio/sfx/combo_5.wav',
    'level_up': 'audio/sfx/level_up.wav',
    'game_over': 'audio/sfx/game_over.wav',
    'power_up_use': 'audio/sfx/power_up.wav',
    'button_click': 'audio/sfx/ui_click.wav',
    
    // Feedback Sounds
    'coins_earned': 'audio/sfx/coin_earn.wav',
    'coin_earn': 'audio/sfx/coin_earn.wav',
    'purchase': 'audio/sfx/purchase.wav',
    'unlock': 'audio/sfx/unlock.wav',
    'notification': 'audio/sfx/notification.wav',
    'placement_invalid': 'audio/sfx/ui_error.wav',
    'placement_cancel': 'audio/sfx/ui_click.wav',
  };

  /// Initialize the audio service
  Future<void> initialize() async {
    try {
      developer.log('Initializing AudioService', name: 'AudioService');
      
      // Initialize audio players
      _musicPlayer = AudioPlayer();
      _sfxPlayer = AudioPlayer();
      
      // Configure audio players
      await _configureAudioPlayers();
      
      // Preload critical audio files
      await _preloadCriticalAudio();
      
      _isInitialized = true;
      developer.log('AudioService initialized successfully', name: 'AudioService');
      
    } catch (e, stackTrace) {
      developer.log('Failed to initialize AudioService: $e', name: 'AudioService', stackTrace: stackTrace);
      _isInitialized = false;
      // Don't rethrow - audio failure shouldn't crash the app
    }
  }

  /// Configure audio players with optimal settings
  Future<void> _configureAudioPlayers() async {
    try {
      // Configure music player
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer.setVolume(_musicVolume);
      
      // Configure SFX player
      await _sfxPlayer.setReleaseMode(ReleaseMode.stop);
      await _sfxPlayer.setVolume(_sfxVolume);
      
      // Set up audio player listeners
      _setupAudioPlayerListeners();
      
    } catch (e) {
      developer.log('Failed to configure audio players: $e', name: 'AudioService');
    }
  }

  /// Setup audio player event listeners
  void _setupAudioPlayerListeners() {
    // Music player listeners
    _musicPlayer.onPlayerStateChanged.listen((PlayerState state) {
      _isMusicPlaying = state == PlayerState.playing;
      _isMusicPaused = state == PlayerState.paused;
      
      if (state == PlayerState.completed) {
        _handleMusicCompleted();
      }
    });
    
    // Handle player errors gracefully
    _musicPlayer.onLog.listen((String message) {
      developer.log('Music player: $message', name: 'AudioService');
    });
    
    _sfxPlayer.onLog.listen((String message) {
      developer.log('SFX player: $message', name: 'AudioService');
    });
  }

  /// Handle music track completion
  void _handleMusicCompleted() {
    // For looping tracks, this shouldn't normally be called
    // But handle edge cases where loop fails
    if (_currentMusicTrack != null && _musicEnabled) {
      developer.log('Music track completed unexpectedly, restarting', name: 'AudioService');
      playMusic(_currentMusicTrack!);
    }
  }

  /// Preload critical audio files for better performance
  Future<void> _preloadCriticalAudio() async {
    final criticalSounds = [
      'ui_click',
      'ui_navigate',
      'block_place',
      'game_over',
    ];

    for (final sound in criticalSounds) {
      try {
        if (_soundEffects.containsKey(sound)) {
          final path = _soundEffects[sound]!;
          _audioCache[sound] = path;
        }
      } catch (e) {
        developer.log('Failed to preload $sound: $e', name: 'AudioService');
      }
    }
    
    developer.log('Preloaded ${_audioCache.length} critical audio files', name: 'AudioService');
  }

  // ========================================
  // MUSIC CONTROL
  // ========================================

  /// Play background music
  Future<void> playMusic(String trackName, {bool fadeIn = true}) async {
    if (!_isInitialized || !_musicEnabled) return;

    try {
      final trackPath = _musicTracks[trackName];
      if (trackPath == null) {
        developer.log('Music track not found: $trackName', name: 'AudioService');
        return;
      }

      // Stop current music if different track
      if (_currentMusicTrack != trackName) {
        await _musicPlayer.stop();
      }

      _currentMusicTrack = trackName;

      if (fadeIn) {
        await _fadeInMusic(trackPath);
      } else {
        await _musicPlayer.play(AssetSource(trackPath));
      }

      developer.log('Playing music: $trackName', name: 'AudioService');
      
    } catch (e) {
      developer.log('Failed to play music $trackName: $e', name: 'AudioService');
    }
  }

  /// Stop background music
  Future<void> stopMusic({bool fadeOut = true}) async {
    if (!_isInitialized) return;

    try {
      if (fadeOut && _isMusicPlaying) {
        await _fadeOutMusic();
      } else {
        await _musicPlayer.stop();
      }

      _currentMusicTrack = null;
      developer.log('Music stopped', name: 'AudioService');
      
    } catch (e) {
      developer.log('Failed to stop music: $e', name: 'AudioService');
    }
  }

  /// Pause background music
  Future<void> pauseMusic() async {
    if (!_isInitialized || !_isMusicPlaying) return;

    try {
      await _musicPlayer.pause();
      developer.log('Music paused', name: 'AudioService');
    } catch (e) {
      developer.log('Failed to pause music: $e', name: 'AudioService');
    }
  }

  /// Resume background music
  Future<void> resumeMusic() async {
    if (!_isInitialized || !_isMusicPaused) return;

    try {
      await _musicPlayer.resume();
      developer.log('Music resumed', name: 'AudioService');
    } catch (e) {
      developer.log('Failed to resume music: $e', name: 'AudioService');
    }
  }

  /// Fade in music
  Future<void> _fadeInMusic(String trackPath) async {
    const int steps = 20;
    const int intervalMs = 50;
    final double stepVolume = _musicVolume / steps;

    await _musicPlayer.setVolume(0.0);
    await _musicPlayer.play(AssetSource(trackPath));

    _fadeTimer?.cancel();
    _fadeTimer = Timer.periodic(const Duration(milliseconds: intervalMs), (timer) async {
      final currentVolume = (timer.tick * stepVolume).clamp(0.0, _musicVolume);
      await _musicPlayer.setVolume(currentVolume);

      if (timer.tick >= steps) {
        timer.cancel();
        _fadeTimer = null;
      }
    });
  }

  /// Fade out music
  Future<void> _fadeOutMusic() async {
    const int steps = 20;
    const int intervalMs = 50;
    final double stepVolume = _musicVolume / steps;

    _fadeTimer?.cancel();
    _fadeTimer = Timer.periodic(const Duration(milliseconds: intervalMs), (timer) async {
      final currentVolume = (_musicVolume - (timer.tick * stepVolume)).clamp(0.0, 1.0);
      await _musicPlayer.setVolume(currentVolume);

      if (currentVolume <= 0.0) {
        timer.cancel();
        _fadeTimer = null;
        await _musicPlayer.stop();
        await _musicPlayer.setVolume(_musicVolume);
      }
    });
  }

  // ========================================
  // SOUND EFFECTS
  // ========================================

  /// Play a sound effect
  Future<void> playSfx(String soundName, {double? volume}) async {
    if (!_isInitialized || !_sfxEnabled) return;

    // Check cooldown to prevent spam
    if (_isOnCooldown(soundName)) return;

    try {
      final soundPath = _soundEffects[soundName];
      if (soundPath == null) {
        developer.log('Sound effect not found: $soundName', name: 'AudioService');
        return;
      }

      final playVolume = volume ?? _sfxVolume;
      await _sfxPlayer.setVolume(playVolume);
      await _sfxPlayer.play(AssetSource(soundPath));

      _setSfxCooldown(soundName);
      
    } catch (e) {
      developer.log('Failed to play SFX $soundName: $e', name: 'AudioService');
    }
  }

  /// Check if sound effect is on cooldown
  bool _isOnCooldown(String soundName) {
    final lastPlayed = _sfxCooldowns[soundName];
    if (lastPlayed == null) return false;

    const cooldownDuration = Duration(milliseconds: 100);
    return DateTime.now().difference(lastPlayed) < cooldownDuration;
  }

  /// Set cooldown for sound effect
  void _setSfxCooldown(String soundName) {
    _sfxCooldowns[soundName] = DateTime.now();
  }

  /// Play UI sound with haptic feedback
  Future<void> playUiSound(String soundName, {HapticType? haptic}) async {
    await playSfx(soundName);
    
    if (haptic != null) {
      await triggerHaptic(haptic);
    }
  }

  /// Trigger haptic feedback
  Future<void> triggerHaptic(HapticType type) async {
    try {
      switch (type) {
        case HapticType.light:
          await HapticFeedback.lightImpact();
          break;
        case HapticType.medium:
          await HapticFeedback.mediumImpact();
          break;
        case HapticType.heavy:
          await HapticFeedback.heavyImpact();
          break;
        case HapticType.selection:
          await HapticFeedback.selectionClick();
          break;
      }
    } catch (e) {
      developer.log('Failed to trigger haptic feedback: $e', name: 'AudioService');
    }
  }

  // ========================================
  // VOLUME CONTROL
  // ========================================

  /// Set music volume
  Future<void> setMusicVolume(double volume) async {
    _musicVolume = volume.clamp(0.0, 1.0);
    
    if (_isInitialized) {
      await _musicPlayer.setVolume(_musicVolume);
    }
    
    developer.log('Music volume set to: $_musicVolume', name: 'AudioService');
  }

  /// Set SFX volume
  Future<void> setSfxVolume(double volume) async {
    _sfxVolume = volume.clamp(0.0, 1.0);
    
    if (_isInitialized) {
      await _sfxPlayer.setVolume(_sfxVolume);
    }
    
    developer.log('SFX volume set to: $_sfxVolume', name: 'AudioService');
  }

  /// Enable/disable music
  Future<void> setMusicEnabled(bool enabled) async {
    _musicEnabled = enabled;
    
    if (!enabled && _isMusicPlaying) {
      await pauseMusic();
    } else if (enabled && _currentMusicTrack != null) {
      await resumeMusic();
    }
    
    developer.log('Music enabled: $enabled', name: 'AudioService');
  }

  /// Enable/disable sound effects
  void setSfxEnabled(bool enabled) {
    _sfxEnabled = enabled;
    developer.log('SFX enabled: $enabled', name: 'AudioService');
  }

  // ========================================
  // GAME-SPECIFIC AUDIO
  // ========================================

  /// Play combo sound based on combo count
  Future<void> playComboSound(int comboCount) async {
    final soundName = 'combo_${comboCount.clamp(1, 5)}';
    await playSfx(soundName);
  }

  /// Play line clear sound based on lines cleared
  Future<void> playLineClearSound(int linesCleared) async {
    String soundName;
    switch (linesCleared) {
      case 1:
        soundName = 'line_clear_single';
        break;
      case 2:
        soundName = 'line_clear_double';
        break;
      case 3:
        soundName = 'line_clear_triple';
        break;
      case 4:
        soundName = 'line_clear_quad';
        break;
      default:
        soundName = 'line_clear_mega';
        break;
    }
    await playSfx(soundName);
  }

  /// Play achievement sound
  Future<void> playAchievementSound() async {
    await playSfx('achievement_unlock');
    await triggerHaptic(HapticType.medium);
  }

  // ========================================
  // GETTERS
  // ========================================

  /// Check if audio service is initialized
  bool get isInitialized => _isInitialized;

  /// Get current music track
  String? get currentMusicTrack => _currentMusicTrack;

  /// Check if music is playing
  bool get isMusicPlaying => _isMusicPlaying;

  /// Check if music is enabled
  bool get isMusicEnabled => _musicEnabled;

  /// Check if SFX is enabled
  bool get isSfxEnabled => _sfxEnabled;

  /// Get music volume
  double get musicVolume => _musicVolume;

  /// Get SFX volume
  double get sfxVolume => _sfxVolume;

  /// Get available music tracks
  List<String> get availableMusicTracks => _musicTracks.keys.toList();

  /// Get available sound effects
  List<String> get availableSoundEffects => _soundEffects.keys.toList();

  /// Clear audio cache
  void clearCache() {
    _audioCache.clear();
    developer.log('Audio cache cleared', name: 'AudioService');
  }

  /// Get audio service status
  Map<String, dynamic> getStatus() {
    return {
      'initialized': _isInitialized,
      'musicEnabled': _musicEnabled,
      'sfxEnabled': _sfxEnabled,
      'musicVolume': _musicVolume,
      'sfxVolume': _sfxVolume,
      'currentTrack': _currentMusicTrack,
      'musicPlaying': _isMusicPlaying,
      'cacheSize': _audioCache.length,
    };
  }

  // ========================================
  // CLEANUP
  // ========================================

  /// Dispose of audio service and clean up resources
  Future<void> dispose() async {
    try {
      developer.log('Disposing AudioService', name: 'AudioService');
      
      // Cancel timers
      _fadeTimer?.cancel();
      _sfxCooldownTimer?.cancel();
      
      // Stop and dispose audio players
      await _musicPlayer.stop();
      await _sfxPlayer.stop();
      await _musicPlayer.dispose();
      await _sfxPlayer.dispose();
      
      // Clear cache and state
      _audioCache.clear();
      _sfxCooldowns.clear();
      _isInitialized = false;
      
      developer.log('AudioService disposed', name: 'AudioService');
      
    } catch (e) {
      developer.log('Error disposing AudioService: $e', name: 'AudioService');
    }
  }
}

/// Haptic feedback types
enum HapticType {
  light,
  medium,
  heavy,
  selection,
}