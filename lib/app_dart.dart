import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:puzzle_box/presentation/cubit/game_cubit_dart.dart';
import 'package:puzzle_box/presentation/cubit/player_cubit_dart.dart';
import 'package:puzzle_box/presentation/cubit/ui_cubit_dart.dart';
import 'package:puzzle_box/presentation/pages/splash_page_dart.dart';
import 'injection_container.dart' as di;
import 'core/theme/app_theme.dart';

class BoxHooksApp extends StatelessWidget {
  const BoxHooksApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => di.sl<GameCubit>()..initialize()),
        BlocProvider(create: (_) => di.sl<PlayerCubit>()..exportPlayerData()),
        BlocProvider(create: (_) => di.sl<UICubit>()),
      ],
      child: MaterialApp(
        title: 'Box Hooks',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        home: const SplashPage(),
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
      ),
    );
  }
}