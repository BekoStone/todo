// File: lib/presentation/cubit/ui_cubit.dart

import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:puzzle_box/core/constants/app_constants.dart';
import '../../core/services/audio_service.dart';
import '../../core/services/storage_service.dart';

/// UI theme mode
enum UIThemeMode {
  light,
  dark,
  system,
}

/// Navigation pages
enum AppPage {
  splash,
  mainMenu,
  game,
  achievements,
  settings,
  store,
}

/// UI animation state
enum AnimationState {
  idle,
  animating,
  paused,
}

/// Settings configuration
class SettingsConfig {
  final bool musicEnabled;
  final bool soundEffectsEnabled;
  final double musicVolume;
  final double sfxVolume;
  final UIThemeMode themeMode;
  final bool animationsEnabled;
  final bool hapticsEnabled;
  final bool showFPS;
  final bool reducedMotion;
  final String languageCode;

  const SettingsConfig({
    this.musicEnabled = true,
    this.soundEffectsEnabled = true,
    this.musicVolume = 0.7,
    this.sfxVolume = 0.8,
    this.themeMode = UIThemeMode.system,
    this.animationsEnabled = true,
    this.hapticsEnabled = true,
    this.showFPS = false,
    this.reducedMotion = false,
    this.languageCode = 'en',
  });

  SettingsConfig copyWith({
    bool? musicEnabled,
    bool? soundEffectsEnabled,
    double? musicVolume,
    double? sfxVolume,
    UIThemeMode? themeMode,
    bool? animationsEnabled,
    bool? hapticsEnabled,
    bool? showFPS,
    bool? reducedMotion,
    String? languageCode,
  }) {
    return SettingsConfig(
      musicEnabled: musicEnabled ?? this.musicEnabled,
      soundEffectsEnabled: soundEffectsEnabled ?? this.soundEffectsEnabled,
      musicVolume: musicVolume ?? this.musicVolume,
      sfxVolume: sfxVolume ?? this.sfxVolume,
      themeMode: themeMode ?? this.themeMode,
      animationsEnabled: animationsEnabled ?? this.animationsEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      showFPS: showFPS ?? this.showFPS,
      reducedMotion: reducedMotion ?? this.reducedMotion,
      languageCode: languageCode ?? this.languageCode,
    );
  }

  Map<String, dynamic> toMap() => {
    'musicEnabled': musicEnabled,
    'soundEffectsEnabled': soundEffectsEnabled,
    'musicVolume': musicVolume,
    'sfxVolume': sfxVolume,
    'themeMode': themeMode.name,
    'animationsEnabled': animationsEnabled,
    'hapticsEnabled': hapticsEnabled,
    'showFPS': showFPS,
    'reducedMotion': reducedMotion,
    'languageCode': languageCode,
  };

  factory SettingsConfig.fromMap(Map<String, dynamic> map) {
    return SettingsConfig(
      musicEnabled: map['musicEnabled'] ?? true,
      soundEffectsEnabled: map['soundEffectsEnabled'] ?? true,
      musicVolume: (map['musicVolume'] as num?)?.toDouble() ?? 0.7,
      sfxVolume: (map['sfxVolume'] as num?)?.toDouble() ?? 0.8,
      themeMode: UIThemeMode.values.firstWhere(
        (mode) => mode.name == map['themeMode'],
        orElse: () => UIThemeMode.system,
      ),
      animationsEnabled: map['animationsEnabled'] ?? true,
      hapticsEnabled: map['hapticsEnabled'] ?? true,
      showFPS: map['showFPS'] ?? false,
      reducedMotion: map['reducedMotion'] ?? false,
      languageCode: map['languageCode'] ?? 'en',
    );
  }
}

/// UI state
class UIState extends Equatable {
  final AppPage currentPage;
  final SettingsConfig settings;
  final AnimationState animationState;
  final bool isLoading;
  final bool showDebugInfo;
  final String? errorMessage;
  final Map<String, dynamic> pageData;
  final List<String> navigationHistory;
  final bool canGoBack;
  final double screenBrightness;
  final bool isKeyboardVisible;
  final Size? screenSize;
  final EdgeInsets? safeAreaInsets;

  const UIState({
    this.currentPage = AppPage.splash,
    this.settings = const SettingsConfig(),
    this.animationState = AnimationState.idle,
    this.isLoading = false,
    this.showDebugInfo = false,
    this.errorMessage,
    this.pageData = const {},
    this.navigationHistory = const [],
    this.canGoBack = false,
    this.screenBrightness = 1.0,
    this.isKeyboardVisible = false,
    this.screenSize,
    this.safeAreaInsets,
  });

  bool get isDarkMode {
    switch (settings.themeMode) {
      case UIThemeMode.light:
        return false;
      case UIThemeMode.dark:
        return true;
      case UIThemeMode.system:
        return false; // Would check system theme in practice
    }
  }

  bool get isAnimating => animationState == AnimationState.animating;
  bool get isOnGamePage => currentPage == AppPage.game;
  bool get isOnMainMenu => currentPage == AppPage.mainMenu;
  bool get hasError => errorMessage != null;

  UIState copyWith({
    AppPage? currentPage,
    SettingsConfig? settings,
    AnimationState? animationState,
    bool? isLoading,
    bool? showDebugInfo,
    String? errorMessage,
    Map<String, dynamic>? pageData,
    List<String>? navigationHistory,
    bool? canGoBack,
    double? screenBrightness,
    bool? isKeyboardVisible,
    Size? screenSize,
    EdgeInsets? safeAreaInsets,
  }) {
    return UIState(
      currentPage: currentPage ?? this.currentPage,
      settings: settings ?? this.settings,
      animationState: animationState ?? this.animationState,
      isLoading: isLoading ?? this.isLoading,
      showDebugInfo: showDebugInfo ?? this.showDebugInfo,
      errorMessage: errorMessage,
      pageData: pageData ?? this.pageData,
      navigationHistory: navigationHistory ?? this.navigationHistory,
      canGoBack: canGoBack ?? this.canGoBack,
      screenBrightness: screenBrightness ?? this.screenBrightness,
      isKeyboardVisible: isKeyboardVisible ?? this.isKeyboardVisible,
      screenSize: screenSize ?? this.screenSize,
      safeAreaInsets: safeAreaInsets ?? this.safeAreaInsets,
    );
  }

  @override
  List<Object?> get props => [
        currentPage,
        settings,
        animationState,
        isLoading,
        showDebugInfo,
        errorMessage,
        pageData,
        navigationHistory,
        canGoBack,
        screenBrightness,
        isKeyboardVisible,
        screenSize,
        safeAreaInsets,
      ];
}

/// UI cubit for managing application UI state
class UICubit extends Cubit<UIState> {
  final AudioService _audioService;
  final StorageService _storageService;
  
  Timer? _autoSaveTimer;
  StreamSubscription? _keyboardSubscription;

  static const String _settingsKey = 'ui_settings';

  UICubit(
    this._audioService,
    this._storageService,
  ) : super(const UIState()) {
    _initializeUI();
    _startAutoSave();
  }

  /// Initialize UI system
  Future<void> _initializeUI() async {
    try {
      emit(state.copyWith(isLoading: true));

      // Load saved settings
      await _loadSettings();

      // Apply audio settings
      await _applyAudioSettings();

      emit(state.copyWith(isLoading: false));
      developer.log('UI initialized', name: 'UICubit');

    } catch (e) {
      developer.log('Failed to initialize UI: $e', name: 'UICubit');
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to initialize UI: $e',
      ));
    }
  }

  /// Navigate to a page
  void navigateToPage(AppPage page, {Map<String, dynamic>? data}) {
    try {
      final newHistory = List<String>.from(state.navigationHistory);
      newHistory.add(state.currentPage.name);
      
      // Limit history size
      if (newHistory.length > 10) {
        newHistory.removeAt(0);
      }

      emit(state.copyWith(
        currentPage: page,
        pageData: data ?? {},
        navigationHistory: newHistory,
        canGoBack: newHistory.isNotEmpty,
        errorMessage: null,
      ));

      developer.log('Navigated to: ${page.name}', name: 'UICubit');

    } catch (e) {
      developer.log('Navigation failed: $e', name: 'UICubit');
    }
  }

  /// Go back to previous page
  void goBack() {
    if (!state.canGoBack || state.navigationHistory.isEmpty) return;

    try {
      final history = List<String>.from(state.navigationHistory);
      final previousPageName = history.removeLast();
      
      final previousPage = AppPage.values.firstWhere(
        (page) => page.name == previousPageName,
        orElse: () => AppPage.mainMenu,
      );

      emit(state.copyWith(
        currentPage: previousPage,
        navigationHistory: history,
        canGoBack: history.isNotEmpty,
        pageData: {},
      ));

      developer.log('Navigated back to: ${previousPage.name}', name: 'UICubit');

    } catch (e) {
      developer.log('Back navigation failed: $e', name: 'UICubit');
    }
  }

  /// Update settings
  Future<void> updateSettings(SettingsConfig newSettings) async {
    try {
      emit(state.copyWith(settings: newSettings));
      
      // Apply audio settings immediately
      await _applyAudioSettings();
      
      // Save settings
      await _saveSettings();

      developer.log('Settings updated', name: 'UICubit');

    } catch (e) {
      developer.log('Failed to update settings: $e', name: 'UICubit');
      emit(state.copyWith(errorMessage: 'Failed to update settings: $e'));
    }
  }

  /// Toggle music
  Future<void> toggleMusic() async {
    final newSettings = state.settings.copyWith(
      musicEnabled: !state.settings.musicEnabled,
    );
    await updateSettings(newSettings);
  }

  /// Toggle sound effects
  Future<void> toggleSoundEffects() async {
    final newSettings = state.settings.copyWith(
      soundEffectsEnabled: !state.settings.soundEffectsEnabled,
    );
    await updateSettings(newSettings);
  }

  /// Set music volume
  Future<void> setMusicVolume(double volume) async {
    final clampedVolume = volume.clamp(0.0, 1.0);
    final newSettings = state.settings.copyWith(musicVolume: clampedVolume);
    await updateSettings(newSettings);
  }

  /// Set SFX volume
  Future<void> setSFXVolume(double volume) async {
    final clampedVolume = volume.clamp(0.0, 1.0);
    final newSettings = state.settings.copyWith(sfxVolume: clampedVolume);
    await updateSettings(newSettings);
  }

  /// Toggle theme mode
  Future<void> toggleThemeMode() async {
    final currentMode = state.settings.themeMode;
    final newMode = switch (currentMode) {
      UIThemeMode.light => UIThemeMode.dark,
      UIThemeMode.dark => UIThemeMode.system,
      UIThemeMode.system => UIThemeMode.light,
    };
    
    final newSettings = state.settings.copyWith(themeMode: newMode);
    await updateSettings(newSettings);
  }

  /// Toggle animations
  Future<void> toggleAnimations() async {
    final newSettings = state.settings.copyWith(
      animationsEnabled: !state.settings.animationsEnabled,
    );
    await updateSettings(newSettings);
  }

  /// Toggle haptics
  Future<void> toggleHaptics() async {
    final newSettings = state.settings.copyWith(
      hapticsEnabled: !state.settings.hapticsEnabled,
    );
    await updateSettings(newSettings);
  }

  /// Set animation state
  void setAnimationState(AnimationState animationState) {
    emit(state.copyWith(animationState: animationState));
  }

  /// Show loading
  void showLoading() {
    emit(state.copyWith(isLoading: true));
  }

  /// Hide loading
  void hideLoading() {
    emit(state.copyWith(isLoading: false));
  }

  /// Show error
  void showError(String error) {
    emit(state.copyWith(errorMessage: error));
  }

  /// Clear error
  void clearError() {
    emit(state.copyWith(errorMessage: null));
  }

  /// Toggle debug info
  void toggleDebugInfo() {
    emit(state.copyWith(showDebugInfo: !state.showDebugInfo));
  }

  /// Update screen info
  void updateScreenInfo({
    Size? screenSize,
    EdgeInsets? safeAreaInsets,
    bool? isKeyboardVisible,
  }) {
    emit(state.copyWith(
      screenSize: screenSize ?? state.screenSize,
      safeAreaInsets: safeAreaInsets ?? state.safeAreaInsets,
      isKeyboardVisible: isKeyboardVisible ?? state.isKeyboardVisible,
    ));
  }

  /// Set screen brightness
  Future<void> setScreenBrightness(double brightness) async {
    final clampedBrightness = brightness.clamp(0.0, 1.0);
    emit(state.copyWith(screenBrightness: clampedBrightness));
    
    // In a real implementation, you would set system brightness here
    developer.log('Screen brightness set to: $clampedBrightness', name: 'UICubit');
  }

  /// Reset to default settings
  Future<void> resetToDefaults() async {
    try {
      const defaultSettings = SettingsConfig();
      await updateSettings(defaultSettings);
      developer.log('Settings reset to defaults', name: 'UICubit');
    } catch (e) {
      developer.log('Failed to reset settings: $e', name: 'UICubit');
    }
  }

  /// Load settings from storage
  Future<void> _loadSettings() async {
    try {
      final settingsData = await _storageService.getString(_settingsKey);
      if (settingsData != null) {
        final settingsMap = Map<String, dynamic>.from(
          // In practice, you'd parse JSON here
          {},
        );
        final settings = SettingsConfig.fromMap(settingsMap);
        emit(state.copyWith(settings: settings));
      }
    } catch (e) {
      developer.log('Failed to load settings: $e', name: 'UICubit');
    }
  }

  /// Save settings to storage
  Future<void> _saveSettings() async {
    try {
      final settingsMap = state.settings.toMap();
      // In practice, you'd convert to JSON here
      await _storageService.setString(_settingsKey, settingsMap.toString());
    } catch (e) {
      developer.log('Failed to save settings: $e', name: 'UICubit');
    }
  }

  /// Apply audio settings
  Future<void> _applyAudioSettings() async {
    try {
      // ignore: await_only_futures
      await _audioService.setMusicEnabled(state.settings.musicEnabled);
      await _audioService.setSoundEffectsEnabled(state.settings.soundEffectsEnabled);
      await _audioService.setMusicVolume(state.settings.musicVolume);
      await _audioService.setSoundEffectsVolume(state.settings.sfxVolume);
    } catch (e) {
      developer.log('Failed to apply audio settings: $e', name: 'UICubit');
    }
  }

  /// Start auto-save timer
  void _startAutoSave() {
    _autoSaveTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _saveSettings();
    });
  }

  /// Get responsive breakpoint
  ResponsiveBreakpoint getResponsiveBreakpoint() {
    final width = state.screenSize?.width ?? 0;
    
    if (width >= 1200) return ResponsiveBreakpoint.desktop;
    if (width >= 768) return ResponsiveBreakpoint.tablet;
    return ResponsiveBreakpoint.mobile;
  }

  /// Check if device is in landscape mode
  bool get isLandscape {
    final size = state.screenSize;
    return size != null && size.width > size.height;
  }

  /// Check if device is a tablet
  bool get isTablet {
    return getResponsiveBreakpoint() == ResponsiveBreakpoint.tablet;
  }

  /// Check if device is desktop
  bool get isDesktop {
    return getResponsiveBreakpoint() == ResponsiveBreakpoint.desktop;
  }

  @override
  Future<void> close() {
    _autoSaveTimer?.cancel();
    _keyboardSubscription?.cancel();
    return super.close();
  }
}

/// Responsive breakpoints
enum ResponsiveBreakpoint {
  mobile,
  tablet,
  desktop,
}

/// UI helper extensions
extension UIStateExtensions on UIState {
  /// Get safe padding for UI elements
  EdgeInsets get safePadding {
    return safeAreaInsets ?? EdgeInsets.zero;
  }

  /// Get responsive padding based on screen size
  EdgeInsets get responsivePadding {
    final baseInsets = safePadding;
    final additionalPadding = switch (currentPage) {
      AppPage.game => const EdgeInsets.all(8.0),
      AppPage.settings => const EdgeInsets.all(16.0),
      _ => const EdgeInsets.all(12.0),
    };
    
    return EdgeInsets.only(
      left: baseInsets.left + additionalPadding.left,
      top: baseInsets.top + additionalPadding.top,
      right: baseInsets.right + additionalPadding.right,
      bottom: baseInsets.bottom + additionalPadding.bottom,
    );
  }

  /// Get animation duration based on settings
  Duration get animationDuration {
    if (!settings.animationsEnabled || settings.reducedMotion) {
      return Duration.zero;
    }
    
    return switch (animationState) {
      AnimationState.idle => AppConstants.shortAnimationDuration,
      AnimationState.animating => AppConstants.mediumAnimationDuration,
      AnimationState.paused => Duration.zero,
    };
  }
}