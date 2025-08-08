import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:puzzle_box/domain/entities/achievement_entity.dart';
import 'package:puzzle_box/presentation/cubit/player_cubit_dart.dart';
import 'package:puzzle_box/presentation/widgets/common/responsive_layout_dart.dart';
import '../widgets/common/gradient_button.dart';
import '../widgets/common/animated_counter.dart';
import '../widgets/overlays/achievement_overlay.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/responsive_utils.dart';

class AchievementsPage extends StatefulWidget {
  const AchievementsPage({super.key});

  @override
  State<AchievementsPage> createState() => _AchievementsPageState();
}

class _AchievementsPageState extends State<AchievementsPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _headerAnimationController;
  late Animation<double> _headerFadeAnimation;
  late Animation<Offset> _headerSlideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadAchievements();
  }

  void _setupAnimations() {
    _tabController = TabController(length: 4, vsync: this);
    
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
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

    _headerAnimationController.forward();
  }

  void _loadAchievements() {
    context.read<PlayerCubit>().loadAchievements();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _headerAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      child: Scaffold(
        body: Container(
          decoration: AppTheme.backgroundGradient,
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildTabBar(),
                Expanded(child: _buildTabView()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _headerAnimationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _headerFadeAnimation,
          child: SlideTransition(
            position: _headerSlideAnimation,
            child: Container(
              padding: EdgeInsets.all(ResponsiveUtils.wp(4)),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back_ios_rounded),
                        iconSize: ResponsiveUtils.wp(6),
                        color: Colors.white,
                      ),
                      Expanded(
                        child: Text(
                          'Achievements',
                          style: AppTheme.headlineStyle.copyWith(
                            fontSize: ResponsiveUtils.sp(24),
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(width: ResponsiveUtils.wp(10)),
                    ],
                  ),
                  SizedBox(height: ResponsiveUtils.hp(2)),
                  BlocBuilder<PlayerCubit, PlayerState>(
                    builder: (context, state) {
                      return Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: ResponsiveUtils.wp(6),
                          vertical: ResponsiveUtils.hp(2),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(
                              'Unlocked',
                              state.unlockedAchievements.length,
                              Icons.emoji_events_rounded,
                              AppTheme.successColor,
                            ),
                            _buildStatItem(
                              'Total',
                              state.allAchievements.length,
                              Icons.flag_rounded,
                              AppTheme.primaryColor,
                            ),
                            _buildStatItem(
                              'Progress',
                              ((state.unlockedAchievements.length / 
                                state.allAchievements.length) * 100).round(),
                              Icons.trending_up_rounded,
                              AppTheme.accentColor,
                              suffix: '%',
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(
    String label,
    int value,
    IconData icon,
    Color color, {
    String suffix = '',
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: ResponsiveUtils.sp(20),
          ),
        ),
        SizedBox(height: ResponsiveUtils.hp(0.5)),
        AnimatedCounter(
          value: value,
          suffix: suffix,
          style: AppTheme.titleStyle.copyWith(
            fontSize: ResponsiveUtils.sp(16),
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppTheme.bodyStyle.copyWith(
            fontSize: ResponsiveUtils.sp(12),
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: ResponsiveUtils.wp(4)),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(4),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white60,
        labelStyle: AppTheme.bodyStyle.copyWith(
          fontSize: ResponsiveUtils.sp(12),
          fontWeight: FontWeight.w600,
        ),
        tabs: const [
          Tab(text: 'All'),
          Tab(text: 'Unlocked'),
          Tab(text: 'Locked'),
          Tab(text: 'Recent'),
        ],
      ),
    );
  }

  Widget _buildTabView() {
    return BlocBuilder<PlayerCubit, PlayerState>(
      builder: (context, state) {
        return TabBarView(
          controller: _tabController,
          children: [
            _buildAchievementsList(state.allAchievements, 'All Achievements'),
            _buildAchievementsList(state.unlockedAchievements, 'Unlocked Achievements'),
            _buildAchievementsList(
              state.allAchievements
                  .where((a) => !state.unlockedAchievements.contains(a))
                  .toList(),
              'Locked Achievements',
            ),
            _buildAchievementsList(state.recentAchievements, 'Recent Achievements'),
          ],
        );
      },
    );
  }

  Widget _buildAchievementsList(List<Achievement> achievements, String title) {
    if (achievements.isEmpty) {
      return _buildEmptyState(title);
    }

    return ListView.builder(
      padding: EdgeInsets.all(ResponsiveUtils.wp(4)),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        return _buildAchievementCard(achievements[index], index);
      },
    );
  }

  Widget _buildEmptyState(String title) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.emoji_events_outlined,
            size: ResponsiveUtils.wp(20),
            color: Colors.white30,
          ),
          SizedBox(height: ResponsiveUtils.hp(2)),
          Text(
            'No achievements yet',
            style: AppTheme.titleStyle.copyWith(
              fontSize: ResponsiveUtils.sp(18),
              color: Colors.white60,
            ),
          ),
          SizedBox(height: ResponsiveUtils.hp(1)),
          Text(
            'Keep playing to unlock achievements!',
            style: AppTheme.bodyStyle.copyWith(
              fontSize: ResponsiveUtils.sp(14),
              color: Colors.white40,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementCard(Achievement achievement, int index) {
    final isUnlocked = context
        .read<PlayerCubit>()
        .state
        .unlockedAchievements
        .contains(achievement);

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 50),
            child: Container(
              margin: EdgeInsets.only(bottom: ResponsiveUtils.hp(2)),
              padding: EdgeInsets.all(ResponsiveUtils.wp(4)),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isUnlocked
                      ? [
                          achievement.rarity.color.withOpacity(0.3),
                          achievement.rarity.color.withOpacity(0.1),
                        ]
                      : [
                          Colors.grey.withOpacity(0.2),
                          Colors.grey.withOpacity(0.1),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isUnlocked
                      ? achievement.rarity.color.withOpacity(0.5)
                      : Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: InkWell(
                onTap: () => _showAchievementDetails(achievement),
                borderRadius: BorderRadius.circular(16),
                child: Row(
                  children: [
                    _buildAchievementIcon(achievement, isUnlocked),
                    SizedBox(width: ResponsiveUtils.wp(4)),
                    Expanded(
                      child: _buildAchievementInfo(achievement, isUnlocked),
                    ),
                    if (isUnlocked) _buildAchievementReward(achievement),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAchievementIcon(Achievement achievement, bool isUnlocked) {
    return Container(
      width: ResponsiveUtils.wp(16),
      height: ResponsiveUtils.wp(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isUnlocked
              ? [
                  achievement.rarity.color,
                  achievement.rarity.color.withOpacity(0.7),
                ]
              : [
                  Colors.grey,
                  Colors.grey.withOpacity(0.7),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: isUnlocked
            ? [
                BoxShadow(
                  color: achievement.rarity.color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Center(
        child: Text(
          achievement.icon,
          style: TextStyle(
            fontSize: ResponsiveUtils.sp(24),
            color: isUnlocked ? Colors.white : Colors.white60,
          ),
        ),
      ),
    );
  }

  Widget _buildAchievementInfo(Achievement achievement, bool isUnlocked) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          achievement.title,
          style: AppTheme.titleStyle.copyWith(
            fontSize: ResponsiveUtils.sp(16),
            fontWeight: FontWeight.bold,
            color: isUnlocked ? Colors.white : Colors.white60,
          ),
        ),
        SizedBox(height: ResponsiveUtils.hp(0.5)),
        Text(
          achievement.description,
          style: AppTheme.bodyStyle.copyWith(
            fontSize: ResponsiveUtils.sp(14),
            color: isUnlocked ? Colors.white70 : Colors.white40,
          ),
        ),
        SizedBox(height: ResponsiveUtils.hp(1)),
        _buildProgressBar(achievement, isUnlocked),
      ],
    );
  }

  Widget _buildProgressBar(Achievement achievement, bool isUnlocked) {
    final progress = isUnlocked ? 1.0 : achievement.currentProgress / achievement.maxProgress;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${achievement.currentProgress}/${achievement.maxProgress}',
              style: AppTheme.bodyStyle.copyWith(
                fontSize: ResponsiveUtils.sp(12),
                color: Colors.white60,
              ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: AppTheme.bodyStyle.copyWith(
                fontSize: ResponsiveUtils.sp(12),
                color: Colors.white60,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: ResponsiveUtils.hp(0.5)),
        Container(
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isUnlocked
                      ? [achievement.rarity.color, achievement.rarity.color.withOpacity(0.7)]
                      : [Colors.grey, Colors.grey.withOpacity(0.7)],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementReward(Achievement achievement) {
    return Column(
      children: [
        if (achievement.coinReward > 0)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveUtils.wp(2),
              vertical: ResponsiveUtils.hp(0.5),
            ),
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.monetization_on_rounded,
                  color: AppTheme.accentColor,
                  size: ResponsiveUtils.sp(16),
                ),
                SizedBox(width: ResponsiveUtils.wp(1)),
                Text(
                  '${achievement.coinReward}',
                  style: AppTheme.bodyStyle.copyWith(
                    fontSize: ResponsiveUtils.sp(12),
                    color: AppTheme.accentColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _showAchievementDetails(Achievement achievement) {
    showDialog(
      context: context,
      builder: (context) => AchievementOverlay(
        achievement: achievement,
        onClaim: () {
          context.read<PlayerCubit>().claimAchievementReward(achievement.id);
          Navigator.of(context).pop();
        },
      ),
    );
  }
}