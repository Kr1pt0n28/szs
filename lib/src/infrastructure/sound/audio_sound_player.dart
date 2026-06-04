import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../../domain/ports/sound_player.dart';

//
class AudioSoundPlayer implements SoundPlayer {
  AudioSoundPlayer({AudioPlayer? player}) : _player = player ?? AudioPlayer();

  final AudioPlayer _player;

  // Callback para cuando la reproducción se detiene, que puede ser configurada externamente.
  void Function()? _onStop;

  @override
  bool get isPlaying => _player.state == PlayerState.playing;

  @override
  set onStop(void Function()? callback) {
    _onStop = callback;
  }

  // Reproduce un archivo de audio desde un asset, con opción de repetición.
  @override
  Future<void> play(String assetToPlay, {bool loop = false}) async {
    await _player.setReleaseMode(loop ? ReleaseMode.loop : ReleaseMode.stop);
    await _player.play(AssetSource(assetToPlay));
    _player.onPlayerStateChanged.listen(_listen);
  }

  void _listen(PlayerState state) {
    _log('Player state changed: $state');
    if (state == PlayerState.completed) {
      stop();
    }
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    _onStop?.call();
  }

  @override
  Future<void> setAsset(String assetPath,
      {bool preload = true, Duration? initialPosition}) async {
    await _player.setSource(AssetSource(assetPath));
    if (preload) {
      await _player.resume();
      await _player.stop();
    }
    if (initialPosition != null) {
      await _player.seek(initialPosition);
    }
  }

  void _log(String msg) {
    debugPrint('VoxiaSound: $msg');
  }
}