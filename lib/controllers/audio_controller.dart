import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:logging/logging.dart';
import '../services/ffmpeg_waveform_service.dart';
import '../services/prerequisite_service.dart';

enum PlayerState { playing, paused, stopped }

class AudioController {
  static final _logger = Logger('AudioController');
  AudioSource? _currentSource;
  SoundHandle? _currentHandle;
  Timer? _positionTimer;
  final _positionController = StreamController<Duration>.broadcast();
  final _playerStateController = StreamController<PlayerState>.broadcast();
  final _waveformController = StreamController<List<double>?>.broadcast();
  final _logController = StreamController<String>.broadcast();
  final _ffmpegErrorController = StreamController<String>.broadcast();

  // Expose streams
  Stream<Duration> get positionStream => _positionController.stream;
  Stream<List<double>?> get waveformStream => _waveformController.stream;
  Stream<String> get logStream => _logController.stream;
  Stream<String> get ffmpegErrorStream => _ffmpegErrorController.stream;

  Duration _currentPosition = Duration.zero;
  Duration get currentPosition => _currentPosition;

  Duration _totalDuration = Duration.zero;
  Duration get totalDuration => _totalDuration;

  List<double>? _currentWaveform;
  List<double>? get currentWaveform => _currentWaveform;

  Future<void>? _initFuture;

  Future<void> init() async {
    _initFuture ??= _init();
    await _initFuture;
  }

  Future<void> _init() async {
    if (!SoLoud.instance.isInitialized) {
      Logger.root.level = Level.ALL;
      Logger.root.onRecord.listen((record) {
        debugPrint('${record.level.name}: ${record.time}: ${record.message}');
      });
      _logger.info("SoLoud: Initializing...");
      await SoLoud.instance.init();
      _logger.info("SoLoud: Initialized");
    }
  }

  File? _tempFile;

  Future<void> setAudioFile(String path) async {
    _logger.info("setAudioFile called with: $path");
    await init();

    // Reset Waveform
    _currentWaveform = null;
    _waveformController.add(null);

    // Cleanup previous source and temp file
    if (_currentSource != null) {
      _logger.info("Disposing previous source...");
      await SoLoud.instance.disposeSource(_currentSource!);
      _currentSource = null;
      _currentHandle = null;
    }

    if (_tempFile != null) {
      try {
        if (await _tempFile!.exists()) {
          await _tempFile!.delete();
        }
      } catch (e) {
        _logger.warning("Could not delete temp file: $e");
      }
      _tempFile = null;
    }

    _logger.info("Loading new source...");
    try {
      String pathPayload = path;

      // Workaround for Windows non-ASCII path support
      if (Platform.isWindows && _hasNonAscii(path)) {
        _logger.info(
          "Detected non-ASCII path on Windows. Creating temp copy...",
        );
        final tempDir = Directory.systemTemp;
        final ext = path.split('.').last;
        final safeName =
            "temp_audio_${DateTime.now().millisecondsSinceEpoch}.$ext";
        final tempPath = "${tempDir.path}\\$safeName";

        final originalFile = File(path);
        _tempFile = await originalFile.copy(tempPath);
        pathPayload = _tempFile!.path;
        _logger.info("Created temp file at: $pathPayload");
      }

      _currentSource = await SoLoud.instance.loadFile(pathPayload);
      _logger.info("Source loaded. Getting length...");
      _totalDuration = SoLoud.instance.getLength(_currentSource!);
      _logger.info("Audio loaded successfully. Duration: $_totalDuration");

      // Extract Waveform (Async) - Use original path to avoid SoLoud locking the temp file
      _extractWaveform(path);
    } catch (e, stack) {
      _logger.severe("Error loading audio ($path): $e\n$stack");
    }
  }

  Future<void> _extractWaveform(String audioPath) async {
    _log("Starting waveform extraction...");

    // Check FFmpeg availability (simple version check)
    final ffmpegError = await PrerequisiteService.checkFfmpeg();
    if (ffmpegError != null) {
      _log("FFmpeg not available.");
      _ffmpegErrorController.add(ffmpegError);
      return;
    }

    _log("FFmpeg OK. Extracting peaks...");
    try {
      final service = FfmpegWaveformService(onLog: _log);
      final peaks = await service.extractPeaks(audioPath);
      if (peaks.isNotEmpty) {
        _currentWaveform = peaks;
        _waveformController.add(_currentWaveform);
        _log("Waveform ready: ${peaks.length} peaks.");
      } else {
        _log("No peaks extracted.");
      }
    } catch (e) {
      _log("Waveform error: $e");
    }
  }

  void _log(String message) {
    _logger.info(message);
    _logController.add(message);
  }

  bool _hasNonAscii(String str) {
    return str.codeUnits.any((c) => c > 127);
  }

  Future<void> play() async {
    if (_currentSource == null) return;

    if (_currentHandle != null &&
        SoLoud.instance.getIsValidVoiceHandle(_currentHandle!)) {
      SoLoud.instance.setPause(_currentHandle!, false);
    } else {
      _currentHandle = await SoLoud.instance.play(_currentSource!);
      if (_currentPosition > Duration.zero) {
        SoLoud.instance.seek(_currentHandle!, _currentPosition);
      }
    }
    _startPositionTimer();
  }

  Future<void> pause() async {
    if (_currentHandle != null &&
        SoLoud.instance.getIsValidVoiceHandle(_currentHandle!)) {
      SoLoud.instance.setPause(_currentHandle!, true);
    }
    _stopPositionTimer();
  }

  Future<void> setSpeed(double speed) async {
    if (_currentHandle != null &&
        SoLoud.instance.getIsValidVoiceHandle(_currentHandle!)) {
      SoLoud.instance.setRelativePlaySpeed(_currentHandle!, speed);
    }
  }

  Future<void> seek(Duration position) async {
    _currentPosition = position;
    if (_currentHandle != null &&
        SoLoud.instance.getIsValidVoiceHandle(_currentHandle!)) {
      SoLoud.instance.seek(_currentHandle!, position);
    }
    _positionController.add(position);
  }

  Future<void> seekBackward(Duration offset) async {
    final newPos = _currentPosition - offset;
    final target = newPos < Duration.zero ? Duration.zero : newPos;
    await seek(target);
  }

  void _startPositionTimer() {
    _positionTimer?.cancel();
    _positionTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (_currentHandle != null &&
          SoLoud.instance.getIsValidVoiceHandle(_currentHandle!)) {
        _currentPosition = SoLoud.instance.getPosition(_currentHandle!);
        _positionController.add(_currentPosition);
      }
    });
  }

  void _stopPositionTimer() {
    _positionTimer?.cancel();
  }

  void dispose() {
    _stopPositionTimer();
    SoLoud.instance.deinit();
    _positionController.close();
    _playerStateController.close();
    _waveformController.close();
    _logController.close();
    _ffmpegErrorController.close();
  }
}

// Global provider for the AudioController
final audioControllerProvider = Provider<AudioController>((ref) {
  final controller = AudioController();
  controller.init(); // Fire and forget init
  ref.onDispose(() => controller.dispose());
  return controller;
});
