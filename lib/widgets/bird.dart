import 'package:flutter/material.dart';

class Bird extends StatelessWidget {
  final Rect rect;

  const Bird(this.rect, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned.fromRect(
      rect: rect,
      child: Image.asset('images/bird-sprite.png'),
    );
  }
}
