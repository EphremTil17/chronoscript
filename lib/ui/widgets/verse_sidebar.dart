import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chronoscript/models/verse.dart';

class VerseSidebar extends StatelessWidget {
  final List<Verse> verses;
  final int selectedIndex;
  final Function(int) onVerseSelected;
  final VoidCallback onRefreshText;
  final bool isLocked;

  const VerseSidebar({
    super.key,
    required this.verses,
    required this.selectedIndex,
    required this.onVerseSelected,
    required this.onRefreshText,
    required this.isLocked, // Should be true ONLY if we want to prevent changing verses (e.g. during recording)
  });

  @override
  Widget build(BuildContext context) {
    const kCrimson = Color(0xFF8B1538);
    const kPaper = Color(0xFFF5F1E8);

    // Calculate Overall Progress
    int totalWords = 0;
    int totalSynced = 0;
    for (var v in verses) {
      totalWords += v.words.length;
      totalSynced += v.syncedWordCount;
    }
    final double overallProgress = totalWords > 0
        ? totalSynced / totalWords
        : 0.0;

    return Container(
      color: kPaper,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: 24.0,
              right: 12.0,
              top: 40,
              bottom: 8,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "VERSES",
                  style: GoogleFonts.lexend(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    color: kCrimson,
                  ),
                ),
                IconButton(
                  onPressed: isLocked ? null : onRefreshText,
                  icon: const Icon(Icons.refresh, size: 20),
                  color: kCrimson,
                  tooltip: "Refresh text from source file",
                ),
              ],
            ),
          ),

          // Overall Completion Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "COMPLETION",
                      style: GoogleFonts.lexend(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.black54,
                        letterSpacing: 1.0,
                      ),
                    ),
                    Text(
                      "${(overallProgress * 100).toInt()}%",
                      style: GoogleFonts.lexend(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: kCrimson,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: overallProgress,
                    minHeight: 6,
                    backgroundColor: kCrimson.withValues(alpha: 0.1),
                    valueColor: const AlwaysStoppedAnimation(kCrimson),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, indent: 24, endIndent: 24),
          const SizedBox(height: 12),

          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: verses.length,
              itemBuilder: (ctx, idx) {
                final verse = verses[idx];
                final isSelected = idx == selectedIndex;
                final totalCount = verse.words.length;
                final syncedCount = verse.syncedWordCount;
                final progress = totalCount > 0
                    ? syncedCount / totalCount
                    : 0.0;

                String displayId = verse.id;
                if (verse.id.toLowerCase().startsWith('v')) {
                  try {
                    final num = int.parse(verse.id.substring(1));
                    displayId = "Verse ${num.toString().padLeft(2, '0')}";
                  } catch (_) {}
                }

                return Material(
                  color: isSelected ? Colors.white : Colors.transparent,
                  child: InkWell(
                    onTap: isLocked ? null : () => onVerseSelected(idx),
                    hoverColor: kCrimson.withValues(alpha: 0.05),
                    child: Container(
                      height: 64, // Increased height for two-line layout
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Text(
                                displayId,
                                style: GoogleFonts.lexend(
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected ? kCrimson : Colors.black87,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                "${(progress * 100).toInt()}%",
                                style: GoogleFonts.lexend(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: progress == 1.0
                                      ? Colors.green.shade700
                                      : kCrimson.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 3,
                              backgroundColor: kCrimson.withValues(alpha: 0.05),
                              valueColor: AlwaysStoppedAnimation(
                                progress == 1.0
                                    ? Colors.green.shade400
                                    : kCrimson.withValues(alpha: 0.4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
