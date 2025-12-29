import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sync_word.dart';
import '../models/verse.dart';

// --- State Classes ---
enum TappingTab { sync, preview }

class TappingState {
  final List<Verse> verses;
  final int selectedVerseIndex;

  // Computed helpers
  Verse get currentVerse => verses.isNotEmpty
      ? verses[selectedVerseIndex]
      : const Verse(id: 'empty', words: []);
  List<SyncWord> get currentWords => currentVerse.words;

  final Set<int> selectedWordIndices; // Multi-selection support
  final int?
  recordingWordIndex; // The word pending an END timestamp (Red state)

  // Backward compatibility helper
  int get selectedWordIndex =>
      selectedWordIndices.isNotEmpty ? selectedWordIndices.last : 0;

  final bool isPlaying;
  final double playbackSpeed;
  final bool isVerificationMode;
  final TappingTab currentTab;

  bool get isRecording => recordingWordIndex != null;

  const TappingState({
    this.verses = const [],
    this.selectedVerseIndex = 0,
    this.selectedWordIndices = const {0},
    this.recordingWordIndex,
    this.isPlaying = false,
    this.playbackSpeed = 1.0,
    this.isVerificationMode = false,
    this.currentTab = TappingTab.sync,
  });

  TappingState copyWith({
    List<Verse>? verses,
    int? selectedVerseIndex,
    Set<int>? selectedWordIndices,
    int? recordingWordIndex,
    bool? isPlaying,
    double? playbackSpeed,
    bool? isVerificationMode,
    TappingTab? currentTab,
    bool clearRecording = false, // Helper to set recordingWordIndex to null
  }) {
    return TappingState(
      verses: verses ?? this.verses,
      selectedVerseIndex: selectedVerseIndex ?? this.selectedVerseIndex,
      selectedWordIndices: selectedWordIndices ?? this.selectedWordIndices,
      recordingWordIndex: clearRecording
          ? null
          : (recordingWordIndex ?? this.recordingWordIndex),
      isPlaying: isPlaying ?? this.isPlaying,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      isVerificationMode: isVerificationMode ?? this.isVerificationMode,
      currentTab: currentTab ?? this.currentTab,
    );
  }

  factory TappingState.fromJson(Map<String, dynamic> json) {
    final List<dynamic> versesJson = json['verses'] as List<dynamic>;
    final stateJson = json['state'] as Map<String, dynamic>? ?? {};

    return TappingState(
      verses: versesJson.map((v) => Verse.fromJson(v)).toList(),
      selectedVerseIndex: stateJson['selected_verse_index'] ?? 0,
      currentTab: TappingTab.values.firstWhere(
        (e) => e.name == (stateJson['current_tab'] ?? 'sync'),
        orElse: () => TappingTab.sync,
      ),
    );
  }
}

// --- Providers ---

class TappingNotifier extends StateNotifier<TappingState> {
  TappingNotifier() : super(const TappingState());

  void loadSession(TappingState loadedState) {
    state = loadedState;
  }

  void setVerses(List<Verse> verses) {
    state = state.copyWith(
      verses: verses,
      selectedVerseIndex: 0,
      selectedWordIndices: {0},
      clearRecording: true,
    );
  }

  void selectVerse(int index) {
    if (index >= 0 && index < state.verses.length) {
      state = state.copyWith(
        selectedVerseIndex: index,
        selectedWordIndices: {0},
        clearRecording: true, // Reset recording on verse change
      );
    }
  }

  void selectWord(int index) {
    if (state.isRecording) return;
    if (index >= 0 && index < state.currentWords.length) {
      state = state.copyWith(selectedWordIndices: {index});
    }
  }

  void handleWordTap(
    int index, {
    bool isControlPressed = false,
    bool isShiftPressed = false,
  }) {
    if (state.isRecording) return;
    if (index < 0 || index >= state.currentWords.length) return;

    final newIndices = Set<int>.from(state.selectedWordIndices);

    if (isShiftPressed && newIndices.isNotEmpty) {
      final lastIdx = state.selectedWordIndex;
      final start = index < lastIdx ? index : lastIdx;
      final end = index > lastIdx ? index : lastIdx;
      for (int i = start; i <= end; i++) {
        newIndices.add(i);
      }
    } else if (isControlPressed) {
      if (newIndices.contains(index)) {
        if (newIndices.length > 1) {
          newIndices.remove(index);
        }
      } else {
        newIndices.add(index);
      }
    } else {
      newIndices.clear();
      newIndices.add(index);
    }

    state = state.copyWith(selectedWordIndices: newIndices);
  }

  // Called when Green Button is clicked
  void startRecordingWord(int startTimeMs) {
    final index = state.selectedWordIndex;
    final word = state.currentWords[index];

    final updatedWord = word.copyWith(startTime: startTimeMs, endTime: null);

    _updateWordAtIndex(index, updatedWord);
    state = state.copyWith(recordingWordIndex: index);
  }

  // Called when Red Button is clicked
  void endRecordingWord(int endTimeMs) {
    if (state.recordingWordIndex == null) return;

    final index = state.recordingWordIndex!;
    final word = state.currentWords[index];

    // Ensure End >= Start
    if (word.startTime != null && endTimeMs < word.startTime!) {
      // Warning or clamp? Clamp for safety.
      endTimeMs = word.startTime!;
    }

    final updatedWord = word.copyWith(endTime: endTimeMs);
    _updateWordAtIndex(index, updatedWord);

    state = state.copyWith(clearRecording: true);
  }

  void _updateWordAtIndex(int index, SyncWord newWord) {
    if (state.verses.isEmpty) return;

    final currentVerse = state.verses[state.selectedVerseIndex];
    if (index >= currentVerse.words.length) return;

    // Create updated verse with modified word
    final updatedWords = List<SyncWord>.from(currentVerse.words);
    updatedWords[index] = newWord;

    final updatedVerse = currentVerse.copyWith(words: updatedWords);

    // Create updated verse list
    final updatedVerses = List<Verse>.from(state.verses);
    updatedVerses[state.selectedVerseIndex] = updatedVerse;

    state = state.copyWith(verses: updatedVerses);
  }

  // Chain-Sync: End current, Start next
  void chainWord(int timestamp) {
    if (state.recordingWordIndex == null) return;

    final currentIndex = state.recordingWordIndex!;
    final currentVerse = state.currentVerse;

    // 1. End current word
    endRecordingWord(timestamp);

    // 2. Check if there is a next word
    if (currentIndex + 1 < currentVerse.words.length) {
      // 3. Select next
      selectWord(currentIndex + 1);

      // 4. Start recording next (using SAME timestamp)
      startRecordingWord(timestamp);
    } else {
      // End of verse: just stop (already done by endRecordingWord)
    }
  }

  void setPlaying(bool isPlaying) {
    state = state.copyWith(isPlaying: isPlaying);
  }

  void setSpeed(double speed) {
    state = state.copyWith(playbackSpeed: speed);
  }

  void toggleVerificationMode() {
    state = state.copyWith(isVerificationMode: !state.isVerificationMode);
  }

  void setTab(TappingTab tab) {
    state = state.copyWith(currentTab: tab);
  }

  void undo() {
    if (state.selectedWordIndices.isEmpty) return;
    state = state.copyWith(
      selectedWordIndices: {
        state.selectedWordIndices.reduce((a, b) => a < b ? a : b) - 1,
      }.where((i) => i >= 0).toSet(),
    );
  }

  void resetSelectedWords() {
    if (state.isRecording) return;
    if (state.selectedWordIndices.isEmpty) return;

    final updatedVerses = List<Verse>.from(state.verses);
    final currentVerse = updatedVerses[state.selectedVerseIndex];
    final updatedWords = List<SyncWord>.from(currentVerse.words);

    for (final index in state.selectedWordIndices) {
      final word = updatedWords[index];
      updatedWords[index] = SyncWord(
        id: word.id,
        text: word.text,
        startTime: null,
        endTime: null,
        isParagraphStart: word.isParagraphStart,
      );
    }

    updatedVerses[state.selectedVerseIndex] = currentVerse.copyWith(
      words: updatedWords,
    );
    state = state.copyWith(verses: updatedVerses);
  }
}

final tappingProvider = StateNotifierProvider<TappingNotifier, TappingState>((
  ref,
) {
  return TappingNotifier();
});

// For loading audio file path
final audioPathProvider = StateProvider<String?>((ref) => null);
