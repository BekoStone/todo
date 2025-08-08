import 'package:flutter/foundation.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:puzzle_box/core/constants/app_constants.dart';
import '../constants/asset_constants.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();
  
  bool _musicEnabled = true;
  bool _sfxEnabled = true;
  double _musicVolume = AppConstants.defaultMusicVolume;
  double _sfxVolume = AppConstants.defaultSfxVolume;
  
  String? _currentMusic;
  final Map<String, DateTime> _lastPlayed = {};
  final Set<String> _preloadedSounds = {};
  
  // Getters
  bool get isMusicEnabled => _musicEnabled;
  bool get isSfxEnabled => _sfxEnabled;
  double get musicVolume => _musicVolume;
  double get sfxVolume => _sfxVolume;
  String? get currentMusic => _currentMusic;
  
  Future<void> initialize() async {
    try {
      // Preload critical sound effects
      for (final sound in AssetConstants.criticalSounds) {
        await _preloadSfx(sound);
      }
      
      if (AppConstants.enableDebugLogging) {
        debugPrint('🔊 Audio service initialized');
      }
    } catch (e) {
      debugPrint('❌ Audio service initialization failed: $e');
    }
  }
  
  Future<void> _preloadSfx(String assetPath) async {
    try {
      await FlameAudio.audioCache.load(assetPath);
      _preloadedSounds.add(assetPath);
    } catch (e) {
      debugPrint('❌ Failed to preload SFX $assetPath: $e');
    }
  }
  
  // Music Control
  Future<void> playMusic(String assetPath, {bool restart = false}) async {
    if (!_musicEnabled) return;
    
    try {
      // Don't restart if same music is already playing
      if (_currentMusic == assetPath && !restart) return;
      
      FlameAudio.bgm.stop();
      await FlameAudio.bgm.play(assetPath, volume: _musicVolume);
      _currentMusic = assetPath;
      
      if (AppConstants.enableDebugLogging) {
        debugPrint('🎵 Playing music: $assetPath');
      }
    } catch (e) {
      debugPrint('❌ Failed to play music $assetPath: $e');
    }
  }
  
  Future<void> stopMusic() async {
    try {
      FlameAudio.bgm.stop();
      _currentMusic = null;
      
      if (AppConstants.enableDebugLogging) {
        debugPrint('🎵 Music stopped');
      }
    } catch (e) {
      debugPrint('❌ Failed to stop music: $e');
    }
  }
  
  Future<void> pauseMusic() async {
    try {
      FlameAudio.bgm.pause();
      
      if (AppConstants.enableDebugLogging) {
        debugPrint('⏸️ Music paused');
      }
    } catch (e) {
      debugPrint('❌ Failed to pause music: $e');
    }
  }
  
  Future<void> resumeMusic() async {
    if (!_musicEnabled) return;
    
    try {
      FlameAudio.bgm.resume();
      
      if (AppConstants.enableDebugLogging) {
        debugPrint('▶️ Music resumed');
      }
    } catch (e) {
      debugPrint('❌ Failed to resume music: $e');
    }
  }
  
  // SFX Control with throttling
  Future<void> playSfx(String assetPath, {double? volume}) async {
    if (!_sfxEnabled) return;
    
    // Throttle rapid repeated sounds
    final now = DateTime.now();
    final lastPlayed = _lastPlayed[assetPath];
    if (lastPlayed != null && now.difference(lastPlayed).inMilliseconds < 100) {
      return; // Skip if played within last 100ms
    }
    _lastPlayed[assetPath] = now;
    
    try {
      await FlameAudio.play(assetPath, volume: volume ?? _sfxVolume);
      
      if (AppConstants.enableDebugLogging) {
        debugPrint('🔊 Played SFX: $assetPath');
      }
    } catch (e) {
      debugPrint('❌ Failed to play SFX $assetPath: $e');
    }
  }
  
  // Volume Control
  Future<void> setMusicVolume(double volume) async {
    _musicVolume = volume.clamp(0.0, 1.0);
    
    if (AppConstants.enableDebugLogging) {
      debugPrint('🎵 Music volume: ${(_musicVolume * 100).round()}%');
    }
  }
  
  Future<void> setSfxVolume(double volume) async {
    _sfxVolume = volume.clamp(0.0, 1.0);
    
    if (AppConstants.enableDebugLogging) {
      debugPrint('🔊 SFX volume: ${(_sfxVolume * 100).round()}%');
    }
  }
  
  // Enable/Disable Audio
  void setMusicEnabled(bool enabled) {
    _musicEnabled = enabled;
    
    if (!enabled) {
      stopMusic();
    }
    
    if (AppConstants.enableDebugLogging) {
      debugPrint('🎵 Music ${enabled ? "enabled" : "disabled"}');
    }
  }
  
  void setSfxEnabled(bool enabled) {
    _sfxEnabled = enabled;
    
    if (AppConstants.enableDebugLogging) {
      debugPrint('🔊 SFX ${enabled ? "enabled" : "disabled"}');
    }
  }
  
  // Convenience methods for common sounds
  void playButtonClick() => playSfx(AssetConstants.sfxButton);
  void playBlockDrop() => playSfx(AssetConstants.sfxDrop);
  void playLineClear() => playSfx(AssetConstants.sfxClear);
  void playCombo() => playSfx(AssetConstants.sfxCombo);
  void playPerfectClear() => playSfx(AssetConstants.sfxPerfect);
  void playError() => playSfx(AssetConstants.sfxError);
  void playReward() => playSfx(AssetConstants.sfxReward);
  void playWin() => playSfx(AssetConstants.sfxWin);
  void playLose() => playSfx(AssetConstants.sfxLose);
  
  // Game state music
  void playMenuMusic() => playMusic(AssetConstants.musicMenu);
  void playGameMusic() => playMusic(AssetConstants.musicGame);
  void playGameOverMusic() => playMusic(AssetConstants.musicGameOver);
  
  // Cleanup
  Future<void> dispose() async {
    try {
      FlameAudio.bgm.stop();
      _preloadedSounds.clear();
      
      if (AppConstants.enableDebugLogging) {
        debugPrint('🔊 Audio service disposed');
      }
    } catch (e) {
      debugPrint('❌ Audio service disposal failed: $e');
    }
  }
  
  // Get audio settings for persistence
  Map<String, dynamic> getSettings() {
    return {
      'musicEnabled': _musicEnabled,
      'sfxEnabled': _sfxEnabled,
      'musicVolume': _musicVolume,
      'sfxVolume': _sfxVolume,
    };
  }
  
  // Load audio settings from persistence
  void loadSettings(Map<String, dynamic> settings) {
    _musicEnabled = settings['musicEnabled'] ?? true;
    _sfxEnabled = settings['sfxEnabled'] ?? true;
    _musicVolume = settings['musicVolume'] ?? AppConstants.defaultMusicVolume;
    _sfxVolume = settings['sfxVolume'] ?? AppConstants.defaultSfxVolume;
    
    if (AppConstants.enableDebugLogging) {
      debugPrint('🔊 Audio settings loaded');
    }
  }
}