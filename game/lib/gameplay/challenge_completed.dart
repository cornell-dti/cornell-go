import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:game/api/geopoint.dart';
import 'package:flutter/cupertino.dart';

import 'package:flutter_svg/flutter_svg.dart';

class ChallengeCompleted extends StatefulWidget {
  final GeoPoint targetLocation;
  final double awardingRadius;
  final String description;
  final int points;
  final int numHintsLeft;

  const ChallengeCompleted(
      {Key? key,
      required this.targetLocation,
      required this.awardingRadius,
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
        body: Container(
      height: MediaQuery.of(context).size.height,
      child: SvgPicture.asset(
        'assets/image/challenge-completed-bg.svg', // Replace with your SVG file path
        fit: BoxFit.cover,
      ),
    ));
  }
}
