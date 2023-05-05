import 'package:flutter/src/widgets/placeholder.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter_map/flutter_map.dart';

class GameplayMap extends StatefulWidget {
  const GameplayMap({Key? key}) : super(key: key);

  @override
  State<GameplayMap> createState() => _GameplayMapState();
}

class _GameplayMapState extends State<GameplayMap> {
  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(),
      children: [],
      nonRotatedChildren: [],
    );
  }
}
