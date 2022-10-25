import 'package:flutter/material.dart';
import 'package:game/model/game_model.dart';
import 'dart:ui';

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
      body: Center(
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(widget.homePageState.imageUrl),
              fit: BoxFit.cover,
            ),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text(
                    'Well Done!',
                    style: TextStyle(
                      fontSize: 72,
                      color: Colors.white,
                    ),
                  ),
                  const Icon(
                    Icons.star,
                    color: Colors.yellow,
                    size: 120.0,
                    semanticLabel: 'Text to announce in accessibility modes',
                  ),
                  const Text(
                    'You have found',
                    style: TextStyle(fontSize: 40, color: Colors.white),
                  ),
                  Text(
                    widget.homePageState.name + "!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 48),
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Padding(
                        padding: EdgeInsets.only(
                            left: 25, right: 25, top: 4, bottom: 4),
                        child: const Text(
                          'Continue',
                          style: TextStyle(fontSize: 28),
                        ),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.red,
                        primary: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
