import 'package:flutter/material.dart';

class Pipe extends StatelessWidget {
  final Rect rect;

  const Pipe(this.rect, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned.fromRect(
      rect: rect,
      child: Container(color: Colors.green),
    );
  }
}
