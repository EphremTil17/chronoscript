import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/audio_controller.dart';

/// Efficient waveform scrubber widget with tap-to-seek and drag functionality.
/// Optimized to only seek on drag-end to prevent audio jitters.
class WaveformScrubber extends ConsumerStatefulWidget {
  const WaveformScrubber({super.key});

  @override
  ConsumerState<WaveformScrubber> createState() => _WaveformScrubberState();
}

class _WaveformScrubberState extends ConsumerState<WaveformScrubber> {
  double? _dragProgress;

  @override
  Widget build(BuildContext context) {
    final audioCtrl = ref.watch(audioControllerProvider);

    return StreamBuilder<List<double>?>(
      stream: audioCtrl.waveformStream,
      builder: (context, waveSnapshot) {
        final peaks = waveSnapshot.data;

        return StreamBuilder<Duration>(
          stream: audioCtrl.positionStream,
          builder: (context, posSnapshot) {
            final position = posSnapshot.data ?? Duration.zero;
            final duration = audioCtrl.totalDuration;

            double progress = 0.0;
            if (duration.inMilliseconds > 0) {
              progress = (position.inMilliseconds / duration.inMilliseconds)
                  .clamp(0.0, 1.0);
            }

            // Use drag progress if active for visual feedback
            final displayProgress = _dragProgress ?? progress;

            return LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  onHorizontalDragStart: (_) {
                    setState(() => _dragProgress = progress);
                  },
                  onHorizontalDragUpdate: (details) {
                    setState(() {
                      _dragProgress =
                          (details.localPosition.dx / constraints.maxWidth)
                              .clamp(0.0, 1.0);
                    });
                  },
                  onHorizontalDragEnd: (_) {
                    if (_dragProgress != null) {
                      _finalizeSeek(_dragProgress!, duration, audioCtrl);
                      setState(() => _dragProgress = null);
                    }
                  },
                  onHorizontalDragCancel: () {
                    setState(() => _dragProgress = null);
                  },
                  onTapUp: (details) {
                    final p = (details.localPosition.dx / constraints.maxWidth)
                        .clamp(0.0, 1.0);
                    _finalizeSeek(p, duration, audioCtrl);
                  },
                  child: RepaintBoundary(
                    child: CustomPaint(
                      size: Size(constraints.maxWidth, constraints.maxHeight),
                      painter: WaveformPainter(
                        peaks: peaks,
                        progress: displayProgress,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _finalizeSeek(double p, Duration total, AudioController ctrl) {
    ctrl.seek(Duration(milliseconds: (total.inMilliseconds * p).toInt()));
  }
}

/// Optimized painter - creates Paint objects once, not per-frame.
class WaveformPainter extends CustomPainter {
  final List<double>? peaks;
  final double progress;

  // Cached paints for performance
  static final Paint _playedPaint = Paint()
    ..color = const Color(0xFF8B1538)
    ..strokeCap = StrokeCap.round;

  static final Paint _unplayedPaint = Paint()
    ..color = const Color(0xFFCCCCCC)
    ..strokeCap = StrokeCap.round;

  static final Paint _playheadPaint = Paint()
    ..color = const Color(0xFF2C2C2C)
    ..strokeWidth = 2.0;

  WaveformPainter({required this.peaks, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (peaks == null || peaks!.isEmpty) return;

    final samples = peaks!;
    final barCount = samples.length;
    final barWidth = size.width / barCount;
    final midY = size.height / 2;
    final progressIndex = (progress * barCount).toInt();

    // Set stroke width based on bar spacing
    _playedPaint.strokeWidth = barWidth * 0.8;
    _unplayedPaint.strokeWidth = barWidth * 0.8;

    for (int i = 0; i < barCount; i++) {
      final amp = samples[i];
      final h = amp * midY * 0.9; // Slight padding
      final x = (i + 0.5) * barWidth;

      canvas.drawLine(
        Offset(x, midY - h),
        Offset(x, midY + h),
        i < progressIndex ? _playedPaint : _unplayedPaint,
      );
    }

    // Playhead
    final playheadX = progress * size.width;
    canvas.drawLine(
      Offset(playheadX, 0),
      Offset(playheadX, size.height),
      _playheadPaint,
    );
  }

  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.peaks != peaks;
  }
}
