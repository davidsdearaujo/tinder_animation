import 'package:flutter/material.dart';

class TinderCardStack extends StatefulWidget {
  final int currentIndex;
  final List<Widget> children;
  const TinderCardStack({
    super.key,
    required this.currentIndex,
    required this.children,
  });

  @override
  State<TinderCardStack> createState() => _TinderCardStackState();
}

class _TinderCardStackState extends State<TinderCardStack> {
  late var delegate = _createDelegate();

  @override
  void didUpdateWidget(covariant TinderCardStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != oldWidget.currentIndex) {
      delegate = _createDelegate();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Flow(
      delegate: delegate,
      children: widget.children,
    );
  }

  TinderCardAnimationFlowDelegate _createDelegate() {
    int? currentIndex;
    if (widget.currentIndex < widget.children.length) {
      currentIndex = widget.currentIndex;
    }
    return TinderCardAnimationFlowDelegate(currentIndex);
  }
}

class TinderCardAnimationFlowDelegate extends FlowDelegate {
  final int? _currentIndex;

  TinderCardAnimationFlowDelegate(this._currentIndex);

  @override
  void paintChildren(FlowPaintingContext context) {
    if (_currentIndex == null) return;

    final nextIndex = _currentIndex + 1;
    if (nextIndex < context.childCount) context.paintChild(nextIndex);

    context.paintChild(_currentIndex);
  }

  @override
  bool shouldRepaint(TinderCardAnimationFlowDelegate oldDelegate) {
    return oldDelegate._currentIndex != _currentIndex;
  }
}
