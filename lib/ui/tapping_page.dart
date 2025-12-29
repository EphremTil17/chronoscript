import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chronoscript/providers/app_state.dart';
import 'package:chronoscript/controllers/audio_controller.dart';
import 'package:chronoscript/services/export_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chronoscript/models/sync_word.dart';
import 'package:chronoscript/ui/widgets/verse_sidebar.dart';
import 'package:chronoscript/ui/widgets/liturgy_hub.dart';
import 'package:chronoscript/ui/widgets/custom_title_bar.dart';
import 'package:chronoscript/ui/widgets/preview_tab.dart';
import 'package:file_picker/file_picker.dart';

class TappingPage extends ConsumerStatefulWidget {
  const TappingPage({super.key});

  @override
  ConsumerState<TappingPage> createState() => _TappingPageState();
}

class _TappingPageState extends ConsumerState<TappingPage> {
  final FocusNode _keyboardFocus = FocusNode();
  final ScrollController _gridScrollController = ScrollController();
  Timer? _autoSaveTimer;

  // New: Live Timer for Green State
  int _liveMs = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_keyboardFocus);
    });

    // Auto-Save every 30s
    _autoSaveTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _autoSave(),
    );

    // Auto-Scroll Listener & Live Timer
    ref.read(audioControllerProvider).positionStream.listen((position) {
      if (mounted) {
        setState(() {
          _liveMs = position.inMilliseconds;
        });
      }
    });
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _keyboardFocus.dispose();
    _gridScrollController.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final audioCtrl = ref.read(audioControllerProvider);
      final notifier = ref.read(tappingProvider.notifier);
      final state = ref.read(tappingProvider);

      if (event.logicalKey == LogicalKeyboardKey.space) {
        if (state.isRecording) {
          notifier.chainWord(audioCtrl.currentPosition.inMilliseconds);
        } else {
          if (!state.isPlaying) {
            audioCtrl.play();
            notifier.setPlaying(true);
          }
          notifier.startRecordingWord(audioCtrl.currentPosition.inMilliseconds);
        }
      } else if (event.logicalKey == LogicalKeyboardKey.enter) {
        if (state.isRecording) {
          notifier.endRecordingWord(audioCtrl.currentPosition.inMilliseconds);
        }
      } else if (event.logicalKey == LogicalKeyboardKey.keyP) {
        if (state.isPlaying) {
          audioCtrl.pause();
          notifier.setPlaying(false);
        } else {
          audioCtrl.play();
          notifier.setPlaying(true);
        }
      } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        audioCtrl.seekBackward(const Duration(seconds: 5));
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        audioCtrl.seekBackward(const Duration(seconds: -5));
      }
    }
  }

  void _autoSave() async {
    final state = ref.read(tappingProvider);
    final audioPath = ref.read(audioPathProvider);
    if (state.verses.isEmpty) return;
    await ExportService.saveAutoSave(state.verses, audioPath);
  }

  Future<void> _manualSave() async {
    final state = ref.read(tappingProvider);
    final audioPath = ref.read(audioPathProvider);

    String? outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Studio Session',
      fileName: 'session.json',
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (outputFile != null) {
      await ExportService.saveProject(outputFile, state.verses, audioPath);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Project saved successfully!",
              style: GoogleFonts.lexend(),
            ),
            backgroundColor: const Color(0xFF8B1538),
          ),
        );
      }
    }
  }

  void _onVerseSelected(int index) {
    ref.read(tappingProvider.notifier).selectVerse(index);
    final verse = ref.read(tappingProvider).verses[index];
    for (var w in verse.words) {
      if (w.startTime != null) {
        ref
            .read(audioControllerProvider)
            .seek(Duration(milliseconds: w.startTime!));
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tappingProvider);
    final notifier = ref.read(tappingProvider.notifier);
    final audioCtrl = ref.read(audioControllerProvider);
    final currentVerseWords = state.currentWords;
    final bool isRecording = state.isRecording;

    final bool isSidebarLocked = isRecording;
    final bool isGridSelectionLocked = isRecording;

    return KeyboardListener(
      focusNode: _keyboardFocus,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F1E8),
        body: Column(
          children: [
            const CustomTitleBar(),
            // MAIN CONTENT AREA (Sidebar + Right Panel)
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // LEFT: Full-Height Sidebar
                  SizedBox(
                    width: 240,
                    child: VerseSidebar(
                      verses: state.verses,
                      selectedIndex: state.selectedVerseIndex,
                      onVerseSelected: _onVerseSelected,
                      isLocked: isSidebarLocked,
                    ),
                  ),

                  // RIGHT: Header, Hub, Grid
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      child: Column(
                        children: [
                          // 1. Right Panel Header
                          Container(
                            height:
                                48, // Slightly taller for better touch target
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFF5F1E8,
                              ), // Matches background
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF8B1538),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  "ChronoScript Studio: ${state.currentVerse.id.toUpperCase()}",
                                  style: GoogleFonts.lexend(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF2C2C2C),
                                  ),
                                ),
                                const Spacer(),
                                // Save Button (Right Top)
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: _manualSave,
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: const Color(
                                            0xFF8B1538,
                                          ).withValues(alpha: 0.3),
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.save_outlined,
                                            size: 18,
                                            color: Color(0xFF8B1538),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            "Save",
                                            style: GoogleFonts.lexend(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF8B1538),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // 2. Control Hub (Compact)
                          LiturgyControlHub(
                            state: state,
                            liveMs: _liveMs,
                            onStart: () => notifier.startRecordingWord(_liveMs),
                            onEnd: () => notifier.endRecordingWord(_liveMs),
                            onChain: () => notifier.chainWord(_liveMs),
                            onTogglePlay: () {
                              if (state.isPlaying) {
                                audioCtrl.pause();
                                notifier.setPlaying(false);
                              } else {
                                audioCtrl.play();
                                notifier.setPlaying(true);
                              }
                            },
                            onSeekBackward: () => audioCtrl.seekBackward(
                              const Duration(seconds: 5),
                            ),
                            onSeekForward: () => audioCtrl.seekBackward(
                              const Duration(seconds: -5),
                            ),
                            onReset: () => notifier.resetSelectedWords(),
                          ),

                          // 3. Word Grid with Header
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Grid Header
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    32,
                                    16,
                                    32,
                                    12,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          _buildTabButton(
                                            "Synchronization",
                                            TappingTab.sync,
                                            state.currentTab,
                                          ),
                                          const SizedBox(width: 8),
                                          _buildTabButton(
                                            "Preview",
                                            TappingTab.preview,
                                            state.currentTab,
                                          ),
                                        ],
                                      ),
                                      if (state.currentTab == TappingTab.sync)
                                        Row(
                                          children: [
                                            _buildLegendItem(
                                              "Synced",
                                              const Color(0xFFB8860B),
                                            ),
                                            const SizedBox(width: 16),
                                            _buildLegendItem(
                                              "Active",
                                              const Color(0xFF8B1538),
                                            ),
                                            const SizedBox(width: 16),
                                            _buildLegendItem(
                                              "Pending",
                                              Colors.grey.shade400,
                                              isCircle: true,
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: state.currentTab == TappingTab.preview
                                      ? const PreviewTab()
                                      : GridView.builder(
                                          controller: _gridScrollController,
                                          padding: const EdgeInsets.fromLTRB(
                                            32,
                                            0,
                                            32,
                                            32,
                                          ),
                                          gridDelegate:
                                              const SliverGridDelegateWithMaxCrossAxisExtent(
                                                maxCrossAxisExtent: 220,
                                                mainAxisSpacing: 20,
                                                crossAxisSpacing: 20,
                                                childAspectRatio: 1.6,
                                              ),
                                          itemCount: currentVerseWords.length,
                                          itemBuilder: (context, index) {
                                            final word =
                                                currentVerseWords[index];
                                            return _WordCard(
                                              word: word,
                                              isSelected: state
                                                  .selectedWordIndices
                                                  .contains(index),
                                              isSynced:
                                                  word.startTime != null &&
                                                  word.endTime != null,
                                              isRecordingActive:
                                                  isRecording &&
                                                  state.recordingWordIndex ==
                                                      index,
                                              isChainedToNext: _isChained(
                                                currentVerseWords,
                                                index,
                                              ),
                                              onTap: isGridSelectionLocked
                                                  ? null
                                                  : () {
                                                      notifier.handleWordTap(
                                                        index,
                                                        isControlPressed:
                                                            HardwareKeyboard
                                                                .instance
                                                                .isControlPressed,
                                                        isShiftPressed:
                                                            HardwareKeyboard
                                                                .instance
                                                                .isShiftPressed,
                                                      );
                                                      if (word.startTime !=
                                                              null &&
                                                          !state.isRecording &&
                                                          !HardwareKeyboard
                                                              .instance
                                                              .isControlPressed &&
                                                          !HardwareKeyboard
                                                              .instance
                                                              .isShiftPressed) {
                                                        audioCtrl.seek(
                                                          Duration(
                                                            milliseconds:
                                                                word.startTime!,
                                                          ),
                                                        );
                                                      }
                                                    },
                                            );
                                          },
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 4. BOTTOM STATUS BAR (Full Width)
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Text(
                    state.currentVerse.id.toUpperCase(),
                    style: GoogleFonts.lexend(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  const Spacer(),
                  _buildStatusCounter(
                    icon: Icons.check_circle_outline,
                    count: state.currentVerse.syncedWordCount,
                    total: state.currentVerse.words.length,
                    label: "words synced",
                    color: const Color(0xFFB8860B),
                  ),
                  const SizedBox(width: 24),
                  _buildStatusCounter(
                    icon: Icons.circle_outlined,
                    count:
                        state.currentVerse.words.length -
                        state.currentVerse.syncedWordCount,
                    total: state.currentVerse.words.length,
                    label: "remaining",
                    color: Colors.grey,
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 120,
                    child: LinearProgressIndicator(
                      value: state.currentVerse.words.isEmpty
                          ? 0
                          : state.currentVerse.syncedWordCount /
                                state.currentVerse.words.length,
                      backgroundColor: Colors.grey.shade100,
                      valueColor: const AlwaysStoppedAnimation(
                        Color(0xFF8B1538),
                      ),
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "40",
                    style: GoogleFonts.lexend(fontSize: 10, color: Colors.grey),
                  ),
                  const SizedBox(width: 16),
                  // Keyboard Shortcuts Icon
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _showShortcutsDialog(context),
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(
                          Icons.keyboard,
                          size: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showShortcutsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFDF5E6),
        title: Row(
          children: [
            const Icon(Icons.keyboard, color: Color(0xFF8B1538)),
            const SizedBox(width: 12),
            Text(
              "Keyboard Shortcuts",
              style: GoogleFonts.lexend(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildShortcutRow("Space", "Start/Chain Transcription"),
            _buildShortcutRow("Enter", "End Word Transcription"),
            _buildShortcutRow("P", "Play / Pause Audio"),
            _buildShortcutRow("Left Arrow", "Rewind 5 Seconds"),
            _buildShortcutRow("Right Arrow", "Forward 5 Seconds"),
            const Divider(height: 32),
            _buildShortcutRow("Ctrl + Click", "Multi-Select Words"),
            _buildShortcutRow("Shift + Click", "Select Range of Words"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Got it",
              style: GoogleFonts.lexend(color: const Color(0xFF8B1538)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutRow(String key, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.grey.shade400),
            ),
            child: Text(
              key,
              style: GoogleFonts.firaCode(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              description,
              style: GoogleFonts.lexend(fontSize: 13, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  bool _isChained(List<SyncWord> words, int index) {
    if (index + 1 >= words.length) return false;
    final w = words[index];
    final next = words[index + 1];
    return w.endTime != null &&
        next.startTime != null &&
        w.endTime == next.startTime;
  }

  Widget _buildTabButton(String label, TappingTab tab, TappingTab activeTab) {
    final bool isActive = tab == activeTab;
    const kCrimson = Color(0xFF8B1538);
    const kInactiveParchment = Color(0xFFE8E2D5);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => ref.read(tappingProvider.notifier).setTab(tab),
        borderRadius: BorderRadius.circular(8),
        hoverColor: isActive
            ? Colors.white.withValues(alpha: 0.15)
            : Colors.black.withValues(alpha: 0.05),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          decoration: BoxDecoration(
            color: isActive
                ? kCrimson
                : kInactiveParchment.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive ? kCrimson : Colors.grey.shade300,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.lexend(
              fontSize: 13,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive ? Colors.white : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, {bool isCircle = false}) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isCircle ? Colors.transparent : color,
            border: isCircle ? Border.all(color: color, width: 1.5) : null,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.lexend(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCounter({
    required IconData icon,
    required int count,
    required int total,
    required String label,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(
          "$count / $total $label",
          style: GoogleFonts.lexend(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}

class _WordCard extends StatelessWidget {
  final SyncWord word;
  final bool isSelected;
  final bool isSynced;
  final bool isRecordingActive;
  final bool isChainedToNext;
  final VoidCallback? onTap;

  const _WordCard({
    required this.word,
    required this.isSelected,
    required this.isSynced,
    required this.isRecordingActive,
    required this.isChainedToNext,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const kCrimson = Color(0xFF8B1538);
    final borderColor = isRecordingActive
        ? kCrimson
        : (isSynced ? const Color(0xFFB8860B) : Colors.transparent);
    final dotColor = isRecordingActive
        ? kCrimson
        : (isSynced ? const Color(0xFFB8860B) : Colors.grey.shade300);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        hoverColor: kCrimson.withValues(alpha: 0.1),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? kCrimson
                      : (borderColor == Colors.transparent
                            ? Colors.grey.shade200
                            : borderColor),
                  width: isSelected || isRecordingActive ? 2 : 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: dotColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        word.text,
                        style: GoogleFonts.notoSerifEthiopic(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF2C2C2C),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      isSynced
                          ? "${((word.endTime! - word.startTime!) / 1000).toStringAsFixed(2)}s"
                          : "Unsynced",
                      style: GoogleFonts.lexend(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: isSynced
                            ? const Color(0xFFB8860B)
                            : Colors.grey.shade400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (isChainedToNext)
              Positioned(
                right:
                    -20, // Center between this card (end at 0) and next (start at 20). Center of gap is 10. Center of widget (20/2=10) needs to be at 10. So right edge at 20.
                top: 0,
                bottom: 0,
                child: Center(
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F1E8),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFB8860B),
                        width: 1.5,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.link,
                        size: 12,
                        color: Color(0xFFB8860B),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
