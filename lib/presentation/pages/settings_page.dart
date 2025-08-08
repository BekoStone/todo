import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:puzzle_box/presentation/cubit/player_cubit_dart.dart';
import 'package:puzzle_box/presentation/cubit/ui_cubit_dart.dart';
import 'package:puzzle_box/presentation/widgets/common/responsive_layout_dart.dart';
import '../widgets/common/gradient_button.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/responsive_utils.dart';
import '../../core/services/audio_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _rotationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));

    _slideController.forward();
    _rotationController.repeat();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      child: Scaffold(
        body: Container(
          decoration: AppTheme.backgroundGradient,
          child: SafeArea(
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(ResponsiveUtils.wp(4)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    SizedBox(height: ResponsiveUtils.hp(3)),
                    _buildAudioSection(),
                    SizedBox(height: ResponsiveUtils.hp(2)),
                    _buildDisplaySection(),
                    SizedBox(height: ResponsiveUtils.hp(2)),
                    _buildGameplaySection(),
                    SizedBox(height: ResponsiveUtils.hp(2)),
                    _buildDataSection(),
                    SizedBox(height: ResponsiveUtils.hp(2)),
                    _buildAboutSection(),
                    SizedBox(height: ResponsiveUtils.hp(4)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_rounded),
          iconSize: ResponsiveUtils.wp(6),
          color: Colors.white,
        ),
        Expanded(
          child: Text(
            'Settings',
            style: AppTheme.headlineStyle.copyWith(
              fontSize: ResponsiveUtils.sp(24),
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        AnimatedBuilder(
          animation: _rotationAnimation,
          builder: (context, child) {
            return Transform.rotate(
              angle: _rotationAnimation.value * 2 * 3.14159,
              child: Icon(
                Icons.settings_rounded,
                size: ResponsiveUtils.wp(6),
                color: Colors.white54,
              ),
            );
          },
        ),
      ],
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
              'Sound Effects',
              'Play sound effects during gameplay',
              Icons.music_note_rounded,
              state.soundEnabled,
              (value) {
                context.read<UICubit>().toggleSound();
                if (value) {
                  AudioService.playSfx('button_click');
                }
              },
            ),
            _buildSwitchTile(
              'Background Music',
              'Play background music',
              Icons.library_music_rounded,
              state.musicEnabled,
              (value) {
                context.read<UICubit>().toggleMusic();
                if (value) {
                  AudioService.playMusic('menu_theme');
                } else {
                  AudioService.stopMusic();
                }
              },
            ),
            _buildSliderTile(
              'Master Volume',
              'Adjust overall volume',
              Icons.volume_up_rounded,
              state.masterVolume,
              (value) {
                context.read<UICubit>().setVolume(value);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildDisplaySection() {
    return BlocBuilder<UICubit, UIState>(
      builder: (context, state) {
        return _buildSection(
          'Display',
          Icons.display_settings_rounded,
          [
            _buildSwitchTile(
              'Dark Mode',
              'Use dark theme',
              Icons.dark_mode_rounded,
              state.isDarkMode,
              (value) {
                context.read<UICubit>().toggleTheme();
              },
            ),
            _buildSwitchTile(
              'Animations',
              'Enable visual animations',
              Icons.animation_rounded,
              state.animationsEnabled,
              (value) {
                context.read<UICubit>().toggleAnimations();
              },
            ),
            _buildSwitchTile(
              'Particle Effects',
              'Show particle effects',
              Icons.auto_awesome_rounded,
              state.particleEffectsEnabled,
              (value) {
                context.read<UICubit>().toggleParticleEffects();
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
          Icons.gamepad_rounded,
          [
            _buildSwitchTile(
              'Vibration',
              'Haptic feedback on actions',
              Icons.vibration_rounded,
              state.vibrationEnabled,
              (value) {
                context.read<UICubit>().toggleVibration();
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

  Widget _buildDataSection() {
    return BlocBuilder<PlayerCubit, PlayerState>(
      builder: (context, state) {
        return _buildSection(
          'Data & Storage',
          Icons.storage_rounded,
          [
            _buildInfoTile(
              'Games Played',
              '${state.stats.gamesPlayed}',
              Icons.sports_esports_rounded,
            ),
            _buildInfoTile(
              'Total Score',
              '${state.stats.totalScore}',
              Icons.emoji_events_rounded,
            ),
            _buildInfoTile(
              'Play Time',
              _formatPlayTime(state.stats.totalPlayTime),
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
      margin: EdgeInsets.symmetric(vertical: ResponsiveUtils.hp(1)),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(ResponsiveUtils.wp(4)),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: ResponsiveUtils.sp(20),
                ),
                SizedBox(width: ResponsiveUtils.wp(3)),
                Text(
                  title,
                  style: AppTheme.titleStyle.copyWith(
                    fontSize: ResponsiveUtils.sp(18),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ...children,
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
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.wp(4),
        vertical: ResponsiveUtils.hp(1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppTheme.primaryColor,
              size: ResponsiveUtils.sp(20),
            ),
          ),
          SizedBox(width: ResponsiveUtils.wp(3)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.titleStyle.copyWith(
                    fontSize: ResponsiveUtils.sp(16),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTheme.bodyStyle.copyWith(
                    fontSize: ResponsiveUtils.sp(12),
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primaryColor,
            inactiveThumbColor: Colors.grey,
            inactiveTrackColor: Colors.grey.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderTile(
    String title,
    String subtitle,
    IconData icon,
    double value,
    ValueChanged<double> onChanged,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.wp(4),
        vertical: ResponsiveUtils.hp(1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: AppTheme.primaryColor,
                  size: ResponsiveUtils.sp(20),
                ),
              ),
              SizedBox(width: ResponsiveUtils.wp(3)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTheme.titleStyle.copyWith(
                        fontSize: ResponsiveUtils.sp(16),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: AppTheme.bodyStyle.copyWith(
                        fontSize: ResponsiveUtils.sp(12),
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${(value * 100).toInt()}%',
                style: AppTheme.bodyStyle.copyWith(
                  fontSize: ResponsiveUtils.sp(14),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppTheme.primaryColor,
              inactiveTrackColor: Colors.white.withOpacity(0.3),
              thumbColor: AppTheme.primaryColor,
              overlayColor: AppTheme.primaryColor.withOpacity(0.2),
            ),
            child: Slider(
              value: value,
              onChanged: onChanged,
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
      margin: EdgeInsets.symmetric(horizontal: ResponsiveUtils.wp(2)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppTheme.primaryColor,
            size: ResponsiveUtils.sp(20),
          ),
        ),
        title: Text(
          title,
          style: AppTheme.titleStyle.copyWith(
            fontSize: ResponsiveUtils.sp(16),
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: AppTheme.bodyStyle.copyWith(
            fontSize: ResponsiveUtils.sp(12),
            color: Colors.white70,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          color: Colors.white54,
          size: ResponsiveUtils.sp(16),
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildInfoTile(String title, String value, IconData icon) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: ResponsiveUtils.wp(2)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppTheme.primaryColor,
            size: ResponsiveUtils.sp(20),
          ),
        ),
        title: Text(
          title,
          style: AppTheme.titleStyle.copyWith(
            fontSize: ResponsiveUtils.sp(16),
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: Text(
          value,
          style: AppTheme.bodyStyle.copyWith(
            fontSize: ResponsiveUtils.sp(14),
            fontWeight: FontWeight.bold,
            color: AppTheme.accentColor,
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
      margin: EdgeInsets.symmetric(horizontal: ResponsiveUtils.wp(2)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Colors.red,
            size: ResponsiveUtils.sp(20),
          ),
        ),
        title: Text(
          title,
          style: AppTheme.titleStyle.copyWith(
            fontSize: ResponsiveUtils.sp(16),
            fontWeight: FontWeight.w600,
            color: Colors.red,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: AppTheme.bodyStyle.copyWith(
            fontSize: ResponsiveUtils.sp(12),
            color: Colors.red.withOpacity(0.7),
          ),
        ),
        trailing: Icon(
          Icons.warning_rounded,
          color: Colors.red,
          size: ResponsiveUtils.sp(16),
        ),
        onTap: onTap,
      ),
    );
  }

  String _formatPlayTime(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${mins}m';
    } else {
      return '${mins}m';
    }
  }

  void _showTutorial() {
    // TODO: Implement tutorial flow
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tutorial coming soon!'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: Row(
          children: [
            Icon(
              Icons.warning_rounded,
              color: Colors.red,
              size: ResponsiveUtils.sp(24),
            ),
            SizedBox(width: ResponsiveUtils.wp(2)),
            Text(
              'Reset Progress',
              style: AppTheme.titleStyle.copyWith(
                fontSize: ResponsiveUtils.sp(18),
                color: Colors.red,
              ),
            ),
          ],
        ),
        content: Text(
          'This will permanently delete all your game data, including:\n\n'
          '• High scores\n'
          '• Achievements\n'
          '• Statistics\n'
          '• Settings\n\n'
          'This action cannot be undone. Are you sure?',
          style: AppTheme.bodyStyle.copyWith(
            fontSize: ResponsiveUtils.sp(14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: AppTheme.bodyStyle.copyWith(
                color: Colors.white70,
              ),
            ),
          ),
          GradientButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetProgress();
            },
            gradient: LinearGradient(
              colors: [Colors.red, Colors.red.shade700],
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _resetProgress() {
    context.read<PlayerCubit>().resetProgress();
    context.read<UICubit>().resetSettings();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Progress reset successfully'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  void _openPrivacyPolicy() {
    // TODO: Implement privacy policy view
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Privacy policy coming soon!'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _openTermsOfService() {
    // TODO: Implement terms of service view
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Terms of service coming soon!'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _contactSupport() {
    // TODO: Implement support contact
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Support contact coming soon!'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }
}