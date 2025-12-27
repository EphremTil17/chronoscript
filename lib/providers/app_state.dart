import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sync_word.dart';
import '../models/verse.dart';

// --- State Classes ---

class TappingState {
  final List<Verse> verses;
  final int selectedVerseIndex;

  // Computed helpers
  Verse get currentVerse => verses.isNotEmpty
      ? verses[selectedVerseIndex]
      : const Verse(id: 'empty', words: []);
  List<SyncWord> get currentWords => currentVerse.words;

  // Selection & Recording
  final int selectedWordIndex; // The word currently highlighted (Blue Border)
  final int?
  recordingWordIndex; // The word pending an END timestamp (Red state)

  final bool isPlaying;
  final double playbackSpeed;
  final bool isVerificationMode;

  bool get isRecording => recordingWordIndex != null;

  const TappingState({
    this.verses = const [],
    this.selectedVerseIndex = 0,
    this.selectedWordIndex = 0,
    this.recordingWordIndex,
    this.isPlaying = false,
    this.playbackSpeed = 1.0,
    this.isVerificationMode = false,
  });

  TappingState copyWith({
    List<Verse>? verses,
    int? selectedVerseIndex,
    int? selectedWordIndex,
    int? recordingWordIndex,
    bool? isPlaying,
    double? playbackSpeed,
    bool? isVerificationMode,
    bool clearRecording = false, // Helper to set recordingWordIndex to null
  }) {
    return TappingState(
      verses: verses ?? this.verses,
      selectedVerseIndex: selectedVerseIndex ?? this.selectedVerseIndex,
      selectedWordIndex: selectedWordIndex ?? this.selectedWordIndex,
      recordingWordIndex: clearRecording
          ? null
          : (recordingWordIndex ?? this.recordingWordIndex),
      isPlaying: isPlaying ?? this.isPlaying,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      isVerificationMode: isVerificationMode ?? this.isVerificationMode,
    );
  }
}

// --- Providers ---

class TappingNotifier extends StateNotifier<TappingState> {
  TappingNotifier() : super(const TappingState());

  void setVerses(List<Verse> verses) {
    state = state.copyWith(
      verses: verses,
      selectedVerseIndex: 0,
      selectedWordIndex: 0,
      clearRecording: true,
    );
  }

  void selectVerse(int index) {
    if (index >= 0 && index < state.verses.length) {
      state = state.copyWith(
        selectedVerseIndex: index,
        selectedWordIndex: 0,
        clearRecording: true, // Reset recording on verse change
      );
    }
  }

  void selectWord(int index) {
    if (state.isRecording) return; // Locked during recording
    if (index >= 0 && index < state.currentWords.length) {
      state = state.copyWith(selectedWordIndex: index);
    }
  }

  // Called when Green Button is clicked
  void startRecordingWord(int startTimeMs) {
    final index = state.selectedWordIndex;
    final word = state.currentWords[index];

    // Update word with START time, clear END time
    // We create a new word directly to handle null endTime (since copyWith might ignore it)
    // Need way to set null. SyncWord copyWith should support it if we designed it right.
    // Assuming copyWith(endTime: null) works if we didn't default it.
    // Actually my copyWith implementation usually ignores nulls.
    // So I might need to reconstruct the object or update copyWith.
    // For now, let's create a new word.
    final newWord = SyncWord(
      id: word.id,
      text: word.text,
      startTime: startTimeMs,
      endTime: null,
      isParagraphStart: word.isParagraphStart,
    );

    _updateWordAtIndex(index, newWord);
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

  void undo() {
    // Basic undo: just clear the last recording if active?
    // Or move selection back?
    // User asked for "Manual Flexibility", so maybe undo isn't critical right now.
    // But let's implement selection fallback for now.
    if (state.selectedWordIndex > 0) {
      state = state.copyWith(selectedWordIndex: state.selectedWordIndex - 1);
    }
  }

  void resetWord(int index) {
    if (state.isRecording) return; // Prevent reset during recording
    if (index < 0 || index >= state.currentWords.length) return;

    final word = state.currentWords[index];
    final resetWord = SyncWord(
      id: word.id,
      text: word.text,
      startTime: null,
      endTime: null,
      isParagraphStart: word.isParagraphStart,
    );

    _updateWordAtIndex(index, resetWord);
  }
}

final tappingProvider = StateNotifierProvider<TappingNotifier, TappingState>((
  ref,
) {
  return TappingNotifier();
});

// For loading audio file path
final audioPathProvider = StateProvider<String?>((ref) => null);
