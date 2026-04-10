import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:til1m/core/constants/app_constants.dart';
import 'package:til1m/domain/entities/word.dart';
import 'package:til1m/domain/entities/word_progress.dart';
import 'package:til1m/presentation/widgets/flashcard/back_face.dart';
import 'package:til1m/presentation/widgets/flashcard/flashcard_front_face.dart';

class FlashcardCard extends StatefulWidget {
  const FlashcardCard({
    required this.word,
    required this.progress,
    required this.isCurrentReview,
    required this.isFlipped,
    required this.isAudioPlaying,
    required this.onFlip,
    required this.onKnow,
    required this.onDontKnow,
    required this.onAudio,
    super.key,
  });

  final Word word;
  final WordProgress progress;
  final bool isCurrentReview;
  final bool isFlipped;
  final bool isAudioPlaying;
  final VoidCallback onFlip;
  final VoidCallback onKnow;
  final VoidCallback onDontKnow;
  final VoidCallback onAudio;

  @override
  State<FlashcardCard> createState() => _FlashcardCardState();
}

class _FlashcardCardState extends State<FlashcardCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flipController;
  late final Animation<double> _flipAnimation;

  double _dragDx = 0;
  double _dragDy = 0;

  static const _flipDuration = Duration(milliseconds: 400);
  static const _swipeThreshold = 90.0;
  static const _perspective = 0.001;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(duration: _flipDuration, vsync: this);
    _flipAnimation = Tween<double>(begin: 0, end: pi).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
    if (widget.isFlipped) _flipController.value = 1;
  }

  @override
  void didUpdateWidget(FlashcardCard old) {
    super.didUpdateWidget(old);
    if (widget.isFlipped && !old.isFlipped) {
      unawaited(_flipController.forward());
    } else if (!widget.isFlipped && old.isFlipped) {
      unawaited(_flipController.reverse());
    }
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails d) {
    setState(() {
      _dragDx += d.delta.dx;
      _dragDy += d.delta.dy;
    });
  }

  void _onPanEnd(DragEndDetails _) {
    if (_dragDx.abs() > _swipeThreshold) {
      if (_dragDx > 0) {
        widget.onKnow();
      } else {
        widget.onDontKnow();
      }
    } else if (_dragDy < -_swipeThreshold / 2 && !widget.isFlipped) {
      widget.onFlip();
    }
    setState(() {
      _dragDx = 0;
      _dragDy = 0;
    });
  }

  void _onPanCancel() => setState(() {
    _dragDx = 0;
    _dragDy = 0;
  });

  @override
  Widget build(BuildContext context) {
    final absOffset = _dragDx.abs();
    final tiltAngle = _dragDx / 2000;
    final overlayOpacity = absOffset < 20
        ? 0.0
        : ((absOffset - 20) / (_swipeThreshold - 20)).clamp(0.0, 0.55);
    final isSwipingRight = _dragDx > 0;
    final isSwipingLeft = _dragDx < 0;

    return GestureDetector(
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      onPanCancel: _onPanCancel,
      child: Transform.rotate(
        angle: tiltAngle,
        child: AnimatedBuilder(
          animation: _flipAnimation,
          builder: (context, _) {
            final angle = _flipAnimation.value;
            final showFront = angle <= pi / 2;

            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, _perspective)
                ..rotateY(angle),
              child: Stack(
                children: [
                  if (showFront)
                    FlashcardFrontFace(
                      word: widget.word,
                      progress: widget.progress,
                      isCurrentReview: widget.isCurrentReview,
                      isAudioPlaying: widget.isAudioPlaying,
                      onFlip: widget.onFlip,
                      onAudio: widget.onAudio,
                    )
                  else
                    Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()..rotateY(pi),
                      child: BackFace(
                        word: widget.word,
                        onKnow: widget.onKnow,
                        onDontKnow: widget.onDontKnow,
                      ),
                    ),

                  if (overlayOpacity > 0)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusXXL,
                        ),
                        child: ColoredBox(
                          color: isSwipingRight
                              ? Colors.green.withValues(alpha: overlayOpacity)
                              : isSwipingLeft
                              ? Colors.red.withValues(alpha: overlayOpacity)
                              : Colors.transparent,
                        ),
                      ),
                    ),

                  if (overlayOpacity > 0.15)
                    Positioned(
                      top: AppConstants.paddingXXL,
                      left: isSwipingRight ? AppConstants.paddingXXL : null,
                      right: isSwipingLeft ? AppConstants.paddingXXL : null,
                      child: _SwipeLabel(
                        label: isSwipingRight ? '✓ Знаю' : '✗ Не знаю',
                        color: isSwipingRight ? Colors.green : Colors.red,
                        opacity: (overlayOpacity * 2).clamp(0, 1),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SwipeLabel extends StatelessWidget {
  const _SwipeLabel({
    required this.label,
    required this.color,
    required this.opacity,
  });

  final String label;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingL,
            vertical: AppConstants.paddingS,
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
