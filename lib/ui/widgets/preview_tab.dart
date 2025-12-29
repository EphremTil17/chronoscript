import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_state.dart';
import '../../controllers/audio_controller.dart';
import 'package:google_fonts/google_fonts.dart';

class PreviewTab extends ConsumerWidget {
  const PreviewTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tappingProvider);
    final verse = state.currentVerse;
    final audioCtrl = ref.watch(audioControllerProvider);

    // 50% Sync Check
    final syncedCount = verse.syncedWordCount;
    final totalCount = verse.words.length;
    final isReady = totalCount > 0 && (syncedCount / totalCount) >= 0.5;

    if (!isReady) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 24),
            Text(
              "Preview Locked",
              style: GoogleFonts.lexend(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Please synchronize at least 50% of the words in this verse\nto enable the Karaoke Preview.",
              textAlign: TextAlign.center,
              style: GoogleFonts.lexend(
                fontSize: 16,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 32),
            _buildProgressIndicator(syncedCount, totalCount),
          ],
        ),
      );
    }

    return StreamBuilder<Duration>(
      stream: audioCtrl.positionStream,
      builder: (context, snapshot) {
        final currentMs = snapshot.data?.inMilliseconds ?? 0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(48.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                verse.id.toUpperCase(),
                style: GoogleFonts.lexend(
                  fontSize: 14,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF8B1538).withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 32),
              Wrap(
                spacing: 12,
                runSpacing: 24,
                children: verse.words.map((word) {
                  final isActive =
                      word.startTime != null &&
                      word.endTime != null &&
                      currentMs >= word.startTime! &&
                      currentMs <= word.endTime!;

                  return _KaraokeWord(text: word.text, isActive: isActive);
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressIndicator(int count, int total) {
    final progress = total == 0 ? 0.0 : count / total;
    return Container(
      width: 300,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Sync Progress",
                style: GoogleFonts.lexend(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Text(
                "${(progress * 100).toInt()}%",
                style: GoogleFonts.lexend(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF8B1538),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade100,
            valueColor: const AlwaysStoppedAnimation(Color(0xFF8B1538)),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
        ],
      ),
    );
  }
}

class _KaraokeWord extends StatelessWidget {
  final String text;
  final bool isActive;

  const _KaraokeWord({required this.text, required this.isActive});

  @override
  Widget build(BuildContext context) {
    const kCrimson = Color(0xFF8B1538);

    return AnimatedDefaultTextStyle(
      duration: const Duration(milliseconds: 150),
      style: GoogleFonts.notoSerifEthiopic(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: isActive ? kCrimson : const Color(0xFF2C2C2C),
      ),
      child: Stack(
        children: [
          Text(text),
          Positioned(
            bottom: 2,
            left: 0,
            right: 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: 3,
              decoration: BoxDecoration(
                color: isActive ? kCrimson : Colors.transparent,
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
