import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:game/api/geopoint.dart';
import 'package:flutter/cupertino.dart';

import 'package:flutter_svg/flutter_svg.dart';

class ChallengeCompleted extends StatefulWidget {
  final String description;
  final int points;
  final int numHintsLeft;

  const ChallengeCompleted(
      {Key? key,
      required this.description,
      required this.points,
      required this.numHintsLeft})
      : super(key: key);

  @override
  State<ChallengeCompleted> createState() => _ChallengeCompletedState();
}

class _ChallengeCompletedState extends State<ChallengeCompleted> {
  int numHintsLeft = 3;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(children: [
      Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: SvgPicture.asset(
            'assets/images/challenge-completed-bg.svg', // Replace with your SVG file path
            fit: BoxFit.cover,
          )),
      Container(
          margin: EdgeInsets.only(
              top: MediaQuery.of(context).size.height * 0.5,
              left: 20,
              right: 20),
          height: MediaQuery.of(context).size.height * 0.5,
          child: Column(children: [
            Container(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'Challenge Complete!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.only(bottom: 30),
              child: Text(
                'You’ve found the Statue on the Arts Quad!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18.0,
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.only(left: 30, bottom: 10),
              alignment: Alignment.centerLeft,
              child: Text(
                'Points',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.only(left: 30, bottom: 50),
              alignment: Alignment.centerLeft,
              child: Text(
                'Points',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ]))
    ]));
  }
}
