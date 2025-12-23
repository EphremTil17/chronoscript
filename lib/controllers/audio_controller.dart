import 'package:just_audio/just_audio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// A dedicated controller to wrap just_audio interactions
class AudioController {
  final AudioPlayer _player = AudioPlayer();

  // Stream of current position
  Stream<Duration> get positionStream => _player.positionStream;

  // Stream of player state
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  Duration get currentPosition => _player.position;

  Future<void> setAudioFile(String path) async {
    await _player.setFilePath(path);
  }

  Future<void> play() => _player.play();
  Future<void> pause() => _player.pause();

  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  Future<void> seek(Duration position) => _player.seek(position);

  Future<void> seekBackward(Duration offset) async {
    final current = _player.position;
    final newPos = current - offset;
    await _player.seek(newPos < Duration.zero ? Duration.zero : newPos);
  }

  void dispose() {
    _player.dispose();
  }
}

// Global provider for the AudioController
final audioControllerProvider = Provider<AudioController>((ref) {
  final controller = AudioController();
  ref.onDispose(() => controller.dispose());
  return controller;
});
