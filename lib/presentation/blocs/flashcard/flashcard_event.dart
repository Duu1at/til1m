part of 'flashcard_bloc.dart';

sealed class FlashcardEvent {
  const FlashcardEvent();
}

/// Build and start a brand-new session from scratch.
final class FlashcardStartSession extends FlashcardEvent {
  const FlashcardStartSession({required this.source});

  final FlashcardSource source;
}

/// Restore the last persisted session (crash / background recovery).
final class FlashcardResumeSession extends FlashcardEvent {
  const FlashcardResumeSession();
}

/// Flip the current card from front to back (or back to front).
final class FlashcardFlipCard extends FlashcardEvent {
  const FlashcardFlipCard();
}

/// Submit an answer for the current card.
final class FlashcardAnswer extends FlashcardEvent {
  const FlashcardAnswer({required this.isCorrect});

  final bool isCorrect;
}

/// Undo the last submitted answer (re-queues the word).
final class FlashcardUndo extends FlashcardEvent {
  const FlashcardUndo();
}

/// Skip the current card without scoring it.
final class FlashcardSkip extends FlashcardEvent {
  const FlashcardSkip();
}

/// Play the TTS pronunciation of the current word.
final class FlashcardPlayAudio extends FlashcardEvent {
  const FlashcardPlayAudio();
}

/// Finish the session early and show the summary screen.
final class FlashcardEndSession extends FlashcardEvent {
  const FlashcardEndSession();
}

/// Append more new words to the current session queue.
final class FlashcardLoadMore extends FlashcardEvent {
  const FlashcardLoadMore();
}

/// Internal — dispatched by the connectivity subscription so that
/// `FlashcardBloc` can call `emit` from within a proper event handler.
final class _ConnectivityChanged extends FlashcardEvent {
  const _ConnectivityChanged({required this.isOnline});

  final bool isOnline;
}
