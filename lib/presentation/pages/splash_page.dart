// lib/presentation/pages/splash_page.dart
import 'package:flutter/material.dart';
import '../../injection_container.dart';
import '../../services/audio_service.dart';
import 'main_menu_page.dart';

class SplashPage extends StatefulWidget {
  static const route = '/';
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late final AnimationController _ac;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..forward();
    sl<AudioService>().preload().ignore();
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(MainMenuPage.route);
    });
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold( // ⚠️ not const
      body: Center(
        child: Text(
          'Puzzle Box',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}
