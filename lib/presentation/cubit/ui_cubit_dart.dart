import 'dart:async';
import 'dart:developer' as developer;
import 'package:bloc/bloc.dart';
import 'package:puzzle_box/core/services/audio_service.dart';
import 'package:puzzle_box/core/services/storage_service.dart';
import 'package:puzzle_box/core/constants/app_constants.dart';
import 'package:puzzle_box/core/state/ui_state.dart';
import 'package:puzzle_box/domain/entities/achievement_entity.dart' hide Achievement;

/// UICubit manages global UI state, navigation, settings, and user preferences.
/// Handles app-wide UI behavior, theme, audio settings, and navigation flow.
/// Follows Clean Architecture with proper state management.
class UICubit extends Cubit<UIState> {
  final AudioService _audioService;
  final StorageService _storageService;
  
  // Timers for UI management
  Timer? _notificationTimer;
  Timer? _autoHideTimer;
  Timer? _loadingTimer;

  UICubit(
    this._audioService,
    this._storageService,
  ) : super(const UIState()) {
    _initializeUICubit();
  }

  @override
  Future<void> close() async {
    _notificationTimer?.cancel();
    _autoHideTimer?.cancel();
    _loadingTimer?.cancel();
    await super.close();
  }

  /// Initialize the UI cubit
  void _initializeUICubit() {
    developer.log('UICubit initialized', name: 'UICubit');
    _loadUserPreferences();
  }

  // ========================================
  // NAVIGATION MANAGEMENT
  // ========================================

  /// Navigate to a specific page
  void navigateToPage(AppPage page, {Map<String, dynamic>? arguments}) {
    developer.log('Navigating to page: ${page.name}', name: 'UICubit');
    
    emit(state.copyWith(
      currentPage: page,
      navigationArguments: arguments,
      lastNavigationTime: DateTime.now(),
    ));
    
    // Play navigation sound
    if (state.soundEnabled) {
      _audioService.playSfx('ui_navigate');
    }
  }

  /// Go back to previous page
  void goBack() {
    final previousPage = _getPreviousPage(state.currentPage);
    if (previousPage != null) {
      navigateToPage(previousPage);
    }
  }

  /// Get appropriate previous page
  AppPage? _getPreviousPage(AppPage currentPage) {
    switch (currentPage) {
      case AppPage.game:
      case AppPage.settings:
      case AppPage.achievements:
      case AppPage.leaderboard:
        return AppPage.mainMenu;
      case AppPage.mainMenu:
        return null; // No back from main menu
      case AppPage.splash:
        return null; // No back from splash
      case AppPage.store:
        return AppPage.mainMenu; // Store goes back to main menu
    }
  }

  // ========================================
  // OVERLAY MANAGEMENT
  // ========================================

  /// Show pause overlay
  void showPauseOverlay() {
    emit(state.copyWith(
      showPauseOverlay: true,
      overlayType: OverlayType.pause,
    ));
  }

  /// Hide pause overlay
  void hidePauseOverlay() {
    emit(state.copyWith(
      showPauseOverlay: false,
      overlayType: null,
    ));
  }

  /// Show game over overlay
  void showGameOverOverlay({Map<String, dynamic>? gameOverData}) {
    emit(state.copyWith(
      showGameOverOverlay: true,
      overlayType: OverlayType.gameOver,
      gameOverResults: gameOverData,
    ));
  }

  /// Hide game over overlay
  void hideGameOverOverlay() {
    emit(state.copyWith(
      showGameOverOverlay: false,
      overlayType: null,
      gameOverResults: null,
    ));
  }

  /// Show settings overlay
  void showSettingsOverlay() {
    emit(state.copyWith(
      showSettingsOverlay: true,
      overlayType: OverlayType.settings,
    ));
  }

  /// Hide settings overlay
  void hideSettingsOverlay() {
    emit(state.copyWith(
      showSettingsOverlay: false,
      overlayType: null,
    ));
  }

  /// Show loading overlay
  void showLoading({String? message}) {
    emit(state.copyWith(
      isLoading: true,
      loadingMessage: message,
    ));
  }

  /// Hide loading overlay
  void hideLoading() {
    emit(state.copyWith(
      isLoading: false,
      loadingMessage: null,
    ));
  }

  /// Show achievement notification
  void showAchievementNotification({Achievement? achievement}) {
    emit(state.copyWith(
      showAchievementNotification: true,
      currentAchievement: achievement,
    ));
    
    // Auto-hide after delay
    _notificationTimer?.cancel();
    _notificationTimer = Timer(const Duration(seconds: 5), () {
      hideAchievementNotification();
    });
  }

  /// Hide achievement notification
  void hideAchievementNotification() {
    emit(state.copyWith(
      showAchievementNotification: false,
      currentAchievement: null,
    ));
    _notificationTimer?.cancel();
  }

  // ========================================
  // NOTIFICATION MANAGEMENT
  // ========================================

  /// Show error message
  void showError(String message, {ErrorType? errorType}) {
    emit(state.copyWith(
      hasError: true,
      errorMessage: message,
      errorType: errorType ?? ErrorType.general,
    ));
    
    // Auto-hide error after delay
    _autoHideTimer?.cancel();
    _autoHideTimer = Timer(const Duration(seconds: 5), () {
      hideError();
    });
    
    // Play error sound
    if (state.soundEnabled) {
      _audioService.playSfx('ui_error');
    }
  }

  /// Hide error message
  void hideError() {
    emit(state.copyWith(
      hasError: false,
      errorMessage: null,
      errorType: null,
    ));
    _autoHideTimer?.cancel();
  }

  /// Show success message
  void showSuccess(String message) {
    emit(state.copyWith(
      hasSuccess: true,
      successMessage: message,
    ));
    
    // Auto-hide success after delay
    _autoHideTimer?.cancel();
    _autoHideTimer = Timer(const Duration(seconds: 3), () {
      hideSuccess();
    });
    
    // Play success sound
    if (state.soundEnabled) {
      _audioService.playSfx('ui_success');
    }
  }

  /// Hide success message
  void hideSuccess() {
    emit(state.copyWith(
      hasSuccess: false,
      successMessage: null,
    ));
    _autoHideTimer?.cancel();
  }

  /// Show info message
  void showInfo(String message) {
    emit(state.copyWith(
      hasInfo: true,
      infoMessage: message,
    ));
    
    // Auto-hide info after delay
    _autoHideTimer?.cancel();
    _autoHideTimer = Timer(const Duration(seconds: 4), () {
      hideInfo();
    });
  }

  /// Hide info message
  void hideInfo() {
    emit(state.copyWith(
      hasInfo: false,
      infoMessage: null,
    ));
    _autoHideTimer?.cancel();
  }

  // ========================================
  // AUDIO SETTINGS
  // ========================================

  /// Toggle music on/off
  Future<void> toggleMusic() async {
    try {
      final newValue = !state.musicEnabled;
      emit(state.copyWith(musicEnabled: newValue));
      
      if (newValue) {
        await _audioService.resumeMusic();
      } else {
        await _audioService.pauseMusic();
      }
      
      await _saveUserPreferences();
      developer.log('Music toggled: $newValue', name: 'UICubit');
    } catch (e) {
      developer.log('Failed to toggle music: $e', name: 'UICubit');
      showError('Failed to toggle music');
    }
  }

  /// Toggle sound effects on/off
  Future<void> toggleSound() async {
    try {
      final newValue = !state.soundEnabled;
      emit(state.copyWith(soundEnabled: newValue));
      
      // Play confirmation sound if enabling
      if (newValue) {
        await _audioService.playSfx('ui_toggle');
      }
      
      await _saveUserPreferences();
      developer.log('Sound toggled: $newValue', name: 'UICubit');
    } catch (e) {
      developer.log('Failed to toggle sound: $e', name: 'UICubit');
      showError('Failed to toggle sound');
    }
  }

  /// Set music volume
  Future<void> setMusicVolume(double volume) async {
    try {
      final clampedVolume = volume.clamp(0.0, 1.0);
      emit(state.copyWith(musicVolume: clampedVolume));
      
      await _audioService.setMusicVolume(clampedVolume);
      await _saveUserPreferences();
      
      developer.log('Music volume set: $clampedVolume', name: 'UICubit');
    } catch (e) {
      developer.log('Failed to set music volume: $e', name: 'UICubit');
      showError('Failed to adjust music volume');
    }
  }

  /// Set sound effects volume
  Future<void> setSfxVolume(double volume) async {
    try {
      final clampedVolume = volume.clamp(0.0, 1.0);
      emit(state.copyWith(sfxVolume: clampedVolume));
      
      await _audioService.setSfxVolume(clampedVolume);
      await _saveUserPreferences();
      
      developer.log('SFX volume set: $clampedVolume', name: 'UICubit');
    } catch (e) {
      developer.log('Failed to set SFX volume: $e', name: 'UICubit');
      showError('Failed to adjust sound volume');
    }
  }

  /// Toggle haptic feedback
  Future<void> toggleHaptics() async {
    try {
      final newValue = !state.hapticsEnabled;
      emit(state.copyWith(hapticsEnabled: newValue));
      
      await _saveUserPreferences();
      developer.log('Haptics toggled: $newValue', name: 'UICubit');
    } catch (e) {
      developer.log('Failed to toggle haptics: $e', name: 'UICubit');
      showError('Failed to toggle haptic feedback');
    }
  }

  // ========================================
  // GAME SETTINGS
  // ========================================

  /// Toggle auto-save
  Future<void> toggleAutoSave() async {
    try {
      final newValue = !state.autoSaveEnabled;
      emit(state.copyWith(autoSaveEnabled: newValue));
      
      await _saveUserPreferences();
      developer.log('Auto-save toggled: $newValue', name: 'UICubit');
    } catch (e) {
      developer.log('Failed to toggle auto-save: $e', name: 'UICubit');
      showError('Failed to toggle auto-save');
    }
  }

  /// Toggle animations
  Future<void> toggleAnimations() async {
    try {
      final newValue = !state.animationsEnabled;
      emit(state.copyWith(animationsEnabled: newValue));
      
      await _saveUserPreferences();
      developer.log('Animations toggled: $newValue', name: 'UICubit');
    } catch (e) {
      developer.log('Failed to toggle animations: $e', name: 'UICubit');
      showError('Failed to toggle animations');
    }
  }

  /// Toggle particles
  Future<void> toggleParticles() async {
    try {
      final newValue = !state.particlesEnabled;
      emit(state.copyWith(particlesEnabled: newValue));
      
      await _saveUserPreferences();
      developer.log('Particles toggled: $newValue', name: 'UICubit');
    } catch (e) {
      developer.log('Failed to toggle particles: $e', name: 'UICubit');
      showError('Failed to toggle particle effects');
    }
  }

  /// Set theme mode
  Future<void> setThemeMode(AppTheme theme) async {
    try {
      emit(state.copyWith(currentTheme: theme));
      await _saveUserPreferences();
      developer.log('Theme set: ${theme.name}', name: 'UICubit');
    } catch (e) {
      developer.log('Failed to set theme: $e', name: 'UICubit');
      showError('Failed to change theme');
    }
  }

  /// Toggle theme mode
  Future<void> toggleThemeMode() async {
    try {
      final newTheme = state.currentTheme == AppTheme.light 
          ? AppTheme.dark 
          : AppTheme.light;
      await setThemeMode(newTheme);
      developer.log('Theme toggled', name: 'UICubit');
    } catch (e) {
      developer.log('Failed to toggle theme: $e', name: 'UICubit');
      showError('Failed to toggle theme');
    }
  }

  // ========================================
  // ACHIEVEMENT DISPLAY
  // ========================================

  /// Show achievement unlock
  void showAchievementUnlock(Achievement achievement) {
    try {
      emit(state.copyWith(
        showAchievementNotification: true,
        currentAchievement: achievement,
        pageData: {
          'achievement_unlock': {
            'achievement_id': achievement.id,
            'title': achievement.title,
            'description': achievement.description,
            'reward_coins': achievement.coinReward,
          }
        }
      ));
      
      // Auto-hide after delay
      _notificationTimer?.cancel();
      _notificationTimer = Timer(const Duration(seconds: 5), () {
        hideAchievementNotification();
        emit(state.copyWith(pageData: {}));
      });
      
      // Play achievement sound
      if (state.soundEnabled) {
        _audioService.playAchievementSound();
      }
      
      developer.log('Achievement unlock shown: ${achievement.title}', name: 'UICubit');
    } catch (e) {
      developer.log('Failed to show achievement unlock: $e', name: 'UICubit');
    }
  }

  // ========================================
  // PERFORMANCE MANAGEMENT
  // ========================================

  /// Set performance mode
  Future<void> setPerformanceMode(PerformanceMode mode) async {
    emit(state.copyWith(performanceMode: mode));
    
    // Apply performance settings
    await _applyPerformanceSettings(mode);
    
    // Save preference
    await _saveUserPreferences();
    
    developer.log('Performance mode set to: ${mode.name}', name: 'UICubit');
  }

  /// Apply performance settings based on mode
  Future<void> _applyPerformanceSettings(PerformanceMode mode) async {
    switch (mode) {
      case PerformanceMode.quality:
        // Enable all visual effects
        emit(state.copyWith(
          particlesEnabled: true,
          animationsEnabled: true,
          shadowsEnabled: true,
        ));
        break;
      case PerformanceMode.balanced:
        // Moderate settings
        emit(state.copyWith(
          particlesEnabled: true,
          animationsEnabled: true,
          shadowsEnabled: false,
        ));
        break;
      case PerformanceMode.performance:
        // Minimal visual effects
        emit(state.copyWith(
          particlesEnabled: false,
          animationsEnabled: true,
          shadowsEnabled: false,
        ));
        break;
    }
  }

  // ========================================
  // DATA PERSISTENCE
  // ========================================

  /// Load user preferences from storage
  Future<void> _loadUserPreferences() async {
    try {
      final preferences = await _storageService.getUserPreferences();
      
      if (preferences != null) {
        emit(state.copyWith(
          musicEnabled: preferences['musicEnabled'] as bool? ?? true,
          soundEnabled: preferences['soundEnabled'] as bool? ?? true,
          hapticsEnabled: preferences['hapticsEnabled'] as bool? ?? true,
          musicVolume: (preferences['musicVolume'] as double?)?.clamp(0.0, 1.0) ?? 0.7,
          sfxVolume: (preferences['sfxVolume'] as double?)?.clamp(0.0, 1.0) ?? 0.8,
          currentTheme: AppTheme.values.firstWhere(
            (theme) => theme.name == preferences['theme'],
            orElse: () => AppTheme.dark,
          ),
          autoSaveEnabled: preferences['autoSaveEnabled'] as bool? ?? true,
          animationsEnabled: preferences['animationsEnabled'] as bool? ?? true,
          particlesEnabled: preferences['particlesEnabled'] as bool? ?? true,
          shadowsEnabled: preferences['shadowsEnabled'] as bool? ?? false,
          performanceMode: PerformanceMode.values.firstWhere(
            (mode) => mode.name == preferences['performanceMode'],
            orElse: () => PerformanceMode.balanced,
          ),
        ));
        
        developer.log('User preferences loaded', name: 'UICubit');
      }
    } catch (e) {
      developer.log('Failed to load user preferences: $e', name: 'UICubit');
      // Continue with default preferences
    }
  }

  /// Save user preferences to storage
  Future<void> _saveUserPreferences() async {
    try {
      final preferences = {
        'musicEnabled': state.musicEnabled,
        'soundEnabled': state.soundEnabled,
        'hapticsEnabled': state.hapticsEnabled,
        'musicVolume': state.musicVolume,
        'sfxVolume': state.sfxVolume,
        'theme': state.currentTheme.name,
        'autoSaveEnabled': state.autoSaveEnabled,
        'animationsEnabled': state.animationsEnabled,
        'particlesEnabled': state.particlesEnabled,
        'shadowsEnabled': state.shadowsEnabled,
        'performanceMode': state.performanceMode.name,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
      
      await _storageService.saveUserPreferences(preferences);
      developer.log('User preferences saved', name: 'UICubit');
    } catch (e) {
      developer.log('Failed to save user preferences: $e', name: 'UICubit');
    }
  }

  // ========================================
  // UTILITY METHODS
  // ========================================

  /// Reset all settings to defaults
  Future<void> resetToDefaults() async {
    try {
      emit(const UIState()); // Reset to default state
      await _saveUserPreferences();
      showSuccess('Settings reset to defaults');
      developer.log('Settings reset to defaults', name: 'UICubit');
    } catch (e) {
      developer.log('Failed to reset settings: $e', name: 'UICubit');
      showError('Failed to reset settings');
    }
  }

  /// Get current UI status
  Map<String, dynamic> getUIStatus() {
    return {
      'currentPage': state.currentPage.name,
      'musicEnabled': state.musicEnabled,
      'soundEnabled': state.soundEnabled,
      'theme': state.currentTheme.name,
      'performanceMode': state.performanceMode.name,
      'hasActiveOverlay': state.overlayType != null,
      'overlayType': state.overlayType?.name,
      'isLoading': state.isLoading,
      'hasNotifications': state.hasError || state.hasSuccess || state.hasInfo,
    };
  }
}