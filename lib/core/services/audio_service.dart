import 'dart:async';
import 'dart:developer' as developer;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';

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
  double _musicVolume = AppConstants.defaultMusicVolume;
  double _sfxVolume = AppConstants.defaultSfxVolume;
  
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
    'game': 'audio/music/game_theme.mp3',
    'victory': 'audio/music/victory_theme.mp3',
    'ambient': 'audio/music/ambient_theme.mp3',
  };
  
  static const Map<String, String> _soundEffects = {
    // UI Sounds
    'ui_click': 'audio/sfx/ui_click.wav',
    'ui_navigate': 'audio/sfx/ui_navigate.wav',
    'ui_success': 'audio/sfx/ui_success.wav',
    'ui_error': 'audio/sfx/ui_error.wav',
    'ui_achievement': 'audio/sfx/ui_achievement.wav',
    
    // Game Sounds
    'block_place': 'audio/sfx/block_place.wav',
    'block_drag': 'audio/sfx/block_drag.wav',
    'block_snap': 'audio/sfx/block_snap.wav',
    'line_clear_1': 'audio/sfx/line_clear_single.wav',
    'line_clear_2': 'audio/sfx/line_clear_double.wav',
    'line_clear_3': 'audio/sfx/line_clear_triple.wav',
    'line_clear_4': 'audio/sfx/line_clear_quad.wav',
    'line_clear_mega': 'audio/sfx/line_clear_mega.wav',
    'combo_1': 'audio/sfx/combo_1.wav',
    'combo_2': 'audio/sfx/combo_2.wav',
    'combo_3': 'audio/sfx/combo_3.wav',
    'combo_4': 'audio/sfx/combo_4.wav',
    'combo_5': 'audio/sfx/combo_5.wav',
    'level_up': 'audio/sfx/level_up.wav',
    'game_over': 'audio/sfx/game_over.wav',
    'power_up': 'audio/sfx/power_up.wav',
    
    // Feedback Sounds
    'coin_earn': 'audio/sfx/coin_earn.wav',
    'purchase': 'audio/sfx/purchase.wav',
    'unlock': 'audio/sfx/unlock.wav',
    'notification': 'audio/sfx/notification.wav',
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
      rethrow;
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
    
    // SFX player listeners  
    _sfxPlayer.onPlayerStateChanged.listen((PlayerState state) {
      // SFX completion handling if needed
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

  /// Preload critical audio files for instant playback
  Future<void> _preloadCriticalAudio() async {
    if (!kIsWeb) { // Skip preloading on web for performance
      try {
        // Preload essential UI sounds
        final criticalSfx = ['ui_click', 'ui_navigate', 'block_place', 'line_clear_1'];
        
        for (final sfxName in criticalSfx) {
          final path = _soundEffects[sfxName];
          if (path != null) {
            await _sfxPlayer.setSource(AssetSource(path));
            _audioCache[sfxName] = path;
          }
        }
        
        developer.log('Critical audio preloaded', name: 'AudioService');
      } catch (e) {
        developer.log('Failed to preload critical audio: $e', name: 'AudioService');
      }
    }
  }

  // ========================================
  // MUSIC PLAYBACK
  // ========================================

  /// Play background music track
  Future<void> playMusic(String trackName, {bool fadeIn = false}) async {
    if (!_isInitialized || !_musicEnabled) return;
    
    try {
      final trackPath = _musicTracks[trackName];
      if (trackPath == null) {
        developer.log('Music track not found: $trackName', name: 'AudioService');
        return;
      }
      
      // Stop current music if different track
      if (_currentMusicTrack != trackName && _isMusicPlaying) {
        await stopMusic(fadeOut: true);
      }
      
      // Set new track
      await _musicPlayer.setSource(AssetSource(trackPath));
      
      if (fadeIn) {
        await _fadeInMusic();
      } else {
        await _musicPlayer.resume();
      }
      
      _currentMusicTrack = trackName;
      developer.log('Playing music: $trackName', name: 'AudioService');
      
    } catch (e) {
      developer.log('Failed to play music: $e', name: 'AudioService');
    }
  }

  /// Stop background music
  Future<void> stopMusic({bool fadeOut = false}) async {
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

  // ========================================
  // SOUND EFFECTS
  // ========================================
  Future<void> setSoundEffectsEnabled(bool enabled) async {
    _sfxEnabled = enabled;
    
    if (!enabled && _sfxPlayer.state == PlayerState.playing) {
      await _sfxPlayer.stop();
    }
    
    developer.log('Sound effects enabled: $enabled', name: 'AudioService');
  }
  /// Play sound effect
  Future<void> playSfx(String sfxName, {double? volume}) async {
    if (!_isInitialized || !_sfxEnabled) return;
    
    // Check cooldown to prevent spam
    if (_isSfxOnCooldown(sfxName)) {
      return;
    }
    
    try {
      final sfxPath = _soundEffects[sfxName];
      if (sfxPath == null) {
        developer.log('Sound effect not found: $sfxName', name: 'AudioService');
        return;
      }
      
      // Set volume (use provided or default)
      final playVolume = volume ?? _sfxVolume;
      await _sfxPlayer.setVolume(playVolume);
      
      // Play sound effect
      await _sfxPlayer.play(AssetSource(sfxPath));
      
      // Set cooldown
      _setSfxCooldown(sfxName);
      
      developer.log('Playing SFX: $sfxName', name: 'AudioService');
      
    } catch (e) {
      developer.log('Failed to play SFX $sfxName: $e', name: 'AudioService');
    }
  }

  /// Play multiple sound effects in sequence
  Future<void> playSfxSequence(List<String> sfxNames, {Duration delay = const Duration(milliseconds: 100)}) async {
    for (int i = 0; i < sfxNames.length; i++) {
      await playSfx(sfxNames[i]);
      if (i < sfxNames.length - 1) {
        await Future.delayed(delay);
      }
    }
  }

  /// Check if sound effect is on cooldown
  bool _isSfxOnCooldown(String sfxName) {
    final lastPlayed = _sfxCooldowns[sfxName];
    if (lastPlayed == null) return false;
    
    const cooldownPeriod = AppConstants.soundDebounceInterval;
    return DateTime.now().difference(lastPlayed) < cooldownPeriod;
  }
Future<void> setSoundEffectsVolume(double volume) async {
    _sfxVolume = volume.clamp(0.0, 1.0);
    
    if (_isInitialized) {
      try {
        await _sfxPlayer.setVolume(_sfxVolume);
        developer.log('SFX volume set to: $_sfxVolume', name: 'AudioService');
      } catch (e) {
        developer.log('Failed to set SFX volume: $e', name: 'AudioService');
      }
    }
  }
  /// Set sound effect cooldown
  void _setSfxCooldown(String sfxName) {
    _sfxCooldowns[sfxName] = DateTime.now();
  }

  // ========================================
  // VOLUME CONTROL
  // ========================================

  /// Set music volume (0.0 to 1.0)
  Future<void> setMusicVolume(double volume) async {
    _musicVolume = volume.clamp(0.0, 1.0);
    
    if (_isInitialized) {
      try {
        await _musicPlayer.setVolume(_musicVolume);
        developer.log('Music volume set to: $_musicVolume', name: 'AudioService');
      } catch (e) {
        developer.log('Failed to set music volume: $e', name: 'AudioService');
      }
    }
  }

  /// Set sound effects volume (0.0 to 1.0)
  Future<void> setSfxVolume(double volume) async {
    _sfxVolume = volume.clamp(0.0, 1.0);
    
    if (_isInitialized) {
      try {
        await _sfxPlayer.setVolume(_sfxVolume);
        developer.log('SFX volume set to: $_sfxVolume', name: 'AudioService');
      } catch (e) {
        developer.log('Failed to set SFX volume: $e', name: 'AudioService');
      }
    }
  }

  /// Get current music volume
  double get musicVolume => _musicVolume;

  /// Get current SFX volume
  double get sfxVolume => _sfxVolume;

  // ========================================
  // AUDIO STATE CONTROL
  // ========================================

  /// Enable/disable music
  Future<void> setMusicEnabled(bool enabled) async {
    _musicEnabled = enabled;
    
    if (!enabled && _isMusicPlaying) {
      pauseMusic();
    } else if (enabled && _isMusicPaused && _currentMusicTrack != null) {
      resumeMusic();
    }
    
    developer.log('Music enabled: $enabled', name: 'AudioService');
  }

  /// Enable/disable sound effects
  void setSfxEnabled(bool enabled) {
    _sfxEnabled = enabled;
    developer.log('SFX enabled: $enabled', name: 'AudioService');
  }

  /// Check if music is enabled
  bool get isMusicEnabled => _musicEnabled;

  /// Check if sound effects are enabled
  bool get isSfxEnabled => _sfxEnabled;

  /// Check if music is currently playing
  bool get isMusicPlaying => _isMusicPlaying;

  /// Get current music track name
  String? get currentMusicTrack => _currentMusicTrack;

  // ========================================
  // AUDIO EFFECTS
  // ========================================

  /// Fade in music over specified duration
  Future<void> _fadeInMusic() async {
    if (!_isInitialized) return;
    
    try {
      await _musicPlayer.setVolume(0.0);
      await _musicPlayer.resume();
      
      const stepDuration = Duration(milliseconds: 50);
      const steps = 20;
      final volumeStep = _musicVolume / steps;
      
      _fadeTimer?.cancel();
      _fadeTimer = Timer.periodic(stepDuration, (timer) async {
        final currentStep = timer.tick;
        final newVolume = volumeStep * currentStep;
        
        if (currentStep >= steps) {
          await _musicPlayer.setVolume(_musicVolume);
          timer.cancel();
        } else {
          await _musicPlayer.setVolume(newVolume);
        }
      });
      
    } catch (e) {
      developer.log('Failed to fade in music: $e', name: 'AudioService');
    }
  }

  /// Fade out music over specified duration
  Future<void> _fadeOutMusic() async {
    if (!_isInitialized) return;
    
    try {
      const stepDuration = Duration(milliseconds: 50);
      const steps = 20;
      final volumeStep = _musicVolume / steps;
      
      _fadeTimer?.cancel();
      _fadeTimer = Timer.periodic(stepDuration, (timer) async {
        final currentStep = timer.tick;
        final newVolume = _musicVolume - (volumeStep * currentStep);
        
        if (currentStep >= steps) {
          await _musicPlayer.stop();
          await _musicPlayer.setVolume(_musicVolume);
          timer.cancel();
        } else {
          await _musicPlayer.setVolume(newVolume.clamp(0.0, 1.0));
        }
      });
      
    } catch (e) {
      developer.log('Failed to fade out music: $e', name: 'AudioService');
    }
  }

  /// Cross-fade between music tracks
  Future<void> crossFadeMusic(String newTrackName, {Duration duration = const Duration(seconds: 2)}) async {
    if (!_isInitialized || !_musicEnabled) return;
    
    try {
      // Start fade out of current track
      await _fadeOutMusic();
      
      // Wait a moment then start new track with fade in
      await Future.delayed(const Duration(milliseconds: 200));
      await playMusic(newTrackName, fadeIn: true);
      
      developer.log('Cross-faded to: $newTrackName', name: 'AudioService');
      
    } catch (e) {
      developer.log('Failed to cross-fade music: $e', name: 'AudioService');
    }
  }

  // ========================================
  // UTILITY METHODS
  // ========================================

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