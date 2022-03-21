import 'package:flutter/widgets.dart';

class GameWidget extends StatefulWidget {
  final Widget _child;
  const GameWidget({Key? key, required Widget child})
      : _child = child,
        super(key: key);

  @override
  _GameWidgetState createState() => _GameWidgetState(_child);
}

class _GameWidgetState extends State<GameWidget> {
  final Widget _child;
  _GameWidgetState(Widget child) : _child = child;
  @override
  Widget build(BuildContext context) {
    return _child;
  }
}
