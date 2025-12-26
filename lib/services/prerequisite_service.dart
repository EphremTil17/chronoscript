import 'dart:io';

/// Simple service for checking FFmpeg availability.
class PrerequisiteService {
  /// Checks if FFmpeg is available in PATH.
  /// Returns null if available, or an error message if not.
  static Future<String?> checkFfmpeg() async {
    try {
      final result = await Process.run('ffmpeg', ['-version']);
      if (result.exitCode == 0) {
        return null; // FFmpeg is available
      }
    } catch (_) {
      // FFmpeg not found
    }

    // Return installation instructions
    if (Platform.isWindows) {
      return '''FFmpeg is required for waveform visualization.

To install:
1. Open PowerShell as Administrator
2. Run: winget install Gyan.FFmpeg
3. Restart this application

Or download from: https://ffmpeg.org/download.html''';
    } else if (Platform.isMacOS) {
      return '''FFmpeg is required for waveform visualization.

To install:
Run: brew install ffmpeg

Then restart this application.''';
    } else {
      return '''FFmpeg is required for waveform visualization.

To install:
Run: sudo apt install ffmpeg

Then restart this application.''';
    }
  }

  /// Get FFmpeg version string if available.
  static Future<String?> getFfmpegVersion() async {
    try {
      final result = await Process.run('ffmpeg', ['-version']);
      if (result.exitCode == 0) {
        final lines = result.stdout.toString().split('\n');
        return lines.isNotEmpty ? lines.first.trim() : 'FFmpeg available';
      }
    } catch (_) {}
    return null;
  }
}
