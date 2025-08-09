import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:puzzle_box/core/state/ui_state.dart';
import 'package:puzzle_box/presentation/cubit/game_cubit_dart.dart';
import 'package:puzzle_box/presentation/cubit/player_cubit_dart.dart';
import 'package:puzzle_box/presentation/cubit/ui_cubit_dart.dart';
import 'package:puzzle_box/presentation/pages/game_page_dart.dart';
import 'package:puzzle_box/presentation/pages/main_menu_page_dart.dart';
import 'package:puzzle_box/presentation/pages/settings_page.dart';
import 'package:puzzle_box/core/utils/responsive_utils.dart';
import 'package:puzzle_box/presentation/pages/splash_page_dart.dart';
import 'injection_container.dart' as di;
import 'core/theme/colors.dart';

class BoxHooksApp extends StatelessWidget {
  const BoxHooksApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<GameCubit>(
          create: (context) => di.getIt<GameCubit>(),
        ),
        BlocProvider<PlayerCubit>(
          create: (context) {
            final cubit = di.getIt<PlayerCubit>();
            // Initialize player data asynchronously
            cubit.initializePlayer();
            return cubit;
          },
        ),
        BlocProvider<UICubit>(
          create: (context) => di.getIt<UICubit>(),
        ),
      ],
      child: Builder(
        builder: (context) {
          // Initialize ResponsiveUtils with context
          ResponsiveUtils.initialize(context);
          
          return BlocBuilder<UICubit, UIState>(
            builder: (context, uiState) {
              return MaterialApp(
                title: 'Box Hooks',
                debugShowCheckedModeBanner: false,
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: _getThemeMode(uiState.currentTheme),
                
                // Navigation handling based on UI state
                home: BlocListener<UICubit, UIState>(
                  listener: (context, state) {
                    _handleGlobalUIChanges(context, state);
                  },
                  child: const AppNavigator(),
                ),
                
                // Global text scaling constraints for better UX
                builder: (context, child) {
                  return MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      textScaleFactor: MediaQuery.of(context)
                          .textScaleFactor
                          .clamp(0.8, 1.3), // Limit text scaling
                    ),
                    child: child!,
                  );
                },
                
                // Error handling for routing
                onUnknownRoute: (settings) {
                  return MaterialPageRoute(
                    builder: (context) => const MainMenuPage(),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  ThemeMode _getThemeMode(AppTheme theme) {
    switch (theme) {
      case AppTheme.light:
        return ThemeMode.light;
      case AppTheme.dark:
        return ThemeMode.dark;
      case AppTheme.system:
        return ThemeMode.system;
    }
  }

  void _handleGlobalUIChanges(BuildContext context, UIState state) {
    // Handle error display
    if (state.hasError && state.errorMessage != null) {
      _showErrorSnackBar(context, state.errorMessage!);
    }
    
    // Handle achievement notifications
    if (state.showAchievementNotification) {
      _showAchievementNotification(context);
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            context.read<UICubit>().hideError();
          },
        ),
      ),
    );
  }

  void _showAchievementNotification(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.emoji_events, color: AppColors.warning),
            SizedBox(width: 8),
            Text('New achievement unlocked!'),
          ],
        ),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () {
            context.read<UICubit>().navigateToPage(AppPage.achievements);
          },
        ),
      ),
    );
  }
}

/// Main app navigator that handles page switching
class AppNavigator extends StatelessWidget {
  const AppNavigator({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UICubit, UIState>(
      builder: (context, state) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
          child: _buildPageForCurrentState(state),
        );
      },
    );
  }

  Widget _buildPageForCurrentState(UIState state) {
    switch (state.currentPage) {
      case AppPage.splash:
        return const SplashPage(key: ValueKey('splash'));
      
      case AppPage.mainMenu:
        return const MainMenuPage(key: ValueKey('mainMenu'));
      
      case AppPage.game:
        return GamePage(
          key: const ValueKey('game'),
          arguments: state.navigationArguments,
        );
      
      case AppPage.settings:
        return const SettingsPage(key: ValueKey('settings'));
      
      case AppPage.achievements:
        return const AchievementsPage(key: ValueKey('achievements'));
      
      case AppPage.leaderboard:
        return const LeaderboardPage(key: ValueKey('leaderboard'));
    }
  }
}

/// Placeholder for achievements page
class AchievementsPage extends StatelessWidget {
  const AchievementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: const Text('Achievements'),
        backgroundColor: AppColors.darkSurface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.read<UICubit>().navigateToPage(AppPage.mainMenu);
          },
        ),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_rounded,
              size: 64,
              color: AppColors.warning,
            ),
            SizedBox(height: 16),
            Text(
              'Achievements',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Coming Soon!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Placeholder for leaderboard page
class LeaderboardPage extends StatelessWidget {
  const LeaderboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: const Text('Leaderboard'),
        backgroundColor: AppColors.darkSurface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.read<UICubit>().navigateToPage(AppPage.mainMenu);
          },
        ),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.leaderboard_rounded,
              size: 64,
              color: AppColors.info,
            ),
            SizedBox(height: 16),
            Text(
              'Leaderboard',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Coming Soon!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Global app theme configuration
class AppThemeConfig {
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 800);
  static const Duration shortAnimationDuration = Duration(milliseconds: 150);
  
  static const Curve animationCurve = Curves.easeInOut;
  static const Curve fastAnimationCurve = Curves.easeOut;
  static const Curve slowAnimationCurve = Curves.easeInOutCubic;
  
  // Screen breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;
  
  // Safe area padding
  static const EdgeInsets defaultPadding = EdgeInsets.all(16);
  static const EdgeInsets largePadding = EdgeInsets.all(24);
  static const EdgeInsets extraLargePadding = EdgeInsets.all(32);
  
  // Border radius
  static const double defaultBorderRadius = 12;
  static const double largeBorderRadius = 16;
  static const double extraLargeBorderRadius = 24;
}

/// Error boundary widget
class ErrorBoundary extends StatelessWidget {
  final Widget child;
  final String? errorMessage;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (errorMessage != null) {
      return Scaffold(
        backgroundColor: AppColors.darkBackground,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.error,
              ),
              const SizedBox(height: 16),
              const Text(
                'Something went wrong',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                errorMessage!,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Restart app or navigate to safe page
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const BoxHooksApp()),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Restart App'),
              ),
            ],
          ),
        ),
      );
    }

    return child;
  }
}