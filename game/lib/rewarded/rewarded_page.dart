import 'package:flutter/material.dart';
import 'package:game/model/game_model.dart';

class RewardWidget extends StatefulWidget {
  const RewardWidget({Key? key, required this.homePageState}) : super(key: key);
  final GameModel homePageState;
  @override
  State<RewardWidget> createState() => _RewardWidgetState();
}

class _RewardWidgetState extends State<RewardWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: Color.fromARGB(255, 165, 165, 165),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Congrats!',
              style: TextStyle(fontSize: 80),
            ),
            Icon(
              Icons.star,
              color: Colors.white,
              size: 120.0,
              semanticLabel: 'Text to announce in accessibility modes',
            ),
            const Text(
              'You have found',
              style: TextStyle(fontSize: 40),
            ),
            Text(
              widget.homePageState.name,
              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
            ),
            Text(
              '+1!',
              style: const TextStyle(fontSize: 40),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'Keep Searching',
                style: TextStyle(fontSize: 30),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Colors.red,
                primary: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
