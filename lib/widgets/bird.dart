import 'package:flutter/material.dart';

class Bird extends StatelessWidget {
  late final Rect rect;
  final double size = 80;

  Bird(x, y, {Key? key}) : super(key: key) {
    rect = Rect.fromCenter(
      center: Offset(x, y),
      width: size,
      height: size,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fromRect(
      rect: rect,
      child: Image.asset('images/bird-sprite.png'),
    );
  }
}
