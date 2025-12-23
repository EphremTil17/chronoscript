import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sync_word.dart';

// --- State Classes ---

class TappingState {
  final List<SyncWord> words;
  final int
  currentIndex; // The word currently being tapped (or waiting to be tapped)
  final bool isPlaying;
  final double playbackSpeed;
  final bool
  isVerificationMode; // False = Tapping Mode, True = Verification Mode

  const TappingState({
    this.words = const [],
    this.currentIndex = 0,
    this.isPlaying = false,
    this.playbackSpeed = 1.0,
    this.isVerificationMode = false,
  });

  TappingState copyWith({
    List<SyncWord>? words,
    int? currentIndex,
    bool? isPlaying,
    double? playbackSpeed,
    bool? isVerificationMode,
  }) {
    return TappingState(
      words: words ?? this.words,
      currentIndex: currentIndex ?? this.currentIndex,
      isPlaying: isPlaying ?? this.isPlaying,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      isVerificationMode: isVerificationMode ?? this.isVerificationMode,
    );
  }
}

// --- Providers ---

// The main state notifier for the tapping session
class TappingNotifier extends StateNotifier<TappingState> {
  TappingNotifier() : super(const TappingState());

  void setWords(List<SyncWord> words) {
    state = state.copyWith(words: words, currentIndex: 0);
  }

  void updateWord(int index, SyncWord updatedWord) {
    final newWords = List<SyncWord>.from(state.words);
    newWords[index] = updatedWord;
    state = state.copyWith(words: newWords);
  }

  void nextWord() {
    if (state.currentIndex < state.words.length - 1) {
      state = state.copyWith(currentIndex: state.currentIndex + 1);
    }
  }

  void setIndex(int index) {
    state = state.copyWith(currentIndex: index);
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

  // Undo Logic (Simplified for now, just rewinds index, caller handles clearing data)
  void undo() {
    if (state.currentIndex > 0) {
      state = state.copyWith(currentIndex: state.currentIndex - 1);
    }
  }
}

final tappingProvider = StateNotifierProvider<TappingNotifier, TappingState>((
  ref,
) {
  return TappingNotifier();
});

// For loading audio file path
final audioPathProvider = StateProvider<String?>((ref) => null);
