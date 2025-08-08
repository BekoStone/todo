import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:puzzle_box/presentation/cubit/game_cubit_dart.dart';
import 'package:puzzle_box/presentation/cubit/player_cubit_dart.dart';
import 'package:puzzle_box/presentation/cubit/ui_cubit_dart.dart';
import 'package:puzzle_box/presentation/pages/splash_page_dart.dart';
import 'package:puzzle_box/core/utils/responsive_utils.dart';
import 'injection_container.dart' as di;
import 'core/theme/app_theme.dart';

class BoxHooksApp extends StatelessWidget {
  const BoxHooksApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // ✅ FIXED: Remove invalid method calls (.initialize(), .exportPlayerData())
        // These methods don't exist or are private, so just create the cubits cleanly
        BlocProvider<GameCubit>(
          create: (context) => di.getIt<GameCubit>(),
        ),
        BlocProvider<PlayerCubit>(
          create: (context) {
            final cubit = di.getIt<PlayerCubit>();
            // Initialize player data when cubit is created
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
          // Initialize ResponsiveUtils with context on first build
          ResponsiveUtils.initialize(context);
          
          return MaterialApp(
            title: 'Box Hooks',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.dark,
            
            // ✅ FIXED: Add proper navigation and state management
            home: BlocListener<UICubit, UIState>(
              listener: (context, state) {
                // Handle global UI state changes
                if (state.hasError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.errorMessage ?? 'An error occurred'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                }
              },
              child: const SplashPage(),
            ),
            
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: MediaQuery.of(context).textScaler.clamp(
                    minScaleFactor: 0.8,
                    maxScaleFactor: 1.4,
                  ),
                ),
                child: child!,
              );
            },
            
            // ✅ ADDED: Global navigation based on UICubit state
            navigatorObservers: [
              AppNavigatorObserver(),
            ],
          );
        },
      ),
    );
  }
}

/// Navigator observer to handle state-based navigation
class AppNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    // Log navigation for debugging
    debugPrint('📱 Navigated to: ${route.settings.name}');
  }
}

/// Extension for easier context access to cubits
extension CubitContext on BuildContext {
  GameCubit get gameCubit => read<GameCubit>();
  PlayerCubit get playerCubit => read<PlayerCubit>();
  UICubit get uiCubit => read<UICubit>();
}

/// State management initialization widget
class StateManagerInitializer extends StatefulWidget {
  final Widget child;
  
  const StateManagerInitializer({
    super.key,
    required this.child,
  });

  @override
  State<StateManagerInitializer> createState() => _StateManagerInitializerState();
}

class _StateManagerInitializerState extends State<StateManagerInitializer> {
  bool _isInitialized = false;
  String? _initializationError;

  @override
  void initState() {
    super.initState();
    _initializeStateManagement();
  }

  Future<void> _initializeStateManagement() async {
    try {
      // Initialize state management
      await di.initializeStateManagement();
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _initializationError = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_initializationError != null) {
      return MaterialApp(
        home: Scaffold(
          backgroundColor: AppTheme.errorColor,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.white,
                  size: 64,
                ),
                const SizedBox(height: 16),
                const Text(
                  'State Management Error',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _initializationError!,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _initializationError = null;
                    });
                    _initializeStateManagement();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return MaterialApp(
        home: Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Initializing State Management...',
                  style: AppTheme.bodyStyle,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return widget.child;
  }
}