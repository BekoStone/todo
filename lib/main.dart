import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'injection_container.dart' as di;
import 'core/utils/performance_utils.dart';
import 'services/audio_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  PerformanceUtils.markColdStart();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.black,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  await di.initDependencies();

  // non-blocking asset/audio preload
  unawaited(di.sl<AudioService>().preload());

  runApp(const PuzzleBoxApp());

  PerformanceUtils.markFirstFrame();
  if (kDebugMode) {
    debugPrint('[Perf] Cold start: ${PerformanceUtils.coldStartMs} ms');
  }
}
