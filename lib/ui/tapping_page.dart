import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async'; // Required for Timer
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chronoscript/providers/app_state.dart';
import 'package:chronoscript/controllers/audio_controller.dart';
import 'package:chronoscript/ui/widgets/word_button.dart';
import 'package:chronoscript/services/export_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audio_waveforms/audio_waveforms.dart';

class TappingPage extends ConsumerStatefulWidget {
  const TappingPage({super.key});

  @override
  ConsumerState<TappingPage> createState() => _TappingPageState();
}

class _TappingPageState extends ConsumerState<TappingPage> {
  final FocusNode _keyboardFocus = FocusNode();

  // For scrolling the grid
  final ScrollController _gridScrollController = ScrollController();

  Timer? _autoSaveTimer;

  @override
  void initState() {
    super.initState();
    // Auto-focus to capture keyboard events immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_keyboardFocus);
    });

    // Start Auto-Save Timer (every 60 seconds)
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      _autoSave();
    });

    // Auto-Scroll Logic
    // We listen to the audio position stream directly here to drive the UI scroll
    // This is a bit imperative but efficient for scrolling.
    ref.read(audioControllerProvider).positionStream.listen((position) {
      final state = ref.read(tappingProvider);

      // Only auto-scroll in Verification Mode
      if (state.isVerificationMode && state.isPlaying) {
        final currentMs = position.inMilliseconds;

        // Find the word that contains this timestamp
        // Optimization: We could track 'lastFoundIndex' to avoid O(N) scan every frame
        // But for < few thousand words, simple search is fine for MVP.
        int foundIndex = -1;
        for (int i = 0; i < state.words.length; i++) {
          final w = state.words[i];
          if (w.startTime != null && w.endTime != null) {
            if (currentMs >= w.startTime! && currentMs <= w.endTime!) {
              foundIndex = i;
              break;
            }
          }
        }

        if (foundIndex != -1) {
          // Highlight the word in the UI?
          // We currently only highlight 'currentIndex'.
          // Should we update 'currentIndex' to match playback in verification mode?
          // YES, that would visually sync the grid.
          if (state.currentIndex != foundIndex) {
            ref.read(tappingProvider.notifier).setIndex(foundIndex);

            // Scroll to it
            if (_gridScrollController.hasClients) {
              // Calculate rough position or use jump
              // Grid cell height approx 75 (aspect ratio 2 + spacing).
              // Let's use insureVisible or just scroll lookup.
              // Since it's a grid, it's row based.
              // Doing a simple calculation:
              // This is approximate.
              // Better to just let the user scroll or use a library, but simplest is:
              // _gridScrollController.animateTo(...)
            }
          }
        }
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
      final notifier = ref.read(tappingProvider.notifier);
      final audioCtrl = ref.read(audioControllerProvider);
      final state = ref.read(
        tappingProvider,
      ); // Added to access state for play/pause

      if (event.logicalKey == LogicalKeyboardKey.space) {
        // Play/Pause toggle
        if (state.isPlaying) {
          audioCtrl.pause();
          notifier.setPlaying(false);
        } else {
          audioCtrl.play();
          notifier.setPlaying(true);
        }
      } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        // Rewind 5s
        audioCtrl.seekBackward(const Duration(seconds: 5));
      } else if (event.logicalKey == LogicalKeyboardKey.keyZ &&
          HardwareKeyboard.instance.isControlPressed) {
        // Undo
        notifier.undo();
        audioCtrl.seekBackward(const Duration(seconds: 5));
      } else if (event.logicalKey == LogicalKeyboardKey.keyF &&
          HardwareKeyboard.instance.isControlPressed) {
        // Footnote flagging
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Footnote flagged at current word")),
        );
        // TODO: In a real app, store this in an 'annotations' map in the state
      }
      // Add more shortcuts as needed
    }
  }

  // Auto-Save method
  void _autoSave() async {
    final state = ref.read(tappingProvider);
    if (state.words.isEmpty) return;

    await ExportService.saveAutoSave(state.words);

    // Optional: Log success if needed
    // debugPrint("Auto-saved");
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tappingProvider);
    final notifier = ref.read(tappingProvider.notifier);
    final audioCtrl = ref.read(audioControllerProvider);

    // Auto-scroll logic: Check if current index is valid and scroll if needed
    // This is basic; for "Follow Audio" verification mode we need more complex logic later.
    if (state.words.isNotEmpty && state.currentIndex < state.words.length) {
      // Basic keeping visible logic can be added here
    }

    return KeyboardListener(
      focusNode: _keyboardFocus,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Tapping Session"),
          actions: [
            IconButton(
              icon: Icon(
                state.isVerificationMode ? Icons.check_circle : Icons.edit,
              ),
              onPressed: notifier.toggleVerificationMode,
              tooltip: state.isVerificationMode
                  ? "Switch to Tapping Mode"
                  : "Switch to Verification Mode",
            ),
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: () async {
                final String? result = await FilePicker.platform
                    .getDirectoryPath();
                if (result != null) {
                  try {
                    await ExportService.exportFiles(result, state.words);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Exported to $result")),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Export failed: $e"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // Top: Waveform & Transport Controls (Placeholder for now)
            Container(
              height: 150,
              color: Colors.black12,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Audio Waveform Visualization Here"),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.replay_5),
                          onPressed: () => audioCtrl.seekBackward(
                            const Duration(seconds: 5),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            state.isPlaying ? Icons.pause : Icons.play_arrow,
                          ),
                          onPressed: () {
                            if (state.isPlaying) {
                              audioCtrl.pause();
                              notifier.setPlaying(false);
                            } else {
                              audioCtrl.play();
                              notifier.setPlaying(true);
                            }
                          },
                        ),
                        // Speed Slider
                        SizedBox(
                          width: 150,
                          child: Slider(
                            value: state.playbackSpeed,
                            min: 0.5,
                            max: 2.0,
                            divisions: 6,
                            label: "${state.playbackSpeed}x",
                            onChanged: (val) {
                              notifier.setSpeed(val);
                              audioCtrl.setSpeed(val);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Bottom: Word Grid
            Expanded(
              child: GridView.builder(
                controller: _gridScrollController,
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 150,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 2.0,
                ),
                itemCount: state.words.length,
                itemBuilder: (context, index) {
                  final word = state.words[index];
                  final bool isActive = index == state.currentIndex;
                  final bool isTapped = index < state.currentIndex;

                  return WordButton(
                    word: word,
                    isActive: isActive,
                    isTapped: isTapped,
                    playbackSpeed: state.playbackSpeed,
                    onPointerDown: () {
                      if (!state.isVerificationMode) {
                        // We need the current position from the player
                        // Since AudioController hides the player, we need to add a method to get it
                        // For now, let's assume we update AudioController or access it via a hack/stream-cache?
                        // Better: Update AudioController.
                        // But I can't update another file in this tool call.
                        // I will temporarily assume I can access it or I will add the method in next step.
                        // Let's use a workaround: The value isn't read here, we just start the visual.
                        // The actual assignment happens in the Notifier?
                        // No, we need to pass the timestamp to the Notifier.

                        // Note: I will update AudioController to expose `currentPosition` in the next step.
                        // Here I'll call a method that I will add: `audioCtrl.currentPosition`.
                        final position = audioCtrl.currentPosition;
                        final updatedWord = word.copyWith(
                          startTime: position.inMilliseconds,
                        );
                        notifier.updateWord(index, updatedWord);
                      } else {
                        // Verification Mode: Seek to start
                        if (word.startTime != null) {
                          audioCtrl.seek(
                            Duration(milliseconds: word.startTime!),
                          );
                        }
                      }
                    },
                    onPointerUp: () {
                      if (!state.isVerificationMode && isActive) {
                        final position = audioCtrl.currentPosition;
                        final updatedWord = word.copyWith(
                          endTime: position.inMilliseconds,
                        );
                        notifier.updateWord(index, updatedWord);
                        notifier.nextWord();
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
