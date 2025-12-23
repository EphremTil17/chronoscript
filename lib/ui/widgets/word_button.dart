import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/sync_word.dart';

class WordButton extends StatefulWidget {
  final SyncWord word;
  final bool isActive;
  final bool isTapped; // Visually completed
  final VoidCallback onPointerDown;
  final VoidCallback onPointerUp;
  final double playbackSpeed;

  const WordButton({
    super.key,
    required this.word,
    required this.isActive,
    required this.isTapped,
    required this.onPointerDown,
    required this.onPointerUp,
    this.playbackSpeed = 1.0,
  });

  @override
  State<WordButton> createState() => _WordButtonState();
}

class _WordButtonState extends State<WordButton> with TickerProviderStateMixin {
  // Timer for tracking duration for visual feedback
  Timer? _timer;
  int _elapsedMs = 0;

  @override
  void didUpdateWidget(WordButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) {
      // Became active
    }
  }

  void _startTimer() {
    _elapsedMs = 0;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      setState(() {
        _elapsedMs += 50;
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color getBackgroundColor() {
      if (widget.isActive) {
        return Theme.of(context).colorScheme.primaryContainer;
      }
      if (widget.isTapped) {
        return Theme.of(
          context,
        ).colorScheme.secondaryContainer.withValues(alpha: 0.5);
      }
      return Colors.white;
    }

    Color getBorderColor() {
      if (widget.isActive) {
        return Theme.of(context).colorScheme.primary;
      }
      if (widget.isTapped) {
        return Theme.of(context).colorScheme.secondary;
      }
      return Colors.grey.shade300;
    }

    return Listener(
      onPointerDown: (_) {
        if (!widget.isActive) {
          return; // Only active word starts tapping? Or can we seek by tapping?
        }
        // The requirement says "active word". Seeking is separate logic (click).
        // But for recording, it's the active word.
        _startTimer();
        widget.onPointerDown();
      },
      onPointerUp: (_) {
        if (!widget.isActive) return;
        _stopTimer();
        widget.onPointerUp();
      },
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: getBackgroundColor(),
          border: Border.all(
            color: getBorderColor(),
            width: widget.isActive ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Progressive Fill Background (if active and holding)
            if (widget.isActive && _timer != null)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: null, // Indeterminate or based on expected duration?
                    // Since we don't know how long it will be, maybe just a repeating animation or purely time based visual?
                    // User asked for "elapsed milliseconds".
                    backgroundColor: Colors.transparent,
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.word.text,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: widget.isActive
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: widget.isActive
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : Colors.black87,
                    ),
                  ),
                  if (widget.isActive && _elapsedMs > 0)
                    Text(
                      "${(_elapsedMs / 1000).toStringAsFixed(1)}s",
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.blueGrey,
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
}
