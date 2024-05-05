import 'package:flutter/material.dart';

/**
 * A circular progress indicator. Used for loading screens.
 */
class CircularIndicator extends StatelessWidget {
  const CircularIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
        color: Color(0xFFFFFFFF),
        child: Center(child: CircularProgressIndicator()));
  }
}
