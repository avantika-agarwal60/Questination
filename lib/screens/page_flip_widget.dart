import 'dart:math';

import 'package:flutter/material.dart';

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
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onFlipComplete();
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final alignment =
        widget.pivotOnLeft ? Alignment.centerLeft : Alignment.centerRight;
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final angle = _animation.value * pi;
        final frontVisible = angle < pi / 2;
        final page = frontVisible
            ? widget.frontPage
            : Transform(
                transform: Matrix4.identity()..rotateY(pi),
                alignment: Alignment.center,
                child: widget.backPage,
              );
        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0008)
            ..rotateY(widget.pivotOnLeft ? -angle : angle),
          alignment: alignment,
          child: page,
        );
      },
    );
  }
}
