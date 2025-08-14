import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:puzzle_box/presentation/pages/main_menu_page.dart';
import '../../presentation/flame/box_hooks_game.dart';
import '../widgets/animated_counter.dart';
import '../game/power_up_panel.dart';
import '../../domain/entities/power_up_entity.dart';
import '../../core/constants/game_constants.dart';
import 'settings_page.dart';

class GamePage extends StatefulWidget {
  static const route = '/game';
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  late final BoxHooksGame _game;

  @override
  void initState() {
    super.initState();
    _game = BoxHooksGame();
  }

  @override
  void dispose() {
    _game.score.dispose();
    _game.gold.dispose();
    _game.gameOver.dispose();
    super.dispose();
  }

  Future<void> _handlePowerUpTap(PowerUpEntity p) async {
    final armed = _game.tryActivatePowerUp(p.type);
    if (armed) {
      setState(() {});
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Get Power-Up'),
        content: Text('Watch a short ad to get 1 ${p.type.name}? (simulated)'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Watch Ad')),
        ],
      ),
    );
    if (ok == true) {
      _game.powerUpSystem.grant(p.type, 1);
      _game.tryActivatePowerUp(p.type);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('+1 ${p.type.name} granted')));
      }
      setState(() {});
    }
  }

  void _openSettingsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return SettingsPage(
          muted: _game.muted,
          onToggleMute: (v) {
            _game.setMuted(v);
            Navigator.of(ctx).pop();
          },
          onRestart: () {
            _game.resetGame();
            Navigator.of(ctx).pop();
          },
          onMainMenu: () {
            Navigator.of(ctx).pop();
            Navigator.of(context).pushReplacementNamed(MainMenuPage.route);
          },
          onResume: () {
            Navigator.of(ctx).pop();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.of(context).viewPadding.bottom;
    return AnimatedBuilder(
      animation: Listenable.merge([_game.score, _game.gold, _game.gameOver]),
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.stars, size: 18),
                const SizedBox(width: 6),
                const Text('Score: '),
                AnimatedCounter(value: _game.score.value, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 18),
                const Icon(Icons.monetization_on, size: 18),
                const SizedBox(width: 6),
                const Text('Gold: '),
                AnimatedCounter(value: _game.gold.value, style: const TextStyle(fontSize: 18)),
              ],
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: _openSettingsSheet,
                tooltip: 'Settings',
              ),
            ],
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final screenW = constraints.maxWidth;
              final screenH = constraints.maxHeight;

              final gridW = GameConstants.gridCols * GameConstants.cellSize;
              final gridH = GameConstants.gridRows * GameConstants.cellSize;

              final gridX = ((screenW - gridW) / 2).roundToDouble() + 0.5;
              final gridY = GameConstants.topPadding;

              final panelTop = gridY + gridH + GameConstants.gridGapToPanel;
              final adTop = screenH - GameConstants.adBannerHeight - bottomSafe - GameConstants.adBottomExtraPadding;

              return Stack(
                children: [
                  Positioned.fill(child: GameWidget(game: _game)),

                  // Power-ups panel
                  Positioned(
                    left: gridX,
                    top: panelTop,
                    width: gridW,
                    height: GameConstants.panelHeight,
                    child: PowerUpPanel(
                      onUse: _handlePowerUpTap,
                      counts: _game.powerUpSystem.counts,
                    ),
                  ),

                  // Ad banner
                  Positioned(
                    left: 0,
                    right: 0,
                    top: adTop,
                    height: GameConstants.adBannerHeight + GameConstants.adBottomExtraPadding + bottomSafe,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: const [
                        _AdBannerPlaceholder(),
                        SizedBox(height: GameConstants.adBottomExtraPadding),
                      ],
                    ),
                  ),

                  // ----- GAME OVER OVERLAY -----
                  if (_game.gameOver.value)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black54,
                        child: Center(
                          child: Card(
                            margin: const EdgeInsets.all(24),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('Game Over', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 12),
                                  Text('Score: ${_game.score.value}'),
                                  const SizedBox(height: 20),
                                  Wrap(
                                    spacing: 12,
                                    children: [
                                      ElevatedButton(
                                        onPressed: _game.resetGame,
                                        child: const Text('Restart'),
                                      ),
                                      OutlinedButton(
                                        onPressed: () => Navigator.of(context).pushReplacementNamed(MainMenuPage.route),
                                        child: const Text('Main Menu'),
                                      ),
                                      // ✅ Second chance via rewarded ad
                                      ElevatedButton.icon(
                                        onPressed: () async {
                                          final ok = await showDialog<bool>(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: const Text('Second Chance'),
                                              content: const Text('Watch an ad to get 1 Color power-up and keep playing? (simulated)'),
                                              actions: [
                                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
                                                ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Watch Ad')),
                                              ],
                                            ),
                                          );
                                          if (ok == true) {
                                            // Grant + arm Color power-up and resume game
                                            _game.powerUpSystem.grant(PowerUpType.color, 1);
                                            _game.tryActivatePowerUp(PowerUpType.color);
                                            _game.gameOver.value = false;
                                            if (mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('+1 Color power-up armed — tap a colored cell')),
                                              );
                                            }
                                          }
                                        },
                                        icon: const Icon(Icons.replay_circle_filled),
                                        label: const Text('Second Chance'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _AdBannerPlaceholder extends StatelessWidget {
  const _AdBannerPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: GameConstants.adBannerHeight,
      color: const Color(0xFF222226),
      alignment: Alignment.center,
      child: const Text('Ad Banner (test)', style: TextStyle(color: Colors.white70)),
    );
  }
}
