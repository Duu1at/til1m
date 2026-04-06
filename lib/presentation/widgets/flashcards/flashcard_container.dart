import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:til1m/core/constants/app_constants.dart';
import 'package:til1m/presentation/blocs/flashcards/flashcards_bloc.dart';
import 'package:til1m/presentation/widgets/flashcards/flashcard_back.dart';
import 'package:til1m/presentation/widgets/flashcards/flashcard_front.dart';

/// Animated card that flips between front and back faces.
/// Accepts [isFlipped] from BLoC state and [currentIndex] to reset on card change.
class FlashcardContainer extends StatefulWidget {
  const FlashcardContainer({
    required this.item,
    required this.isFlipped,
    required this.currentIndex,
    required this.uiLanguage,
    required this.onTap,
    super.key,
  });

  final FlashcardItem item;
  final bool isFlipped;
  final int currentIndex;
  final String uiLanguage;
  final VoidCallback onTap;

  @override
  State<FlashcardContainer> createState() => _FlashcardContainerState();
}

class _FlashcardContainerState extends State<FlashcardContainer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppConstants.durationSlow,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void didUpdateWidget(FlashcardContainer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.currentIndex != oldWidget.currentIndex) {
      // New card — reset instantly, no animation
      _controller.reset();
    } else if (widget.isFlipped && !oldWidget.isFlipped) {
      unawaited(_controller.forward());
    } else if (!widget.isFlipped && oldWidget.isFlipped) {
      unawaited(_controller.reverse());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.isFlipped ? null : widget.onTap,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, _) {
          final t = _animation.value;
          final showBack = t > 0.5;

          final Widget face;
          final double angle;

          if (showBack) {
            // Back face rotates from -π to 0 (appears from -90° → 0°)
            angle = (t - 1) * pi;
            face = FlashcardBack(item: widget.item, uiLanguage: widget.uiLanguage);
          } else {
            // Front face rotates from 0 to π (disappears at 90°)
            angle = t * pi;
            face = FlashcardFront(item: widget.item);
          }

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001) // perspective
              ..rotateY(angle),
            child: face,
          );
        },
      ),
    );
  }
}
