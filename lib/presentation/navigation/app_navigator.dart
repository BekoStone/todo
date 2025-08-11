import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:puzzle_box/core/state/ui_state.dart';
import 'package:puzzle_box/presentation/cubit/ui_cubit.dart';
import 'package:puzzle_box/presentation/pages/splash_page.dart';
import 'package:puzzle_box/presentation/pages/main_menu_page.dart';
import 'package:puzzle_box/presentation/pages/game_page.dart';
import 'package:puzzle_box/presentation/pages/settings_page.dart';
import '../../core/utils/performance_utils.dart';

/// AppNavigator handles app-wide navigation and page routing.
/// Listens to UIState changes and navigates between pages accordingly.
/// Optimized for performance with proper memory management and smooth transitions.
class AppNavigator extends StatefulWidget {
  const AppNavigator({super.key});

  @override
  State<AppNavigator> createState() => _AppNavigatorState();
}

class _AppNavigatorState extends State<AppNavigator> 
    with TickerProviderStateMixin, WidgetsBindingObserver {
  
  // Animation controllers for page transitions
  late AnimationController _transitionController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  // Navigation state tracking
  AppPage? _currentPage;
  AppPage? _previousPage;
  bool _isTransitioning = false;
  
  // Performance monitoring
  DateTime? _navigationStart;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupAnimations();
    PerformanceUtils.markColdStartBegin();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _transitionController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _transitionController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _transitionController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _transitionController,
      curve: Curves.easeInOutCubic,
    ));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Handle app lifecycle changes
    switch (state) {
      case AppLifecycleState.paused:
        _handleAppPaused();
        break;
      case AppLifecycleState.resumed:
        _handleAppResumed();
        break;
      case AppLifecycleState.detached:
        _handleAppDetached();
        break;
      default:
        break;
    }
  }

  void _handleAppPaused() {
    // Auto-pause game if currently playing
    if (_currentPage == AppPage.game) {
      context.read<UICubit>().showPauseOverlay();
    }
  }

  void _handleAppResumed() {
    // Handle app resume logic
    PerformanceUtils.recordFrameTime(16.67); // Reset performance tracking
  }

  void _handleAppDetached() {
    // Clean up before app closes
    PerformanceUtils.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UICubit, UIState>(
      listener: _handleUIStateChange,
      builder: (context, uiState) {
        return AnimatedBuilder(
          animation: _transitionController,
          builder: (context, child) {
            return Stack(
              children: [
                // Current page content
                _buildCurrentPage(uiState.currentPage, uiState.navigationArguments),
                
                // Transition overlay if transitioning
                if (_isTransitioning)
                  _buildTransitionOverlay(),
              ],
            );
          },
        );
      },
    );
  }

  void _handleUIStateChange(BuildContext context, UIState state) {
    final newPage = state.currentPage;
    
    // Only navigate if page actually changed
    if (newPage != _currentPage && !_isTransitioning) {
      _navigateToPage(newPage, state.navigationArguments);
    }
  }

  Future<void> _navigateToPage(AppPage page, Map<String, dynamic>? arguments) async {
    if (_isTransitioning) return;
    
    _navigationStart = DateTime.now();
    _isTransitioning = true;
    _previousPage = _currentPage;
    _currentPage = page;
    
    // Start transition animation
    await _transitionController.forward();
    
    // Mark navigation complete
    _isTransitioning = false;
    _transitionController.reset();
    
    // Log navigation performance
    if (_navigationStart != null) {
      final duration = DateTime.now().difference(_navigationStart!);
      PerformanceUtils.recordFrameTime(duration.inMilliseconds.toDouble());
    }
    
    // Update state to reflect navigation completion
    setState(() {});
  }

  Widget _buildCurrentPage(AppPage page, Map<String, dynamic>? arguments) {
    Widget pageWidget;
    
    switch (page) {
      case AppPage.splash:
        pageWidget = const SplashPage();
        break;
        
      case AppPage.mainMenu:
        pageWidget = const MainMenuPage();
        break;
        
      case AppPage.game:
        pageWidget = GamePage(arguments: arguments);
        break;
        
      case AppPage.settings:
        pageWidget = const SettingsPage();
        break;
        
      case AppPage.achievements:
        pageWidget = _buildAchievementsPage();
        break;
        
      case AppPage.leaderboard:
        pageWidget = _buildLeaderboardPage();
        break;
        
      default:
        pageWidget = const SplashPage();
        break;
    }
    
    // Wrap in performance monitoring
    return PerformanceWidget(
      child: pageWidget,
      pageName: page.name,
    );
  }

  Widget _buildTransitionOverlay() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          color: Colors.black.withValues(alpha:0.3),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );
  }

  // Placeholder pages for future implementation
  Widget _buildAchievementsPage() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.read<UICubit>().goBack(),
        ),
      ),
      body: const Center(
        child: Text(
          'Achievements page coming soon!',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }

  Widget _buildLeaderboardPage() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.read<UICubit>().goBack(),
        ),
      ),
      body: const Center(
        child: Text(
          'Leaderboard page coming soon!',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}

/// Performance monitoring widget wrapper
class PerformanceWidget extends StatefulWidget {
  final Widget child;
  final String pageName;

  const PerformanceWidget({
    super.key,
    required this.child,
    required this.pageName,
  });

  @override
  State<PerformanceWidget> createState() => _PerformanceWidgetState();
}

class _PerformanceWidgetState extends State<PerformanceWidget> {
  DateTime? _buildStart;

  @override
  void initState() {
    super.initState();
    _buildStart = DateTime.now();
    PerformanceUtils.markPageStart(widget.pageName);
  }

  @override
  void dispose() {
    if (_buildStart != null) {
      final buildTime = DateTime.now().difference(_buildStart!);
      PerformanceUtils.recordPageBuildTime(widget.pageName, buildTime);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Navigation route information
class NavigationRoute {
  final AppPage page;
  final Map<String, dynamic>? arguments;
  final DateTime timestamp;
  final String? source;

  const NavigationRoute({
    required this.page,
    this.arguments,
    required this.timestamp,
    this.source,
  });

  @override
  String toString() {
    return 'NavigationRoute(page: ${page.name}, arguments: $arguments, timestamp: $timestamp, source: $source)';
  }
}

/// Navigation history tracker for debugging and analytics
class NavigationHistory {
  static final List<NavigationRoute> _history = [];
  static const int maxHistoryLength = 50;

  /// Add navigation event to history
  static void addNavigation(AppPage page, {Map<String, dynamic>? arguments, String? source}) {
    final route = NavigationRoute(
      page: page,
      arguments: arguments,
      timestamp: DateTime.now(),
      source: source,
    );

    _history.add(route);

    // Keep history size manageable
    if (_history.length > maxHistoryLength) {
      _history.removeAt(0);
    }
  }

  /// Get navigation history
  static List<NavigationRoute> getHistory() {
    return List.unmodifiable(_history);
  }

  /// Get last navigation
  static NavigationRoute? getLastNavigation() {
    return _history.isNotEmpty ? _history.last : null;
  }

  /// Clear navigation history
  static void clearHistory() {
    _history.clear();
  }

  /// Get navigation statistics
  static Map<String, dynamic> getStatistics() {
    final pageVisits = <String, int>{};
    int totalNavigations = _history.length;

    for (final route in _history) {
      final pageName = route.page.name;
      pageVisits[pageName] = (pageVisits[pageName] ?? 0) + 1;
    }

    return {
      'totalNavigations': totalNavigations,
      'pageVisits': pageVisits,
      'mostVisitedPage': pageVisits.isEmpty 
          ? null 
          : pageVisits.entries.reduce((a, b) => a.value > b.value ? a : b).key,
      'historyLength': _history.length,
    };
  }
}