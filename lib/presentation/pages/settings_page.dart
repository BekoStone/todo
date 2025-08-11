import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:puzzle_box/core/state/player_state.dart';
import 'package:puzzle_box/core/state/ui_state.dart';
import 'package:puzzle_box/presentation/cubit/player_cubit.dart';
import 'package:puzzle_box/presentation/cubit/ui_cubit.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/colors.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with TickerProviderStateMixin {
  
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
  }

  void _startAnimations() {
    _slideController.forward();
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
              
              // Settings content
              Expanded(
                child: SlideTransition(
                  position: _slideAnimation,
                  child: _buildSettingsContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Back button
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () => context.read<UICubit>().goBack(),
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Title
          const Expanded(
            child: Text(
              'Settings',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          
          // Reset button
          Container(
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha:0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: _showResetConfirmation,
              icon: const Icon(
                Icons.refresh_rounded,
                color: AppColors.error,
              ),
              tooltip: 'Reset All Data',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Audio Settings
          _buildAudioSection(),
          
          const SizedBox(height: 32),
          
          // Gameplay Settings
          _buildGameplaySection(),
          
          const SizedBox(height: 32),
          
          // Visual Settings
          _buildVisualSection(),
          
          const SizedBox(height: 32),
          
          // Data & Storage
          _buildDataSection(),
          
          const SizedBox(height: 32),
          
          // About
          _buildAboutSection(),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildAudioSection() {
    return BlocBuilder<UICubit, UIState>(
      builder: (context, state) {
        return _buildSection(
          'Audio',
          Icons.volume_up_rounded,
          [
            _buildSwitchTile(
              'Music',
              'Background music and ambient sounds',
              Icons.music_note_rounded,
              state.musicEnabled,
              (value) {
                context.read<UICubit>().toggleMusic();
              },
            ),
            _buildVolumeSlider(
              'Music Volume',
              Icons.music_note_rounded,
              state.musicVolume,
              state.musicEnabled,
              (value) {
                context.read<UICubit>().setMusicVolume(value);
              },
            ),
            _buildSwitchTile(
              'Sound Effects',
              'UI sounds and game effects',
              Icons.audiotrack_rounded,
              state.soundEnabled,
              (value) {
                context.read<UICubit>().toggleSound();
              },
            ),
            _buildVolumeSlider(
              'Sound Volume',
              Icons.audiotrack_rounded,
              state.soundVolume,
              state.soundEnabled,
              (value) {
                context.read<UICubit>().setSoundVolume(value);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildGameplaySection() {
    return BlocBuilder<UICubit, UIState>(
      builder: (context, state) {
        return _buildSection(
          'Gameplay',
          Icons.sports_esports_rounded,
          [
            _buildSwitchTile(
              'Haptic Feedback',
              'Vibration for game interactions',
              Icons.vibration_rounded,
              state.hapticsEnabled,
              (value) {
                context.read<UICubit>().toggleHaptics();
              },
            ),
            _buildSwitchTile(
              'Auto-Save',
              'Automatically save game progress',
              Icons.save_rounded,
              state.autoSaveEnabled,
              (value) {
                context.read<UICubit>().toggleAutoSave();
              },
            ),
            _buildListTile(
              'Tutorial',
              'Learn how to play the game',
              Icons.school_rounded,
              () => _showTutorial(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildVisualSection() {
    return BlocBuilder<UICubit, UIState>(
      builder: (context, state) {
        return _buildSection(
          'Visual',
          Icons.palette_rounded,
          [
            _buildSwitchTile(
              'Animations',
              'Enable smooth animations and transitions',
              Icons.animation_rounded,
              state.animationsEnabled,
              (value) {
                context.read<UICubit>().toggleAnimations();
              },
            ),
            _buildSwitchTile(
              'Particle Effects',
              'Visual effects for gameplay actions',
              Icons.auto_awesome_rounded,
              state.particlesEnabled,
              (value) {
                context.read<UICubit>().toggleParticles();
              },
            ),
            _buildListTile(
              'Theme',
              'Dark theme (Light theme coming soon)',
              Icons.dark_mode_rounded,
              () => _showThemeOptions(),
            ),
            _buildListTile(
              'Performance Mode',
              _getPerformanceModeDescription(state.performanceMode),
              Icons.speed_rounded,
              () => _showPerformanceModeOptions(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDataSection() {
    return BlocBuilder<PlayerCubit, PlayerState>(
      builder: (context, state) {
        return _buildSection(
          'Data & Storage',
          Icons.storage_rounded,
          [
            _buildInfoTile(
              'Games Played',
              '${state.playerStats?.totalGamesPlayed ?? 0}',
              Icons.sports_esports_rounded,
            ),
            _buildInfoTile(
              'Total Score',
              '${state.playerStats?.totalScore ?? 0}',
              Icons.emoji_events_rounded,
            ),
            _buildInfoTile(
              'Play Time',
              _formatPlayTime(state.playerStats?.totalPlayTime ?? Duration.zero),
              Icons.timer_rounded,
            ),
            _buildDangerTile(
              'Reset Progress',
              'Clear all game data',
              Icons.delete_forever_rounded,
              () => _showResetConfirmation(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAboutSection() {
    return _buildSection(
      'About',
      Icons.info_rounded,
      [
        _buildInfoTile(
          'Version',
          AppConstants.appVersion,
          Icons.app_settings_alt_rounded,
        ),
        _buildListTile(
          'Privacy Policy',
          'View our privacy policy',
          Icons.privacy_tip_rounded,
          () => _openPrivacyPolicy(),
        ),
        _buildListTile(
          'Terms of Service',
          'View terms and conditions',
          Icons.description_rounded,
          () => _openTermsOfService(),
        ),
        _buildListTile(
          'Contact Support',
          'Get help or report issues',
          Icons.support_agent_rounded,
          () => _contactSupport(),
        ),
      ],
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha:0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha:0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha:0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          
          // Section content
          ...children,
          
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: ListTile(
        leading: Icon(
          icon,
          color: AppColors.primary,
          size: 24,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withValues(alpha:0.7),
          ),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.primary,
          activeTrackColor: AppColors.primary.withValues(alpha:0.3),
          inactiveThumbColor: Colors.grey,
          inactiveTrackColor: Colors.grey.withValues(alpha:0.3),
        ),
      ),
    );
  }

  Widget _buildVolumeSlider(
    String title,
    IconData icon,
    double value,
    bool enabled,
    ValueChanged<double> onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: enabled ? AppColors.primary : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: enabled ? Colors.white : Colors.grey,
                  ),
                ),
              ),
              Text(
                '${(value * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: enabled ? Colors.white : Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: enabled ? AppColors.primary : Colors.grey,
              inactiveTrackColor: Colors.white.withValues(alpha:0.3),
              thumbColor: enabled ? AppColors.primary : Colors.grey,
              overlayColor: AppColors.primary.withValues(alpha:0.2),
              disabledActiveTrackColor: Colors.grey,
              disabledInactiveTrackColor: Colors.grey.withValues(alpha:0.3),
              disabledThumbColor: Colors.grey,
            ),
            child: Slider(
              value: value,
              onChanged: enabled ? onChanged : null,
              min: 0.0,
              max: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: ListTile(
        leading: Icon(
          icon,
          color: AppColors.primary,
          size: 24,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withValues(alpha:0.7),
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          color: Colors.white.withValues(alpha:0.5),
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildInfoTile(String title, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: ListTile(
        leading: Icon(
          icon,
          color: AppColors.info,
          size: 24,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        trailing: Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.info,
          ),
        ),
      ),
    );
  }

  Widget _buildDangerTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: ListTile(
        leading: Icon(
          icon,
          color: AppColors.error,
          size: 24,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.error,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: AppColors.error.withValues(alpha:0.7),
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          color: AppColors.error.withValues(alpha:0.5),
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }

  // Helper methods
  String _getPerformanceModeDescription(PerformanceMode mode) {
    switch (mode) {
      case PerformanceMode.quality:
        return 'Best visual quality';
      case PerformanceMode.balanced:
        return 'Balanced performance and quality';
      case PerformanceMode.performance:
        return 'Best performance';
    }
  }

  String _formatPlayTime(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  // Action handlers
  void _showTutorial() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        title: const Text(
          'Tutorial',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Tutorial feature coming soon! Learn the basics of block placement, line clearing, and power-ups.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'OK',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _showThemeOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        title: const Text(
          'Theme',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Currently using Dark theme. Light theme and custom themes coming soon!',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'OK',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _showPerformanceModeOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        title: const Text(
          'Performance Mode',
          style: TextStyle(color: Colors.white),
        ),
        content: BlocBuilder<UICubit, UIState>(
          builder: (context, state) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: PerformanceMode.values.map((mode) {
                return RadioListTile<PerformanceMode>(
                  title: Text(
                    _getPerformanceModeTitle(mode),
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    _getPerformanceModeDescription(mode),
                    style: const TextStyle(color: Colors.white70),
                  ),
                  value: mode,
                  groupValue: state.performanceMode,
                  onChanged: (value) {
                    if (value != null) {
                      context.read<UICubit>().setPerformanceMode(value);
                      Navigator.of(context).pop();
                    }
                  },
                  activeColor: AppColors.primary,
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }

  String _getPerformanceModeTitle(PerformanceMode mode) {
    switch (mode) {
      case PerformanceMode.quality:
        return 'Quality';
      case PerformanceMode.balanced:
        return 'Balanced';
      case PerformanceMode.performance:
        return 'Performance';
    }
  }

  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        title: const Text(
          'Reset All Data',
          style: TextStyle(color: AppColors.error),
        ),
        content: const Text(
          'This will permanently delete all your game progress, achievements, and settings. This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetAllData();
            },
            child: const Text(
              'Reset',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _resetAllData() async {
    try {
      await context.read<PlayerCubit>().resetPlayerData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All data has been reset'),
            backgroundColor: AppColors.success,
          ),
        );
        
        // Navigate back to main menu
        context.read<UICubit>().navigateToPage(AppPage.mainMenu);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reset data: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _openPrivacyPolicy() {
    // Implement privacy policy opening
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Privacy policy feature coming soon'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _openTermsOfService() {
    // Implement terms of service opening
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Terms of service feature coming soon'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _contactSupport() {
    // Implement support contact
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Support contact feature coming soon'),
        backgroundColor: AppColors.info,
      ),
    );
  }
}