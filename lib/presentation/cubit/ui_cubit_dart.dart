import 'dart:async';
import 'dart:developer' as developer;
import 'package:bloc/bloc.dart';
import 'package:puzzle_box/core/services/audio_service.dart';
import 'package:puzzle_box/core/services/storage_service.dart';
import 'package:puzzle_box/core/constants/app_constants.dart';
import 'package:puzzle_box/core/state/ui_state.dart';
import 'package:puzzle_box/domain/entities/achievement_entity.dart';

/// UICubit manages global UI state, navigation, settings, and user preferences.
/// Handles app-wide UI behavior, theme, audio settings, and navigation flow.
/// Follows Clean Architecture with proper state management.
class UICubit extends Cubit<UIState> {
  final AudioService _audioService;
  final StorageService _storageService;
  
  // Timers for UI management
  Timer? _notificationTimer;
  Timer? _autoHideTimer;

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
  void showGameOverOverlay({Map<String, dynamic>? gameResults}) {
    emit(state.copyWith(
      showGameOverOverlay: true,
      overlayType: OverlayType.gameOver,
      gameOverResults: gameResults,
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

  // ========================================
  // LOADING STATE MANAGEMENT
  // ========================================

  /// Show loading indicator
  void showLoading({String? message}) {
    emit(state.copyWith(
      isLoading: true,
      loadingMessage: message ?? 'Loading...',
    ));
  }

  /// Hide loading indicator
  void hideLoading() {
    emit(state.copyWith(
      isLoading: false,
      loadingMessage: null,
    ));
  }

  // ========================================
  // ERROR HANDLING
  // ========================================

  /// Show error message
  void showError(String message) {
    emit(state.copyWith(
      hasError: true,
      errorMessage: message,
    ));
    
    // Auto-hide error after 5 seconds
    _autoHideTimer?.cancel();
    _autoHideTimer = Timer(const Duration(seconds: 5), hideError);
  }

  /// Hide error message
  void hideError() {
    _autoHideTimer?.cancel();
    emit(state.copyWith(
      hasError: false,
      errorMessage: null,
    ));
  }

  // ========================================
  // NOTIFICATION MANAGEMENT
  // ========================================

  /// Show achievement notification
  void showAchievementNotification() {
    emit(state.copyWith(
      showAchievementNotification: true,
    ));
    
    // Auto-hide after 3 seconds
    _notificationTimer?.cancel();
    _notificationTimer = Timer(const Duration(seconds: 3), hideAchievementNotification);
  }

  /// Hide achievement notification
  void hideAchievementNotification() {
    _notificationTimer?.cancel();
    emit(state.copyWith(
      showAchievementNotification: false,
    ));
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
  Future<void> setSoundVolume(double volume) async {
    try {
      final clampedVolume = volume.clamp(0.0, 1.0);
      emit(state.copyWith(soundVolume: clampedVolume));
      
      await _audioService.setSfxVolume(clampedVolume);
      await _saveUserPreferences();
      
      developer.log('Sound volume set: $clampedVolume', name: 'UICubit');
    } catch (e) {
      developer.log('Failed to set sound volume: $e', name: 'UICubit');
      showError('Failed to adjust sound volume');
    }
  }

  // ========================================
  // OTHER SETTINGS
  // ========================================

  /// Toggle haptic feedback
  Future<void> toggleHaptics() async {
    try {
      final newValue = !state.hapticsEnabled;
      emit(state.copyWith(hapticsEnabled: newValue));
      
      // Provide haptic feedback if enabling
      if (newValue) {
        await _audioService.vibrate();
      }
      
      await _saveUserPreferences();
      developer.log('Haptics toggled: $newValue', name: 'UICubit');
    } catch (e) {
      developer.log('Failed to toggle haptics: $e', name: 'UICubit');
      showError('Failed to toggle haptics');
    }
  }

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
      showError('Failed to toggle particles');
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

  /// Show achievement unlock
  void showAchievementUnlock(Achievement achievement) {
    try {
      showLoading();
      
      emit(state.copyWith(
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
      Future.delayed(const Duration(seconds: 3), () {
        hideLoading();
        emit(state.copyWith(pageData: {}));
      });
      
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
          musicVolume: (preferences['musicVolume'] as double?) ?? 0.7,
          soundVolume: (preferences['soundVolume'] as double?) ?? 0.8,
          currentTheme: AppTheme.values.firstWhere(
            (theme) => theme.name == (preferences['theme'] as String?),
            orElse: () => AppTheme.dark,
          ),
          currentLanguage: AppLanguage.values.firstWhere(
            (lang) => lang.name == (preferences['language'] as String?),
            orElse: () => AppLanguage.english,
          ),
          animationsEnabled: preferences['animationsEnabled'] as bool? ?? true,
          particlesEnabled: preferences['particlesEnabled'] as bool? ?? true,
          autoSaveEnabled: preferences['autoSaveEnabled'] as bool? ?? true,
        ));
      }
      
      developer.log('User preferences loaded', name: 'UICubit');
    } catch (e) {
      developer.log('Failed to load user preferences: $e', name: 'UICubit');
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
        'soundVolume': state.soundVolume,
        'theme': state.currentTheme.name,
        'language': state.currentLanguage.name,
        'animationsEnabled': state.animationsEnabled,
        'particlesEnabled': state.particlesEnabled,
        'autoSaveEnabled': state.autoSaveEnabled,
      };
      
      await _storageService.saveUserPreferences(preferences);
      developer.log('User preferences saved', name: 'UICubit');
    } catch (e) {
      developer.log('Failed to save user preferences: $e', name: 'UICubit');
    }
  }
}