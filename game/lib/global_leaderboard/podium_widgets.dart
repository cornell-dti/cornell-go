import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/**
 * 'PodiumBlock' widget - Displays leaderboard podium 
 * 
 * This file contains a dynamic podium widget block to appear in the leaderboard 
 * page. For each of the 4 possible podium positions (1st,2nd,3rd,Not in top 3) there is,
 *  there is a differet image variation which highlights the corresponding podium in orange.
 * 
 * @param props - Contains:
 * - 'position': Current position of user 
 * - 'scoreList': Number of points for the top 3 users 
 */

var pointsStyle = TextStyle(
  color: Colors.white,
  fontSize: 14,
  fontFamily: 'Poppins',
  fontWeight: FontWeight.w500,
  height: 0,
);

Widget PodiumBlock(context, int position, List scoreList) {
  Map<int, String> svgAssetPaths = {
    0: 'assets/icons/blank_podiums.svg',
    1: 'assets/icons/gold_podiums.svg',
    2: 'assets/icons/silver_podiums.svg',
    3: 'assets/icons/bronze_podiums.svg',
  };

  String svgAssetPath = svgAssetPaths[position] ?? svgAssetPaths[0]!;

  return Padding(
    padding: const EdgeInsets.only(bottom: 10.0),
    child: Stack(alignment: Alignment.bottomCenter, children: <Widget>[
      SvgPicture.asset(
        svgAssetPath,
        width: 360,
        height: 178,
      ),
      Positioned(
        left: 27,
        bottom: 12,
        child: SizedBox(
          width: 60,
          height: 29,
          child: FittedBox(
            alignment: Alignment.center,
            fit: BoxFit.scaleDown,
            child: Text(scoreList[1].toString() + " PTS", style: pointsStyle),
          ),
        ),
      ),
      Positioned(
        left: 150,
        bottom: 25,
        child: SizedBox(
          width: 60,
          height: 29,
          child: FittedBox(
            alignment: Alignment.center,
            fit: BoxFit.scaleDown,
            child: Text(scoreList[0].toString() + " PTS", style: pointsStyle),
          ),
        ),
      ),
      Positioned(
        right: 27,
        bottom: 6,
        child: SizedBox(
          width: 60,
          height: 29,
          child: FittedBox(
            alignment: Alignment.center,
            fit: BoxFit.scaleDown,
            child: Text(scoreList[2].toString() + " PTS", style: pointsStyle),
          ),
        ),
      )
    ]),
  );
}
