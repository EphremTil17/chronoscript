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

  void _setSpeed(double speed) {
    setState(() => _speed = speed);
    final audioCtrl = ref.read(audioControllerProvider);
    audioCtrl.setSpeed(speed);
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
              // TIMER
              Padding(
                padding: const EdgeInsets.only(left: 4.0, bottom: 4),
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
                  // Start/Chain Button
                  _buildStartButton(isRecording: isRecording),
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
              height: 80,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: const WaveformScrubber(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayButton(Color color) {
    return GestureDetector(
      onTap: widget.onTogglePlay,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(
          widget.state.isPlaying ? Icons.pause : Icons.play_arrow,
          color: Colors.white,
          size: 26,
        ),
      ),
    );
  }

  Widget _buildSeekButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Icon(icon, size: 18, color: Colors.black54),
      ),
    );
  }

  Widget _buildStartButton({required bool isRecording}) {
    const kCrimson = Color(0xFF8B1538);
    return GestureDetector(
      onTap: isRecording ? widget.onChain : widget.onStart,
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: kCrimson,
          borderRadius: BorderRadius.circular(17),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon: dot for START, chain for CHAIN
            isRecording
                ? const Icon(Icons.link, color: Colors.white, size: 16)
                : Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
            const SizedBox(width: 6),
            Text(
              isRecording ? "CHAIN" : "START",
              style: GoogleFonts.lexend(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeedSelector() {
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
}
