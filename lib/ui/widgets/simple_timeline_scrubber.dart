import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/app_state.dart';
import '../../controllers/audio_controller.dart';

/// Efficient waveform scrubber widget with zoom and pan support.
class WaveformScrubber extends ConsumerStatefulWidget {
  const WaveformScrubber({super.key});

  @override
  ConsumerState<WaveformScrubber> createState() => _WaveformScrubberState();
}

class _WaveformScrubberState extends ConsumerState<WaveformScrubber> {
  double? _dragProgress;
  bool _manualPanActive = false;

  @override
  Widget build(BuildContext context) {
    final audioCtrl = ref.watch(audioControllerProvider);
    final zoomLevel = ref.watch(waveformZoomProvider);
    final scrollProviderValue = ref.watch(waveformScrollProvider);

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

            // Determine if we should follow the playhead or the manual scroll position
            final effectiveScroll = (zoomLevel > 1.0 && !_manualPanActive)
                ? progress
                : scrollProviderValue;

            final displayProgress = _dragProgress ?? progress;

            return LayoutBuilder(
              builder: (context, constraints) {
                return MouseRegion(
                  child: Listener(
                    onPointerSignal: (pointerSignal) {
                      if (pointerSignal is PointerScrollEvent) {
                        final isCtrlPressed =
                            HardwareKeyboard.instance.isControlPressed;
                        if (isCtrlPressed) {
                          final oldZoom = ref.read(waveformZoomProvider);
                          setState(() => _manualPanActive = false);

                          if (pointerSignal.scrollDelta.dy > 0) {
                            ref.read(waveformZoomProvider.notifier).state =
                                (oldZoom / 1.1).clamp(1.0, 50.0);
                          } else {
                            ref.read(waveformZoomProvider.notifier).state =
                                (oldZoom * 1.1).clamp(1.0, 50.0);
                          }
                        } else {
                          setState(() => _manualPanActive = true);
                          final currentScroll = ref.read(
                            waveformScrollProvider,
                          );
                          final panDelta =
                              pointerSignal.scrollDelta.dy /
                              (constraints.maxWidth * zoomLevel);
                          ref.read(waveformScrollProvider.notifier).state =
                              (currentScroll + panDelta).clamp(0.0, 1.0);
                        }
                      }
                    },
                    child: GestureDetector(
                      onHorizontalDragStart: (_) {
                        setState(() {
                          _dragProgress = progress;
                          _manualPanActive = false;
                        });
                      },
                      onHorizontalDragUpdate: (details) {
                        final viewportWidth = 1.0 / zoomLevel;
                        final startX = (effectiveScroll - viewportWidth / 2)
                            .clamp(0.0, 1.0 - viewportWidth);

                        setState(() {
                          final localX =
                              details.localPosition.dx / constraints.maxWidth;
                          _dragProgress = (startX + localX * viewportWidth)
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
                        final viewportWidth = 1.0 / zoomLevel;
                        final startX = (effectiveScroll - viewportWidth / 2)
                            .clamp(0.0, 1.0 - viewportWidth);
                        final localX =
                            details.localPosition.dx / constraints.maxWidth;
                        final p = (startX + localX * viewportWidth).clamp(
                          0.0,
                          1.0,
                        );
                        _finalizeSeek(p, duration, audioCtrl);
                      },
                      child: Stack(
                        children: [
                          RepaintBoundary(
                            child: CustomPaint(
                              size: Size(
                                constraints.maxWidth,
                                constraints.maxHeight,
                              ),
                              painter: WaveformPainter(
                                peaks: peaks,
                                progress: displayProgress,
                                zoomLevel: zoomLevel,
                                scrollProgress: effectiveScroll,
                              ),
                            ),
                          ),
                          if (zoomLevel > 1.0)
                            Positioned(
                              top: 4,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  "Zoom: ${zoomLevel.toStringAsFixed(1)}x${_manualPanActive ? ' (Locked)' : ''}",
                                  style: GoogleFonts.lexend(
                                    color: Colors.white,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ),
                        ],
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

class WaveformPainter extends CustomPainter {
  final List<double>? peaks;
  final double progress;
  final double zoomLevel;
  final double scrollProgress;

  static final Paint _playedPaint = Paint()
    ..color = const Color(0xFF8B1538)
    ..strokeCap = StrokeCap.round;

  static final Paint _unplayedPaint = Paint()
    ..color = const Color(0xFFCCCCCC)
    ..strokeCap = StrokeCap.round;

  static final Paint _playheadPaint = Paint()
    ..color = const Color(0xFF2C2C2C)
    ..strokeWidth = 2.0;

  WaveformPainter({
    required this.peaks,
    required this.progress,
    required this.zoomLevel,
    required this.scrollProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (peaks == null || peaks!.isEmpty) return;

    final samples = peaks!;
    final totalPeaksCount = samples.length;
    final viewportWidth = 1.0 / zoomLevel;

    // The viewport is centered on scrollProgress
    final startFraction = (scrollProgress - viewportWidth / 2).clamp(
      0.0,
      1.0 - viewportWidth,
    );
    final double visiblePeaksCount = viewportWidth * totalPeaksCount;
    final double pixelsPerPeak = size.width / visiblePeaksCount;

    final midY = size.height / 2;

    // Stable Sampling Strategy:
    // If pixelsPerPeak > 2.0, we draw every peak individually.
    // If pixelsPerPeak <= 2.0, we decimate into "buckets" to preserve performance and prevent jitter.

    if (pixelsPerPeak > 2.0) {
      // HIGH ZOOM: Draw every individual peak in the viewport
      final int startIdx = (startFraction * totalPeaksCount).floor().clamp(
        0,
        totalPeaksCount - 1,
      );
      final int endIdx = ((startFraction + viewportWidth) * totalPeaksCount)
          .ceil()
          .clamp(0, totalPeaksCount - 1);

      _playedPaint.strokeWidth = (pixelsPerPeak * 0.7).clamp(1.0, 10.0);
      _unplayedPaint.strokeWidth = _playedPaint.strokeWidth;

      for (int i = startIdx; i <= endIdx; i++) {
        final double x = (i - startFraction * totalPeaksCount) * pixelsPerPeak;
        final double amp = samples[i];
        final h = amp * midY * 0.9;
        final isPlayed = (i / totalPeaksCount) <= progress;

        canvas.drawLine(
          Offset(x, midY - h),
          Offset(x, midY + h),
          isPlayed ? _playedPaint : _unplayedPaint,
        );
      }
    } else {
      // LOW/MED ZOOM: Decimate using Quantized Bucketing to prevent jitter
      // We want to draw roughly 1 bar per 2-3 pixels for a clean look
      const double targetBarWidth = 3.0;
      final int peaksPerBar = (targetBarWidth / pixelsPerPeak).ceil();
      final double actualBarWidth = peaksPerBar * pixelsPerPeak;

      _playedPaint.strokeWidth = actualBarWidth * 0.7;
      _unplayedPaint.strokeWidth = actualBarWidth * 0.7;

      // Start the loop at an index that is a multiple of peaksPerBar to keep buckets stable
      final int firstVisibleIdx = (startFraction * totalPeaksCount).floor();
      final int loopStart = (firstVisibleIdx ~/ peaksPerBar) * peaksPerBar;
      final int loopEnd = ((startFraction + viewportWidth) * totalPeaksCount)
          .ceil();

      for (int i = loopStart; i <= loopEnd; i += peaksPerBar) {
        // Max-sample within this stable bucket
        double maxAmp = 0.0;
        for (int j = 0; j < peaksPerBar && (i + j) < totalPeaksCount; j++) {
          if (samples[i + j] > maxAmp) maxAmp = samples[i + j];
        }

        // Center the bar in its bucket
        final double x =
            (i + (peaksPerBar / 2.0) - startFraction * totalPeaksCount) *
            pixelsPerPeak;
        final h = maxAmp * midY * 0.9;
        final isPlayed = (i / totalPeaksCount) <= progress;

        if (x + actualBarWidth < 0 || x - actualBarWidth > size.width) continue;

        canvas.drawLine(
          Offset(x, midY - h),
          Offset(x, midY + h),
          isPlayed ? _playedPaint : _unplayedPaint,
        );
      }
    }

    // Playhead Drawing
    if (progress >= startFraction &&
        progress <= (startFraction + viewportWidth)) {
      final playheadX =
          ((progress - startFraction) / viewportWidth) * size.width;
      canvas.drawLine(
        Offset(playheadX, 0),
        Offset(playheadX, size.height),
        _playheadPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.peaks != peaks ||
        oldDelegate.zoomLevel != zoomLevel ||
        oldDelegate.scrollProgress != scrollProgress;
  }
}
