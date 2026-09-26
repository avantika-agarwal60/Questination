import 'dart:math';
import 'package:flutter/material.dart';

/// Wraps two pages in a 3-D flip animation.
///
/// [frontPage] is visible before the flip, [backPage] after.
/// Call [flip()] on the state via a GlobalKey to trigger the animation.
/// [pivotOnLeft] = true means the page flips from the right edge (next-page flip).
/// [pivotOnLeft] = false means it flips from the left edge (prev-page flip).
class PageFlipWidget extends StatefulWidget {
  final Widget frontPage;
  final Widget backPage;
  final bool pivotOnLeft;
  final VoidCallback onFlipComplete;

  const PageFlipWidget({
    super.key,
    required this.frontPage,
    required this.backPage,
    required this.pivotOnLeft,
    required this.onFlipComplete,
  });

  @override
  State<PageFlipWidget> createState() => PageFlipWidgetState();
}

class PageFlipWidgetState extends State<PageFlipWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onFlipComplete();
      }
    });
    // Start the flip automatically when created
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final alignment =
        widget.pivotOnLeft ? Alignment.centerLeft : Alignment.centerRight;

    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final angle = _anim.value * pi;
        final isFrontVisible = angle < pi / 2;

        // When showing the back, we need to mirror it so it reads correctly
        Widget content;
        if (isFrontVisible) {
          content = widget.frontPage;
        } else {
          // Mirror around Y axis to un-flip the back face text
          content = Transform(
            transform: Matrix4.identity()..rotateY(pi),
            alignment: Alignment.center,
            child: widget.backPage,
          );
        }

        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0008) // perspective
            ..rotateY(widget.pivotOnLeft ? -angle : angle),
          alignment: alignment,
          child: content,
        );
      },
    );
  }
}
