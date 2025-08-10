import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:puzzle_box/domain/entities/achievement_entity.dart';
import 'package:puzzle_box/core/state/player_state.dart';
import 'package:puzzle_box/presentation/cubit/player_cubit_dart.dart';
import '../widgets/common/animated_counter.dart';
import '../widgets/overlays/achievement_overlay.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/colors.dart';
import '../../core/utils/responsive_utils.dart';

class AchievementsPage extends StatefulWidget {
  const AchievementsPage({super.key});

  @override
  State<AchievementsPage> createState() => _AchievementsPageState();
}

class _AchievementsPageState extends State<AchievementsPage>
    with TickerProviderStateMixin {
  
  // Animation controllers - CRITICAL: Must be disposed properly
  late TabController _tabController;
  late AnimationController _headerAnimationController;
  late AnimationController _listAnimationController;
  late AnimationController _progressAnimationController;
  late AnimationController _filterAnimationController;
  
  // Animations
  late Animation<double> _headerFadeAnimation;
  late Animation<Offset> _headerSlideAnimation;
  late Animation<double> _listStaggerAnimation;
  late Animation<double> _progressBarAnimation;
  late Animation<double> _filterRotationAnimation;
  
  // State tracking
  bool _isDisposed = false;
  AchievementCategory _selectedCategory = AchievementCategory.all;
  bool _showUnlockedOnly = false;
  String _searchQuery = '';
  
  // Controllers
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadAchievements();
  }

  @override
  void dispose() {
    _isDisposed = true;
    
    // CRITICAL: Dispose all animation controllers to prevent memory leaks
    _tabController.dispose();
    _headerAnimationController.dispose();
    _listAnimationController.dispose();
    _progressAnimationController.dispose();
    _filterAnimationController.dispose();
    
    // Dispose text controller
    _searchController.dispose();
    
    super.dispose();
  }

  void _setupAnimations() {
    _tabController = TabController(length: 4, vsync: this);
    
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _listAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _progressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _filterAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _headerFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _headerAnimationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _headerAnimationController,
      curve: const Interval(0.2, 1.0, curve: Curves.elasticOut),
    ));
    
    _listStaggerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _listAnimationController,
      curve: Curves.easeOutCubic,
    ));
    
    _progressBarAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressAnimationController,
      curve: Curves.easeInOutCubic,
    ));
    
    _filterRotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.5,
    ).animate(CurvedAnimation(
      parent: _filterAnimationController,
      curve: Curves.easeInOut,
    ));

    // Start initial animations
    _headerAnimationController.forward();
    _listAnimationController.forward();
    _progressAnimationController.forward();
  }

  void _loadAchievements() {
    context.read<PlayerCubit>().refreshPlayerData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.darkBackground,
              AppColors.darkSurface,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),
              
              // Progress overview
              _buildProgressOverview(),
              
              // Filter and search
              _buildFilterSection(),
              
              // Achievements list
              Expanded(
                child: _buildAchievementsList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: Listenable.merge([_headerFadeAnimation, _headerSlideAnimation]),
      builder: (context, child) {
        return FadeTransition(
          opacity: _headerFadeAnimation,
          child: SlideTransition(
            position: _headerSlideAnimation,
            child: Container(
              padding: EdgeInsets.all(ResponsiveUtils.wp(4)),
              child: Row(
                children: [
                  // Back button
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back_ios_rounded,
                      color: Colors.white,
                    ),
                  ),
                  
                  // Title
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Achievements',
                          style: TextStyle(
                            fontSize: ResponsiveUtils.sp(6),
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Track your progress',
                          style: TextStyle(
                            fontSize: ResponsiveUtils.sp(3),
                            color: Colors.white.withValues(alpha:0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Achievement count badge
                  _buildAchievementBadge(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAchievementBadge() {
    return BlocBuilder<PlayerCubit, PlayerState>(
      builder: (context, playerState) {
        final unlockedCount = playerState.achievements.length;
        final totalCount = 50; // This would come from achievement service
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
            ),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Text(
            '$unlockedCount/$totalCount',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressOverview() {
    return BlocBuilder<PlayerCubit, PlayerState>(
      builder: (context, playerState) {
        final achievements = playerState.achievements;
        final totalAchievements = 50; // Would come from service
        final unlockedCount = achievements.length;
        final progressPercentage = unlockedCount / totalAchievements;
        
        return AnimatedBuilder(
          animation: _progressBarAnimation,
          builder: (context, child) {
            return Container(
              margin: EdgeInsets.symmetric(horizontal: ResponsiveUtils.wp(4)),
              padding: EdgeInsets.all(ResponsiveUtils.wp(4)),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha:0.2),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  // Progress bar
                  Row(
                    children: [
                      Text(
                        'Overall Progress',
                        style: TextStyle(
                          fontSize: ResponsiveUtils.sp(3.5),
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      AnimatedCounter(
                        count: (progressPercentage * 100 * _progressBarAnimation.value).round(),
                        duration: const Duration(milliseconds: 800),
                        style: TextStyle(
                          fontSize: ResponsiveUtils.sp(3.5),
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                        suffix: '%',
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Progress bar
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha:0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progressPercentage * _progressBarAnimation.value,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.secondary],
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Statistics
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('Unlocked', unlockedCount.toString()),
                      _buildStatItem('Remaining', (totalAchievements - unlockedCount).toString()),
                      _buildStatItem('Total Coins', '${_calculateTotalCoins(achievements)}'),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: ResponsiveUtils.sp(4),
            fontWeight: FontWeight.bold,
            color: AppColors.accent,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: ResponsiveUtils.sp(2.5),
            color: Colors.white.withValues(alpha:0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterSection() {
    return Container(
      margin: EdgeInsets.all(ResponsiveUtils.wp(4)),
      child: Column(
        children: [
          // Search bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha:0.2),
                width: 1,
              ),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search achievements...',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha:0.5)),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.white.withValues(alpha:0.5),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Filter options
          Row(
            children: [
              // Category filter
              Expanded(
                child: _buildCategoryFilter(),
              ),
              
              const SizedBox(width: 12),
              
              // Show unlocked only toggle
              _buildUnlockedToggle(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha:0.2),
          width: 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<AchievementCategory>(
          value: _selectedCategory,
          dropdownColor: AppColors.darkSurface,
          onChanged: (category) {
            if (category != null) {
              setState(() {
                _selectedCategory = category;
              });
            }
          },
          items: AchievementCategory.values.map((category) {
            return DropdownMenuItem(
              value: category,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  _getCategoryName(category),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            );
          }).toList(),
          icon: AnimatedBuilder(
            animation: _filterRotationAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _filterRotationAnimation.value * 3.14159,
                child: const Icon(
                  Icons.filter_list,
                  color: Colors.white,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildUnlockedToggle() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showUnlockedOnly = !_showUnlockedOnly;
        });
        _filterAnimationController.forward().then((_) {
          _filterAnimationController.reverse();
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _showUnlockedOnly 
              ? AppColors.primary.withValues(alpha:0.3)
              : Colors.white.withValues(alpha:0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _showUnlockedOnly 
                ? AppColors.primary
                : Colors.white.withValues(alpha:0.2),
            width: 1,
          ),
        ),
        child: Icon(
          _showUnlockedOnly ? Icons.check_box : Icons.check_box_outline_blank,
          color: _showUnlockedOnly ? AppColors.primary : Colors.white,
        ),
      ),
    );
  }

  Widget _buildAchievementsList() {
    return BlocBuilder<PlayerCubit, PlayerState>(
      builder: (context, playerState) {
        if (playerState.status == PlayerStateStatus.loading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final achievements = _filterAchievements(playerState.achievements);

        return AnimatedBuilder(
          animation: _listStaggerAnimation,
          builder: (context, child) {
            return ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.wp(4)),
              itemCount: achievements.length,
              itemBuilder: (context, index) {
                final achievement = achievements[index];
                final animationDelay = index * 0.1;
                final itemAnimation = Tween<double>(
                  begin: 0.0,
                  end: 1.0,
                ).animate(CurvedAnimation(
                  parent: _listAnimationController,
                  curve: Interval(
                    animationDelay.clamp(0.0, 0.8),
                    (animationDelay + 0.2).clamp(0.2, 1.0),
                    curve: Curves.easeOutCubic,
                  ),
                ));

                return Transform.translate(
                  offset: Offset(0, (1 - itemAnimation.value) * 50),
                  child: Opacity(
                    opacity: itemAnimation.value,
                    child: _buildAchievementCard(achievement),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildAchievementCard(Achievement achievement) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: achievement.isUnlocked
              ? [
                  AppColors.primary.withValues(alpha:0.2),
                  AppColors.secondary.withValues(alpha:0.1),
                ]
              : [
                  Colors.white.withValues(alpha:0.05),
                  Colors.white.withValues(alpha:0.02),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: achievement.isUnlocked
              ? AppColors.primary.withValues(alpha:0.3)
              : Colors.white.withValues(alpha:0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(ResponsiveUtils.wp(4)),
        child: Row(
          children: [
            // Achievement icon
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: achievement.isUnlocked
                    ? AppColors.primary.withValues(alpha:0.3)
                    : Colors.white.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                achievement.isUnlocked ? Icons.emoji_events : Icons.lock_outline,
                color: achievement.isUnlocked ? AppColors.primary : Colors.white.withValues(alpha:0.5),
                size: 24,
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Achievement details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    achievement.title,
                    style: TextStyle(
                      fontSize: ResponsiveUtils.sp(3.5),
                      fontWeight: FontWeight.bold,
                      color: achievement.isUnlocked ? Colors.white : Colors.white.withValues(alpha:0.7),
                    ),
                  ),
                  
                  const SizedBox(height: 4),
                  
                  Text(
                    achievement.description,
                    style: TextStyle(
                      fontSize: ResponsiveUtils.sp(2.8),
                      color: Colors.white.withValues(alpha:0.6),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Progress bar (if not unlocked)
                  if (!achievement.isUnlocked)
                    _buildAchievementProgress(achievement),
                ],
              ),
            ),
            
            // Reward
            if (achievement.isUnlocked)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha:0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.monetization_on,
                      color: AppColors.warning,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${achievement.coinReward}',
                      style: const TextStyle(
                        color: AppColors.warning,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementProgress(Achievement achievement) {
    final progress = achievement.progress / achievement.targetValue;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress',
              style: TextStyle(
                fontSize: ResponsiveUtils.sp(2.5),
                color: Colors.white.withValues(alpha:0.5),
              ),
            ),
            Text(
              '${achievement.progress}/${achievement.targetValue}',
              style: TextStyle(
                fontSize: ResponsiveUtils.sp(2.5),
                color: Colors.white.withValues(alpha:0.7),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 4),
        
        Container(
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha:0.2),
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Achievement> _filterAchievements(List<Achievement> achievements) {
    return achievements.where((achievement) {
      // Filter by search query
      if (_searchQuery.isNotEmpty &&
          !achievement.title.toLowerCase().contains(_searchQuery.toLowerCase()) &&
          !achievement.description.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      
      // Filter by category
      if (_selectedCategory != AchievementCategory.all &&
          achievement.category != _selectedCategory) {
        return false;
      }
      
      // Filter by unlocked status
      if (_showUnlockedOnly && !achievement.isUnlocked) {
        return false;
      }
      
      return true;
    }).toList();
  }

  String _getCategoryName(AchievementCategory category) {
    switch (category) {
      case AchievementCategory.all:
        return 'All Categories';
      case AchievementCategory.gameplay:
        return 'Gameplay';
      case AchievementCategory.progression:
        return 'Progression';
      case AchievementCategory.collection:
        return 'Collection';
      case AchievementCategory.special:
        return 'Special';
      case AchievementCategory.general:
        return 'General';
      case AchievementCategory.scoring:
        return 'Scoring';
      case AchievementCategory.mastery:
        return 'Mastery';
      case AchievementCategory.social:
        return 'Social';
      case AchievementCategory.time:
        return 'Time-Based';
    }
  }

  int _calculateTotalCoins(List<Achievement> achievements) {
    return achievements
        .where((achievement) => achievement.isUnlocked)
        .fold(0, (total, achievement) => total + achievement.coinReward);
  }
}