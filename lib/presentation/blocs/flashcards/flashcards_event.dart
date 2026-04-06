import 'package:equatable/equatable.dart';

sealed class FlashcardsEvent extends Equatable {
  const FlashcardsEvent();
}

final class FlashcardsStartRequested extends FlashcardsEvent {
  const FlashcardsStartRequested();

  @override
  List<Object?> get props => [];
}

final class FlashcardsCardFlipRequested extends FlashcardsEvent {
  const FlashcardsCardFlipRequested();

  @override
  List<Object?> get props => [];
}

final class FlashcardsAnswerSubmitted extends FlashcardsEvent {
  const FlashcardsAnswerSubmitted({required this.knew});

  final bool knew;

  @override
  List<Object?> get props => [knew];
}

final class FlashcardsSessionRestarted extends FlashcardsEvent {
  const FlashcardsSessionRestarted();

  @override
  List<Object?> get props => [];
}
