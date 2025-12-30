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

  // Target density for visualization - 100 peaks per second gives sub-frame detail (10ms)
  static const int peaksPerSecond = 100;

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

        // Return cached data - we don't strictly check length here as
        // older fixed-length caches will just be upgraded to rate-based
        // if the sample happens to match or if user clears cache.
        return data.map((e) => (e as num).toDouble()).toList();
      } catch (_) {
        // Re-extract if cache is corrupted
      }
    }

    // 2. Extract using FFmpeg
    _log("Extracting high-density waveform...");
    final stopwatch = Stopwatch()..start();
    final peaks = await _runFfmpeg(audioPath);
    stopwatch.stop();

    if (peaks.isEmpty) {
      return [];
    }

    _log("Extraction complete in ${stopwatch.elapsedMilliseconds}ms");

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
    return File(p.join(dir.path, 'chronoscript_waveforms', '$name.v3.peaks'));
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

    if (duration <= 0) return [];

    final int totalPeaks = (duration * peaksPerSecond).ceil();
    _log("Target peak count: $totalPeaks (at ${peaksPerSecond}pps)");

    // Target sample rate for analysis
    const int sampleRate = 4000;
    final totalSamples = (duration * sampleRate).toInt();
    final samplesPerPeak = (totalSamples / totalPeaks).ceil();

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

    // Drain stderr to prevent deadlock
    process.stderr.transform(utf8.decoder).listen((data) {
      if (data.contains('Error') || data.contains('error')) {
        _log("FFmpeg stderr: ${data.trim()}");
      }
    });

    final peaks = List<double>.filled(totalPeaks, 0.0);
    int currentPeakIndex = 0;
    int samplesInCurrentPeak = 0;
    int maxValInPeak = 0;

    // Buffer to handle samples split across chunks
    final carryOver = <int>[];

    try {
      await for (final chunk in process.stdout) {
        // combine with carry-over from previous chunk
        Uint8List bytes;
        if (carryOver.isEmpty) {
          bytes = Uint8List.fromList(chunk);
        } else {
          bytes = Uint8List.fromList([...carryOver, ...chunk]);
          carryOver.clear();
        }

        final data = ByteData.view(bytes.buffer);
        int i = 0;
        for (; i + 1 < bytes.length; i += 2) {
          final sample = data.getInt16(i, Endian.little).abs();
          if (sample > maxValInPeak) maxValInPeak = sample;

          samplesInCurrentPeak++;

          if (samplesInCurrentPeak >= samplesPerPeak &&
              currentPeakIndex < totalPeaks) {
            peaks[currentPeakIndex] = maxValInPeak / 32768.0;
            currentPeakIndex++;
            samplesInCurrentPeak = 0;
            maxValInPeak = 0;

            if (currentPeakIndex % 10000 == 0) {
              _log(
                "Extraction progress: $currentPeakIndex / $totalPeaks peaks...",
              );
            }
          }
        }

        // store remaining byte if any
        if (i < bytes.length) {
          carryOver.add(bytes[i]);
        }
      }

      // Handle the last peak if we have remaining samples
      if (currentPeakIndex < totalPeaks && samplesInCurrentPeak > 0) {
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
