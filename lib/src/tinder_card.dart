import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

class CardModel {
  final int id;
  const CardModel({required this.id});
}

class TinderCard extends StatefulWidget {
  static const defaultAnimationDuration = Durations.medium3;

  final Widget child;
  final VoidCallback onLeft;
  final VoidCallback onRight;
  final EdgeInsets padding;
  final BoxConstraints cardConstraints;
  final bool startVisible;
  const TinderCard({
    super.key,
    required this.child,
    required this.onLeft,
    required this.onRight,
    this.startVisible = true,
    this.padding = EdgeInsets.zero,
    this.cardConstraints = const BoxConstraints(maxWidth: 300),
  });

  @override
  State<TinderCard> createState() => TinderCardState();
}

class TinderCardState extends State<TinderCard> with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    positionCardAnimation.addListener(() {
      _setPositionAndRotation(Offset(positionCardAnimation.value, 0));
    });
  }

  final isDraggingNotifier = ValueNotifier(false);
  final data = ValueNotifier((position: Offset.zero, rotation: 0.0));

  late final controller = AnimationController(
    vsync: this,
    duration: TinderCard.defaultAnimationDuration,
    value: 0,
  );
  late var positionCardAnimation = Tween<double>(begin: 0, end: 300).animate(controller);
  late var opacityCardAnimation = (widget.startVisible)
      ? Tween<double>(begin: 1, end: 0).animate(controller)
      : Tween<double>(begin: 0, end: 1).animate(controller);

  double get saveIconOpacity {
    return max(0, min(1, lerpDouble(0, 1, data.value.position.dx / 200) ?? 0));
  }

  double get removeIconOpacity {
    return max(0, min(1, lerpDouble(0, 1, data.value.position.dx / -200) ?? 0));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: opacityCardAnimation,
      builder: (context, child) => Opacity(
        opacity: opacityCardAnimation.value,
        child: child,
      ),
      child: Stack(
        children: [
          Center(
            child: GestureDetector(
              onHorizontalDragStart: (details) {
                isDraggingNotifier.value = true;
              },
              onHorizontalDragEnd: (details) {
                isDraggingNotifier.value = false;
                final action = switch (data.value.position.dx) {
                  > 100 => animateRight,
                  < -100 => animateLeft,
                  _ => _runResetCardAnimation
                };
                action.call();
              },
              onHorizontalDragUpdate: (details) {
                _setPositionAndRotation(
                  data.value.position + Offset(details.delta.dx, 0),
                );
              },
              child: ValueListenableBuilder(
                valueListenable: data,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: value.position,
                    child: Transform.rotate(
                      alignment: (value.position.dx.isNegative) //
                          ? const Alignment(-1, 0.2)
                          : const Alignment(1, 0.2),
                      angle: value.rotation,
                      child: child!,
                    ),
                  );
                },
                child: Padding(
                  padding: widget.padding,
                  child: Stack(
                    children: [
                      ConstrainedBox(
                        constraints: widget.cardConstraints,
                        child: ValueListenableBuilder(
                          valueListenable: isDraggingNotifier,
                          builder: (context, isDragging, child) {
                            return Card(
                              elevation: isDragging ? 5 : 0,
                              child: SizedBox(
                                width: double.infinity,
                                height: double.infinity,
                                child: widget.child,
                              ),
                            );
                          },
                        ),
                      ),
                      Positioned.fill(
                        child: ValueListenableBuilder(
                          valueListenable: data,
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: removeIconOpacity,
                              child: child,
                            );
                          },
                          child: IgnorePointer(
                            child: Padding(
                              padding: const EdgeInsets.all(25),
                              child: FittedBox(
                                fit: BoxFit.contain,
                                child: CircleAvatar(
                                  backgroundColor: Color.lerp(Colors.red, Colors.white, 0.6),
                                  foregroundColor: Colors.red,
                                  child: const Icon(Icons.delete_outline_outlined),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: ValueListenableBuilder(
                          valueListenable: data,
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: saveIconOpacity,
                              child: child,
                            );
                          },
                          child: const IgnorePointer(
                            child: Padding(
                              padding: EdgeInsets.all(25),
                              child: FittedBox(
                                fit: BoxFit.contain,
                                child: CircleAvatar(
                                  child: Icon(Icons.bookmark_added),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Animates the card to right AND executes the `onRight` callback
  Future<void> animateRight() {
    return _runRightAnimation().whenComplete(widget.onRight);
  }

  /// Animates the card to left AND executes the `onLeft` callback
  Future<void> animateLeft() {
    return _runLeftAnimation().whenComplete(widget.onLeft);
  }

  void _setPositionAndRotation(Offset position) {
    final rotation = lerpDouble(0, 0.5, min(1, max(-1, data.value.position.dx / 200)));
    data.value = (
      position: position,
      rotation: -(rotation ?? 0),
    );
  }

  Future<void> animateLeftRollBack() {
    final xEnd = -_horizontalAnimationValue();
    return _rollBack(xEnd);
  }

  Future<void> animateRightRollBack() async {
    final xEnd = _horizontalAnimationValue();
    return _rollBack(xEnd);
  }

  Future<void> _rollBack(double xEnd) async {
    controller.value = 1;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      const xBegin = 0.0;
      opacityCardAnimation = Tween<double>(begin: 1, end: 0).animate(controller);
      positionCardAnimation = Tween<double>(begin: xBegin, end: xEnd).animate(controller);
      isDraggingNotifier.value = true;
      controller.reverse(from: 1).whenComplete(() {
        controller.reset();
        _setPositionAndRotation(Offset.zero);
        isDraggingNotifier.value = false;
      });
    });
    return Future.delayed(TinderCard.defaultAnimationDuration);
  }

  Future<void> _runRightAnimation() async {
    final xDistance = _horizontalAnimationValue();

    final xBegin = data.value.position.dx;
    final xEnd = max(xDistance, data.value.position.dx + 300.0);

    opacityCardAnimation = Tween<double>(begin: 1, end: 0).animate(controller);
    positionCardAnimation = Tween<double>(begin: xBegin, end: xEnd).animate(controller);
    await controller.forward(from: 0);
  }

  Future<void> _runLeftAnimation() async {
    final xDistance = _horizontalAnimationValue();
    final xBegin = data.value.position.dx;
    final xEnd = min(-xDistance, data.value.position.dx - 300.0);

    opacityCardAnimation = Tween<double>(begin: 1, end: 0).animate(controller);
    positionCardAnimation = Tween<double>(begin: xBegin, end: xEnd).animate(controller);
    await controller.forward(from: 0);
  }

  Future<void> _runResetCardAnimation() async {
    const xBegin = 0.0;
    final xEnd = data.value.position.dx;
    opacityCardAnimation = const AlwaysStoppedAnimation(1);
    positionCardAnimation = Tween<double>(begin: xBegin, end: xEnd).animate(controller);
    await controller.reverse(from: 1);
  }

  double _horizontalAnimationValue() {
    if (widget.cardConstraints.hasBoundedWidth) {
      return widget.cardConstraints.maxWidth;
    } else if (context.size case Size contextSize) {
      return contextSize.width;
    } else {
      return MediaQuery.sizeOf(context).width * 0.7;
    }
  }
}
