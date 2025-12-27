import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chronoscript/models/verse.dart';

class VerseSidebar extends StatelessWidget {
  final List<Verse> verses;
  final int selectedIndex;
  final Function(int) onVerseSelected;
  final bool isLocked;

  const VerseSidebar({
    super.key,
    required this.verses,
    required this.selectedIndex,
    required this.onVerseSelected,
    required this.isLocked, // Should be true ONLY if we want to prevent changing verses (e.g. during recording)
  });

  @override
  Widget build(BuildContext context) {
    const kCrimson = Color(0xFF8B1538);
    const kPaper = Color(0xFFF5F1E8);

    return Container(
      color: kPaper,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 24.0, top: 40, bottom: 16),
            child: Text(
              "VERSES",
              style: GoogleFonts.lexend(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
                color: kCrimson,
              ),
            ),
          ),
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
                    hoverColor: kCrimson.withValues(alpha: 0.1),
                    child: Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Text(
                            displayId,
                            style: GoogleFonts.lexend(
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected ? kCrimson : Colors.black87,
                            ),
                          ),
                          const Spacer(),
                          if (isSelected)
                            Text(
                              "${(progress * 100).toInt()}%",
                              style: GoogleFonts.lexend(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: kCrimson.withAlpha((255 * 0.6).toInt()),
                              ),
                            )
                          else
                            Icon(
                              Icons.chevron_right,
                              size: 14,
                              color: Colors.grey.withAlpha((255 * 0.4).toInt()),
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
