import 'dart:async';
import 'dart:developer' as developer;
import 'package:bloc/bloc.dart';
import 'package:puzzle_box/core/services/audio_service.dart';
import 'package:puzzle_box/core/services/storage_service.dart';
import 'package:puzzle_box/core/constants/app_constants.dart';
import 'package:puzzle_box/core/state/ui_state.dart';


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

  /// Show achievement notification
  void showAchievementNotification({Achievement? achievement}) {
    emit(state.copyWith(
      showAchievementNotification: true,
      currentAchievement: achievement,
    ));
    
    // Auto-hide after delay
    _autoHideTimer?.cancel();
    _autoHideTimer = Timer(const Duration(seconds: 4), () {
      hideAchievementNotification();
    });
  }

  /// Hide achievement notification
  void hideAchievementNotification() {
    emit(state.copyWith(
      showAchievementNotification: false,
      currentAchievement: null,
    ));
    _autoHideTimer?.cancel();
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

  // ========================================
  // NOTIFICATION MANAGEMENT
  // ========================================

  /// Show error message
  void showError(String message, {Duration? duration}) {
    emit(state.copyWith(
      hasError: true,
      errorMessage: message,
      errorType: ErrorType.general,
    ));
    
    // Auto-clear error after duration
    final clearDuration = duration ?? const Duration(seconds: 4);
    _notificationTimer?.cancel();
    _notificationTimer = Timer(clearDuration, () {
      clearError();
    });
    
    // Play error sound
    if (state.soundEnabled) {
      _audioService.playSfx('ui_error');
    }
  }

  /// Show success message
  void showSuccess(String message, {Duration? duration}) {
    emit(state.copyWith(
      hasSuccess: true,
      successMessage: message,
    ));
    
    // Auto-clear success after duration
    final clearDuration = duration ?? const Duration(seconds: 3);
    _notificationTimer?.cancel();
    _notificationTimer = Timer(clearDuration, () {
      clearSuccess();
    });
    
    // Play success sound
    if (state.soundEnabled) {
      _audioService.playSfx('ui_success');
    }
  }

  /// Show info message
  void showInfo(String message, {Duration? duration}) {
    emit(state.copyWith(
      hasInfo: true,
      infoMessage: message,
    ));
    
    // Auto-clear info after duration
    final clearDuration = duration ?? const Duration(seconds: 3);
    _notificationTimer?.cancel();
    _notificationTimer = Timer(clearDuration, () {
      clearInfo();
    });
  }

  /// Clear error message
  void clearError() {
    emit(state.copyWith(
      hasError: false,
      errorMessage: null,
      errorType: null,
    ));
  }

  /// Clear success message
  void clearSuccess() {
    emit(state.copyWith(
      hasSuccess: false,
      successMessage: null,
    ));
  }

  /// Clear info message
  void clearInfo() {
    emit(state.copyWith(
      hasInfo: false,
      infoMessage: null,
    ));
  }

  // ========================================
  // SETTINGS MANAGEMENT
  // ========================================

  /// Toggle music on/off
  Future<void> toggleMusic() async {
    final newValue = !state.musicEnabled;
    
    emit(state.copyWith(musicEnabled: newValue));
    
    // Update audio service
    if (newValue) {
      await _audioService.resumeMusic();
    } else {
      await _audioService.pauseMusic();
    }
    
    // Save preference
    await _saveUserPreferences();
    
    developer.log('Music toggled: $newValue', name: 'UICubit');
  }

  /// Toggle sound effects on/off
  Future<void> toggleSound() async {
    final newValue = !state.soundEnabled;
    
    emit(state.copyWith(soundEnabled: newValue));
    
    // Test sound if enabling
    if (newValue) {
      _audioService.playSfx('ui_click');
    }
    
    // Save preference
    await _saveUserPreferences();
    
    developer.log('Sound toggled: $newValue', name: 'UICubit');
  }

  /// Set music volume
  Future<void> setMusicVolume(double volume) async {
    final clampedVolume = volume.clamp(0.0, 1.0);
    
    emit(state.copyWith(musicVolume: clampedVolume));
    
    // Update audio service
    await _audioService.setMusicVolume(clampedVolume);
    
    // Save preference
    await _saveUserPreferences();
  }

  /// Set sound effects volume
  Future<void> setSoundVolume(double volume) async {
    final clampedVolume = volume.clamp(0.0, 1.0);
    
    emit(state.copyWith(soundVolume: clampedVolume));
    
    // Update audio service
    await _audioService.setSfxVolume(clampedVolume);
    
    // Save preference
    await _saveUserPreferences();
  }

  /// Toggle haptic feedback
  Future<void> toggleHaptics() async {
    final newValue = !state.hapticsEnabled;
    
    emit(state.copyWith(hapticsEnabled: newValue));
    
    // Test haptic if enabling
    if (newValue) {
      // HapticFeedback.lightImpact(); // Would need import
    }
    
    // Save preference
    await _saveUserPreferences();
    
    developer.log('Haptics toggled: $newValue', name: 'UICubit');
  }

  /// Set app theme
  Future<void> setTheme(AppTheme theme) async {
    emit(state.copyWith(currentTheme: theme));
    
    // Save preference
    await _saveUserPreferences();
    
    developer.log('Theme changed to: ${theme.name}', name: 'UICubit');
  }

  /// Set app language
  Future<void> setLanguage(AppLanguage language) async {
    emit(state.copyWith(currentLanguage: language));
    
    // Save preference
    await _saveUserPreferences();
    
    developer.log('Language changed to: ${language.name}', name: 'UICubit');
  }

  // ========================================
  // TUTORIAL MANAGEMENT
  // ========================================

  /// Start tutorial
  void startTutorial() {
    emit(state.copyWith(
      showTutorial: true,
      tutorialStep: 0,
    ));
  }

  /// Next tutorial step
  void nextTutorialStep() {
    final currentStep = state.tutorialStep;
    emit(state.copyWith(tutorialStep: currentStep + 1));
    
    // Play UI sound
    if (state.soundEnabled) {
      _audioService.playSfx('ui_click');
    }
  }

  /// Previous tutorial step
  void previousTutorialStep() {
    final currentStep = state.tutorialStep;
    if (currentStep > 0) {
      emit(state.copyWith(tutorialStep: currentStep - 1));
    }
  }

  /// Complete tutorial
  Future<void> completeTutorial() async {
    emit(state.copyWith(
      showTutorial: false,
      tutorialCompleted: true,
      tutorialStep: 0,
    ));
    
    // Save completion status
    await _saveUserPreferences();
    
    // Show success
    showSuccess('Tutorial completed! You\'re ready to play!');
    
    developer.log('Tutorial completed', name: 'UICubit');
  }

  /// Skip tutorial
  Future<void> skipTutorial() async {
    emit(state.copyWith(
      showTutorial: false,
      tutorialSkipped: true,
      tutorialStep: 0,
    ));
    
    // Save skip status
    await _saveUserPreferences();
    
    developer.log('Tutorial skipped', name: 'UICubit');
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
          tutorialCompleted: preferences['tutorialCompleted'] as bool? ?? false,
          performanceMode: PerformanceMode.values.firstWhere(
            (mode) => mode.name == (preferences['performanceMode'] as String?),
            orElse: () => PerformanceMode.balanced,
          ),
        ));
        
        // Apply loaded settings
        await _audioService.setMusicVolume(state.musicVolume);
        await _audioService.setSfxVolume(state.soundVolume);
        await _applyPerformanceSettings(state.performanceMode);
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
        'tutorialCompleted': state.tutorialCompleted,
        'performanceMode': state.performanceMode.name,
        'lastSaved': DateTime.now().toIso8601String(),
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
  Future<void> resetSettings() async {
    emit(const UIState());
    
    // Reset audio service
    await _audioService.setMusicVolume(AppConstants.defaultMusicVolume);
    await _audioService.setSfxVolume(AppConstants.defaultSfxVolume);
    
    // Save reset preferences
    await _saveUserPreferences();
    
    showSuccess('Settings reset to defaults');
    
    developer.log('Settings reset to defaults', name: 'UICubit');
  }

  /// Export UI settings
  Map<String, dynamic> exportSettings() {
    return {
      'musicEnabled': state.musicEnabled,
      'soundEnabled': state.soundEnabled,
      'hapticsEnabled': state.hapticsEnabled,
      'musicVolume': state.musicVolume,
      'soundVolume': state.soundVolume,
      'theme': state.currentTheme.name,
      'language': state.currentLanguage.name,
      'performanceMode': state.performanceMode.name,
      'exportDate': DateTime.now().toIso8601String(),
    };
  }

  /// Import UI settings
  Future<void> importSettings(Map<String, dynamic> settings) async {
    try {
      emit(state.copyWith(
        musicEnabled: settings['musicEnabled'] as bool? ?? state.musicEnabled,
        soundEnabled: settings['soundEnabled'] as bool? ?? state.soundEnabled,
        hapticsEnabled: settings['hapticsEnabled'] as bool? ?? state.hapticsEnabled,
        musicVolume: (settings['musicVolume'] as double?) ?? state.musicVolume,
        soundVolume: (settings['soundVolume'] as double?) ?? state.soundVolume,
        currentTheme: AppTheme.values.firstWhere(
          (theme) => theme.name == (settings['theme'] as String?),
          orElse: () => state.currentTheme,
        ),
        currentLanguage: AppLanguage.values.firstWhere(
          (lang) => lang.name == (settings['language'] as String?),
          orElse: () => state.currentLanguage,
        ),
        performanceMode: PerformanceMode.values.firstWhere(
          (mode) => mode.name == (settings['performanceMode'] as String?),
          orElse: () => state.performanceMode,
        ),
      ));
      
      // Apply imported settings
      await _audioService.setMusicVolume(state.musicVolume);
      await _audioService.setSfxVolume(state.soundVolume);
      await _applyPerformanceSettings(state.performanceMode);
      
      // Save imported settings
      await _saveUserPreferences();
      
      showSuccess('Settings imported successfully');
      
    } catch (e) {
      showError('Failed to import settings: ${e.toString()}');
    }
  }

  // ========================================
  // CLEANUP
  // ========================================

  @override
  Future<void> close() {
    _notificationTimer?.cancel();
    _autoHideTimer?.cancel();
    return super.close();
  }
}