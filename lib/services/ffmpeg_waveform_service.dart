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
    // 1. Get total file length to estimate samples per peak
    final List<String> probeArgs = [
      '-i',
      audioPath,
      '-show_entries',
      'format=duration',
      '-v',
      'quiet',
      '-of',
      'csv=p=0',
    ];

    double duration = 0;
    try {
      final probeResult = await Process.run('ffprobe', probeArgs);
      duration = double.tryParse(probeResult.stdout.toString().trim()) ?? 0;
    } catch (e) {
      _log("Probing failed, estimation will be less accurate.");
    }

    // Target sample rate for analysis
    const int sampleRate = 4000;
    final totalSamples = (duration * sampleRate).toInt();
    final samplesPerPeak = totalSamples > 0
        ? (totalSamples / targetPeakCount).ceil()
        : 1000; // Fallback

    final List<String> args = [
      '-i', audioPath,
      '-ac', '1', // Mono
      '-ar', '$sampleRate',
      '-f', 's16le',
      '-acodec', 'pcm_s16le',
      'pipe:1',
    ];

    _log("Starting FFmpeg stream...");
    final process = await Process.start('ffmpeg', args);
    _activeProcesses.add(process);

    final peaks = List<double>.filled(targetPeakCount, 0.0);
    int currentPeakIndex = 0;
    int samplesInCurrentPeak = 0;
    int maxValInPeak = 0;

    try {
      await for (final chunk in process.stdout) {
        final uint8List = Uint8List.fromList(chunk);
        final data = ByteData.view(uint8List.buffer);
        for (int i = 0; i < chunk.length - 1; i += 2) {
          final sample = data.getInt16(i, Endian.little).abs();
          if (sample > maxValInPeak) maxValInPeak = sample;

          samplesInCurrentPeak++;

          if (samplesInCurrentPeak >= samplesPerPeak &&
              currentPeakIndex < targetPeakCount) {
            peaks[currentPeakIndex] = maxValInPeak / 32768.0;
            currentPeakIndex++;
            samplesInCurrentPeak = 0;
            maxValInPeak = 0;
          }
        }
      }

      // Handle the last peak if we have remaining samples
      if (currentPeakIndex < targetPeakCount && samplesInCurrentPeak > 0) {
        peaks[currentPeakIndex] = maxValInPeak / 32768.0;
      }
    } catch (e) {
      _log("Streaming extraction error: $e");
    } finally {
      _activeProcesses.remove(process);
    }

    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      _log("FFmpeg exited with error code $exitCode");
    }

    _log("Extracted ${peaks.length} peaks via streaming.");
    return peaks;
  }
}
