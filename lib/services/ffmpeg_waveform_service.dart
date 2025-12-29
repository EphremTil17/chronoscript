import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:logging/logging.dart';

/// Service for extracting waveform peaks using FFmpeg.
/// Optimized for performance with a fixed peak count.
class FfmpegWaveformService {
  static final _logger = Logger('FfmpegWaveformService');
  final void Function(String message)? onLog;

  // Target number of peaks for visualization - keep this small for performance
  static const int targetPeakCount = 400;

  static final Set<Process> _activeProcesses = {};

  /// Forcefully kills all active FFmpeg processes.
  static void killAll() {
    for (final process in _activeProcesses) {
      try {
        process.kill(ProcessSignal.sigterm);
      } catch (_) {}
    }
    _activeProcesses.clear();
  }

  FfmpegWaveformService({this.onLog});

  void _log(String message) {
    _logger.info(message);
    onLog?.call(message);
  }

  /// Extracts audio peaks from the given file.
  /// Returns a fixed-size list of normalized peak values (0.0 to 1.0).
  Future<List<double>> extractPeaks(String audioPath) async {
    final audioFile = File(audioPath);
    if (!await audioFile.exists()) {
      _log("Audio file not found");
      return [];
    }

    // 1. Check cache
    final cacheFile = await _getCacheFile(audioPath);
    if (await cacheFile.exists()) {
      try {
        final content = await cacheFile.readAsString();
        final List<dynamic> data = jsonDecode(content);
        _log("Loaded ${data.length} peaks from cache");

        // Ensure cache matches current target count
        if (data.length == targetPeakCount) {
          return data.map((e) => (e as num).toDouble()).toList();
        }
        _log(
          "Cache mismatch (${data.length} != $targetPeakCount), re-extracting...",
        );
      } catch (_) {
        // Re-extract if cache is corrupted
      }
    }

    // 2. Extract using FFmpeg
    _log("Extracting waveform...");
    final peaks = await _runFfmpeg(audioPath);

    if (peaks.isEmpty) {
      return [];
    }

    // 3. Cache result
    final cacheDir = cacheFile.parent;
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    await cacheFile.writeAsString(jsonEncode(peaks));
    _log("Cached ${peaks.length} peaks");

    return peaks;
  }

  Future<File> _getCacheFile(String audioPath) async {
    final dir = await getApplicationDocumentsDirectory();
    final name = p.basenameWithoutExtension(audioPath);
    return File(p.join(dir.path, 'chronoscript_waveforms', '$name.peaks'));
  }

  Future<List<double>> _runFfmpeg(String audioPath) async {
    // Use low sample rate for fast processing
    final List<String> args = [
      '-i', audioPath,
      '-ac', '1', // Mono
      '-ar', '4000', // 4kHz (low for speed)
      '-f', 's16le',
      '-acodec', 'pcm_s16le',
      'pipe:1',
    ];

    _log("Running FFmpeg...");
    final result = await Process.run('ffmpeg', args, stdoutEncoding: null);

    if (result.exitCode != 0) {
      _log("FFmpeg error");
      return [];
    }

    final Uint8List rawBytes = result.stdout as Uint8List;
    return _processPcm(rawBytes);
  }

  List<double> _processPcm(Uint8List rawBytes) {
    if (rawBytes.isEmpty) return [];

    final sampleCount = rawBytes.length ~/ 2;
    if (sampleCount < targetPeakCount) return [];

    final samplesPerPeak = sampleCount ~/ targetPeakCount;
    final peaks = List<double>.filled(targetPeakCount, 0.0);
    final data = ByteData.view(rawBytes.buffer);

    for (int p = 0; p < targetPeakCount; p++) {
      int maxVal = 0;
      final startSample = p * samplesPerPeak;
      final endSample = (p + 1) * samplesPerPeak;

      for (
        int s = startSample;
        s < endSample && s * 2 + 1 < rawBytes.length;
        s++
      ) {
        final sample = data.getInt16(s * 2, Endian.little).abs();
        if (sample > maxVal) maxVal = sample;
      }
      peaks[p] = maxVal / 32768.0;
    }

    _log("Extracted $targetPeakCount peaks");
    return peaks;
  }
}
