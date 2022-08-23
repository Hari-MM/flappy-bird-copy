import 'package:flutter/material.dart';

class Background extends StatelessWidget {
  final Rect floorRect;

  const Background(this.floorRect, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Container(
            color: Colors.lightBlue.shade200,
          ),
        ),
        Container(height: floorRect.height, color: Colors.brown),
      ],
    );
  }
}
