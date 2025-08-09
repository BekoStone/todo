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
import 'core/theme/app_theme.dart' hide AppTheme;

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
          
          return MaterialApp(
            title: 'Box Hooks',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.dark,
            
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
                  textScaler: MediaQuery.of(context).textScaler.clamp(
                    minScaleFactor: 0.85,
                    maxScaleFactor: 1.3,
                  ),
                ),
                child: child!,
              );
            },
            
            // Global navigation observer
            navigatorObservers: [
              AppNavigatorObserver(),
            ],
            
            // Routes for proper navigation
            routes: {
              '/': (context) => const AppNavigator(),
              '/menu': (context) => const MainMenuPage(),
              '/game': (context) => const GamePage(),
              '/settings': (context) => const SettingsPage(),
            },
          );
        },
      ),
    );
  }

  /// Handle global UI state changes
  void _handleGlobalUIChanges(BuildContext context, UIState state) {
    // Handle global errors
    if (state.hasError && state.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.errorMessage!),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          action: SnackBarAction(
            label: 'Dismiss',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
    
    // Handle achievement notifications
    if (state.hasUnseenAchievements) {
      _showAchievementNotification(context);
    }
  }

  /// Show achievement notification overlay
  void _showAchievementNotification(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const AchievementNotificationDialog(),
    );
  }
}

/// Main app navigator that handles page routing based on state
class AppNavigator extends StatelessWidget {
  const AppNavigator({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UICubit, UIState>(
      builder: (context, uiState) {
        switch (uiState.currentPage) {
          case AppPage.splash:
            return const SplashPage();
          case AppPage.mainMenu:
            return const MainMenuPage();
          case AppPage.game:
            return const GamePage();
          case AppPage.settings:
            return const SettingsPage();
          default:
            return const SplashPage();
        }
      },
    );
  }
}

/// Achievement notification dialog
class AchievementNotificationDialog extends StatelessWidget {
  const AchievementNotificationDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF4ECDC4),
              Color(0xFF44A08D),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.emoji_events,
              color: Colors.white,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'Achievement Unlocked!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Check your profile to see your new achievement.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Awesome!',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Navigator observer for debugging and analytics
class AppNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    debugPrint('📱 Navigation: Pushed ${route.settings.name}');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    debugPrint('📱 Navigation: Popped ${route.settings.name}');
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    debugPrint('📱 Navigation: Replaced ${oldRoute?.settings.name} with ${newRoute?.settings.name}');
  }
}

/// Extension for easier context access to cubits
extension CubitContext on BuildContext {
  GameCubit get gameCubit => read<GameCubit>();
  PlayerCubit get playerCubit => read<PlayerCubit>();
  UICubit get uiCubit => read<UICubit>();
}

