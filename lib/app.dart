import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:puzzle_box/core/state/ui_state.dart';
import 'package:puzzle_box/presentation/cubit/game_cubit.dart';
import 'package:puzzle_box/presentation/cubit/player_cubit.dart';
import 'package:puzzle_box/presentation/cubit/ui_cubit.dart';
import 'package:puzzle_box/core/utils/responsive_utils.dart';
import 'package:puzzle_box/presentation/navigation/app_navigator.dart';
import 'injection_container.dart' as di;
import 'core/constants/app_constants.dart';
import 'core/utils/performance_utils.dart';

/// BoxHooksApp is the root application widget.
/// Sets up global state management, theming, and navigation.
/// Optimized for 60 FPS performance with proper memory management.
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
                title: AppConstants.appName,
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
                      textScaler: TextScaler.linear(
                        MediaQuery.of(context).textScaler.scale(1.0).clamp(0.8, 1.2),
                      ),
                    ),
                    child: _wrapWithPerformanceMonitoring(child),
                  );
                },
                
                // Global navigation observer for performance tracking
                navigatorObservers: [
                  _AppNavigationObserver(),
                ],
                
                // Global shortcuts for better UX
                shortcuts: _buildShortcuts(),
                actions: _buildActions(context),
              );
            },
          );
        },
      ),
    );
  }

  /// Convert UI state theme to Flutter ThemeMode
  ThemeMode _getThemeMode(AppTheme theme) {
    switch (theme) {
      case AppTheme.light:
        return ThemeMode.light;
      case AppTheme.dark:
        return ThemeMode.dark;
      case AppTheme.auto:
        return ThemeMode.system;
    }
  }

  /// Handle global UI state changes
  void _handleGlobalUIChanges(BuildContext context, UIState state) {
    // Handle haptic feedback
    if (state.shouldHapticFeedback) {
      HapticFeedback.lightImpact();
    }

    // Handle system UI overlay changes
    if (state.currentPage == AppPage.game) {
      _setGameModeSystemUI();
    } else {
      _setNormalSystemUI();
    }

    // Handle screen orientation locks
    _handleOrientationChanges(state.currentPage);

    // Handle notification callbacks
    if (state.shouldShowNotification && state.notificationMessage != null) {
      _showGlobalNotification(context, state.notificationMessage!);
    }

    // Handle error states
    if (state.hasError && state.errorMessage != null) {
      _showGlobalError(context, state.errorMessage!);
    }
  }

  /// Set system UI for game mode (immersive)
  void _setGameModeSystemUI() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [],
    );
  }

  /// Set system UI for normal app mode
  void _setNormalSystemUI() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: SystemUiOverlay.values,
    );
  }

  /// Handle orientation changes per page
  void _handleOrientationChanges(AppPage page) {
    switch (page) {
      case AppPage.game:
        // Allow both orientations for game
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        break;
      default:
        // Prefer portrait for other pages
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
        ]);
        break;
    }
  }

  /// Show global notification
  void _showGlobalNotification(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Show global error
  void _showGlobalError(BuildContext context, String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(error)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
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

  /// Wrap child with performance monitoring overlay
  Widget _wrapWithPerformanceMonitoring(Widget? child) {
    if (child == null) return const SizedBox.shrink();
    
    if (AppConstants.enablePerformanceMonitoring) {
      return Stack(
        children: [
          child,
          Positioned(
            top: 50,
            right: 10,
            child: _PerformanceOverlay(),
          ),
        ],
      );
    }
    
    return child;
  }

  /// Build keyboard shortcuts map
  Map<ShortcutActivator, Intent> _buildShortcuts() {
    return {
      const SingleActivator(LogicalKeyboardKey.escape): const _BackIntent(),
      const SingleActivator(LogicalKeyboardKey.space): const _PauseIntent(),
      const SingleActivator(LogicalKeyboardKey.enter): const _ConfirmIntent(),
    };
  }

  /// Build action map for shortcuts
  Map<Type, Action<Intent>> _buildActions(BuildContext context) {
    return {
      _BackIntent: CallbackAction<_BackIntent>(
        onInvoke: (_) {
          context.read<UICubit>().goBack();
          return null;
        },
      ),
      _PauseIntent: CallbackAction<_PauseIntent>(
        onInvoke: (_) {
          final uiState = context.read<UICubit>().state;
          if (uiState.currentPage == AppPage.game) {
            context.read<UICubit>().showPauseOverlay();
          }
          return null;
        },
      ),
      _ConfirmIntent: CallbackAction<_ConfirmIntent>(
        onInvoke: (_) {
          // Handle enter key confirmation logic
          return null;
        },
      ),
    };
  }
}

/// Performance monitoring overlay widget
class _PerformanceOverlay extends StatefulWidget {
  @override
  State<_PerformanceOverlay> createState() => _PerformanceOverlayState();
}

class _PerformanceOverlayState extends State<_PerformanceOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final metrics = PerformanceUtils.getMetrics();
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
          if (_isExpanded) {
            _animationController.forward();
          } else {
            _animationController.reverse();
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: _isExpanded ? 200 : 60,
        height: _isExpanded ? 120 : 60,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha:0.7),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(8),
        child: _isExpanded ? _buildExpandedView(metrics) : _buildCollapsedView(metrics),
      ),
    );
  }

  Widget _buildCollapsedView(PerformanceMetrics metrics) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '${metrics.averageFPS.toStringAsFixed(0)}',
          style: TextStyle(
            color: _getFPSColor(metrics.averageFPS),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Text(
          'FPS',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedView(PerformanceMetrics metrics) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FPS: ${metrics.averageFPS.toStringAsFixed(1)}',
          style: TextStyle(
            color: _getFPSColor(metrics.averageFPS),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          'Mem: ${metrics.currentMemoryMB.toStringAsFixed(1)}MB',
          style: TextStyle(
            color: _getMemoryColor(metrics.currentMemoryMB),
            fontSize: 10,
          ),
        ),
        Text(
          'Dropped: ${metrics.droppedFrames}',
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
        if (metrics.coldStartTime != null)
          Text(
            'Cold: ${metrics.coldStartTime!.inMilliseconds}ms',
            style: const TextStyle(color: Colors.white70, fontSize: 10),
          ),
      ],
    );
  }

  Color _getFPSColor(double fps) {
    if (fps >= 55) return Colors.green;
    if (fps >= 45) return Colors.orange;
    return Colors.red;
  }

  Color _getMemoryColor(double memoryMB) {
    if (memoryMB < 100) return Colors.green;
    if (memoryMB < 150) return Colors.orange;
    return Colors.red;
  }
}

/// Navigation observer for performance tracking
class _AppNavigationObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    PerformanceUtils.recordFrameTime(16.67); // Reset frame tracking on navigation
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    PerformanceUtils.recordFrameTime(16.67); // Reset frame tracking on navigation
  }
}

/// Intent classes for keyboard shortcuts
class _BackIntent extends Intent {
  const _BackIntent();
}

class _PauseIntent extends Intent {
  const _PauseIntent();
}

class _ConfirmIntent extends Intent {
  const _ConfirmIntent();
}