import 'package:flame_audio/flame_audio.dart';
import '../core/constants/asset_constants.dart';
import '../core/constants/game_constants.dart';

abstract class AudioService {
  Future<void> preload();
  Future<void> playClick();
  Future<void> playClear();
  Future<void> playBgm({bool loop = true});
  Future<void> stopBgm();
  Future<void> dispose();
  void setMuted(bool muted);
}

class AudioServiceImpl implements AudioService {
  bool _initialized = false;
  bool _muted = false;

  @override
  Future<void> preload() async {
    if (_initialized) return;
    try {
      await FlameAudio.audioCache.loadAll(AssetConstants.audioAll);
      _initialized = true;
    } catch (_) {
      _initialized = false;
    }
  }

  @override
  Future<void> playClick() async {
    if (_muted) return;
    try { await FlameAudio.play(AssetConstants.audioClick, volume: GameConstants.sfxVolume); } catch (_) {}
  }

  @override
  Future<void> playClear() async {
    if (_muted) return;
    try { await FlameAudio.play(AssetConstants.audioClear, volume: GameConstants.sfxVolume); } catch (_) {}
  }

  @override
  Future<void> playBgm({bool loop = true}) async {
    if (_muted) return;
    try {
      await FlameAudio.bgm.play(AssetConstants.audioBgm, volume: GameConstants.musicVolume);
      if (!loop) await FlameAudio.bgm.stop();
    } catch (_) {}
  }

  @override
  Future<void> stopBgm() async { try { await FlameAudio.bgm.stop(); } catch (_) {} }

  @override
  Future<void> dispose() async { try { await FlameAudio.bgm.stop(); } catch (_) {} }

  @override
  void setMuted(bool muted) {
    _muted = muted;
    if (_muted) {
      stopBgm();
    }
  }
}
