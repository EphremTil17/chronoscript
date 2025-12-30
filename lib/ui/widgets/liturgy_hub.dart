import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chronoscript/providers/app_state.dart';
import 'package:chronoscript/ui/widgets/simple_timeline_scrubber.dart';
import 'package:chronoscript/controllers/audio_controller.dart';

class LiturgyControlHub extends ConsumerStatefulWidget {
  final TappingState state;
  final int liveMs;
  final VoidCallback onStart;
  final VoidCallback onEnd;
  final VoidCallback onChain;
  final VoidCallback onTogglePlay;
  final VoidCallback onSeekBackward;
  final VoidCallback onSeekForward;
  final VoidCallback onReset;

  const LiturgyControlHub({
    super.key,
    required this.state,
    required this.liveMs,
    required this.onStart,
    required this.onEnd,
    required this.onChain,
    required this.onTogglePlay,
    required this.onSeekBackward,
    required this.onSeekForward,
    required this.onReset,
  });

  @override
  ConsumerState<LiturgyControlHub> createState() => _LiturgyControlHubState();
}

class _LiturgyControlHubState extends ConsumerState<LiturgyControlHub> {
  double _speed = 1.0;
  static const List<double> _speeds = [0.5, 0.75, 1.0, 1.25, 1.5];

  String _formatDuration(int ms) {
    if (ms < 0) ms = 0;
    final duration = Duration(milliseconds: ms);
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final millis3 = duration.inMilliseconds
        .remainder(1000)
        .toString()
        .padLeft(3, '0');
    return "$minutes:$seconds.$millis3";
  }

  String _formatTotalDuration(int ms) {
    if (ms < 0) ms = 0;
    final duration = Duration(milliseconds: ms);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return hours > 0
        ? "${hours.toString().padLeft(2, '0')}:$minutes:$seconds"
        : "$minutes:$seconds";
  }

  void _setSpeed(double speed) {
    setState(() => _speed = speed);
    final audioCtrl = ref.read(audioControllerProvider);
    audioCtrl.setSpeed(speed);
    ref.read(tappingProvider.notifier).setSpeed(speed);
  }

  @override
  Widget build(BuildContext context) {
    const kCrimson = Color(0xFF8B1538);
    final isRecording = widget.state.isRecording;

    return Container(
      color: const Color(0xFFF5F1E8),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // LEFT COLUMN: Timer + Controls + Speed
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // TIMER + ZOOM
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  SizedBox(
                    width:
                        210, // Fixed width prevents buttons from jittering as milliseconds change
                    child: Text(
                      _formatDuration(widget.liveMs),
                      style: GoogleFonts.lexend(
                        fontSize: 36,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF2C2C2C),
                        fontFeatures: [const FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildZoomButton(
                    icon: Icons.zoom_in_rounded,
                    onPressed: () {
                      final zoom = ref.read(waveformZoomProvider);
                      ref.read(waveformZoomProvider.notifier).state =
                          (zoom * 1.5).clamp(1.0, 50.0);
                    },
                  ),
                  const SizedBox(width: 4),
                  _buildZoomButton(
                    icon: Icons.zoom_out_rounded,
                    onPressed: () {
                      final zoom = ref.read(waveformZoomProvider);
                      ref.read(waveformZoomProvider.notifier).state =
                          (zoom / 1.5).clamp(1.0, 50.0);
                    },
                  ),
                ],
              ),

              // CONTROLS ROW
              Row(
                children: [
                  // Play/Pause
                  _buildPlayButton(kCrimson),
                  const SizedBox(width: 8),
                  // Seek Buttons
                  _buildSeekButton(Icons.replay_5, widget.onSeekBackward),
                  const SizedBox(width: 4),
                  _buildSeekButton(Icons.forward_5, widget.onSeekForward),
                  const SizedBox(width: 12),
                  // Start/Chain Button Area - Fixed Width to prevent jitter
                  SizedBox(
                    width: 135,
                    child: isRecording
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              _buildStopButton(),
                              const SizedBox(width: 8),
                              _buildChainButton(),
                            ],
                          )
                        : _buildStartButton(),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // SPEED SELECTOR (below controls, left-aligned)
              _buildSpeedSelector(),
            ],
          ),

          const SizedBox(width: 24),

          // RIGHT COLUMN: Waveform (Expanded)
          Expanded(
            child: SizedBox(
              height: 100, // Fixed height to satisfy Column constraints
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: const WaveformScrubber(),
                    ),
                  ),
                  const SizedBox(height: 4),
                  StreamBuilder<Duration>(
                    stream: ref.watch(audioControllerProvider).positionStream,
                    builder: (context, _) {
                      final total = ref
                          .watch(audioControllerProvider)
                          .totalDuration;
                      return Text(
                        _formatTotalDuration(total.inMilliseconds),
                        style: GoogleFonts.lexend(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayButton(Color color) {
    return Material(
      color: color,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        onTap: widget.onTogglePlay,
        customBorder: const CircleBorder(),
        hoverColor: Colors.white.withValues(alpha: 0.2),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            widget.state.isPlaying ? Icons.pause : Icons.play_arrow,
            color: Colors.white,
            size: 26,
          ),
        ),
      ),
    );
  }

  Widget _buildSeekButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        hoverColor: Colors.grey.shade100,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Icon(icon, size: 18, color: Colors.black54),
        ),
      ),
    );
  }

  Widget _buildStartButton() {
    const kCrimson = Color(0xFF8B1538);
    final isMultiSelect = widget.state.selectedWordIndices.length > 1;
    final color = isMultiSelect ? Colors.grey.shade400 : kCrimson;

    return Tooltip(
      message: isMultiSelect
          ? "Transcription disabled during multi-selection"
          : "",
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(17),
        elevation: isMultiSelect ? 0 : 2,
        child: InkWell(
          onTap: isMultiSelect ? null : widget.onStart,
          borderRadius: BorderRadius.circular(17),
          hoverColor: Colors.white.withValues(alpha: 0.15),
          child: Container(
            height: 34,
            width: 135,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(17)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isMultiSelect ? Colors.white70 : Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "TRANSCRIBE",
                  style: GoogleFonts.lexend(
                    color: isMultiSelect ? Colors.white70 : Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStopButton() {
    const kCrimson = Color(0xFF8B1538);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      elevation: 2,
      child: InkWell(
        onTap: widget.onEnd,
        borderRadius: BorderRadius.circular(8),
        hoverColor: kCrimson.withValues(alpha: 0.1),
        child: Container(
          height: 34,
          width: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: kCrimson, width: 1.5),
          ),
          child: const Icon(Icons.stop, color: kCrimson, size: 18),
        ),
      ),
    );
  }

  Widget _buildChainButton() {
    const kCrimson = Color(0xFF8B1538);
    return Material(
      color: kCrimson,
      borderRadius: BorderRadius.circular(17),
      elevation: 2,
      child: InkWell(
        onTap: widget.onChain,
        borderRadius: BorderRadius.circular(17),
        hoverColor: Colors.white.withValues(alpha: 0.15),
        child: Container(
          height: 34,
          width: 83, // 135 total - 44 stop - 8 gap = 83
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(17)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.link, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text(
                "CHAIN",
                style: GoogleFonts.lexend(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpeedSelector() {
    final selectionCount = widget.state.selectedWordIndices.length;
    final resetLabel = selectionCount > 1
        ? "Reset ($selectionCount)"
        : "Reset Word";

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSpeedDropdown(),
        const SizedBox(width: 16),
        // Reset Button
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onReset,
            borderRadius: BorderRadius.circular(14),
            hoverColor: const Color(0xFF8B1538).withValues(alpha: 0.05),
            child: Container(
              height: 28,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.refresh, size: 14, color: Colors.grey.shade700),
                  const SizedBox(width: 6),
                  Text(
                    resetLabel,
                    style: GoogleFonts.lexend(
                      fontSize: 11,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpeedDropdown() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            "Speed:",
            style: GoogleFonts.lexend(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButton<double>(
            value: _speed,
            underline: const SizedBox(),
            isDense: true,
            icon: const Icon(
              Icons.keyboard_arrow_down,
              size: 14,
              color: Colors.grey,
            ),
            style: GoogleFonts.lexend(fontSize: 11, color: Colors.black87),
            items: _speeds.map((s) {
              return DropdownMenuItem(value: s, child: Text("${s}x"));
            }).toList(),
            onChanged: (val) {
              if (val != null) _setSpeed(val);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildZoomButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    const kCrimson = Color(0xFF8B1538);
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      elevation: 1,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        hoverColor: kCrimson.withValues(alpha: 0.1),
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(icon, size: 20, color: kCrimson),
        ),
      ),
    );
  }
}
