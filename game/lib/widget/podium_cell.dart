import 'package:flutter/material.dart';
import 'package:game/utils/utility_functions.dart';

/**
 * This widget represents the users which are in the top 3 positions! They have
 * a different representation than the other users in the leaderboard because
 * they are on the podium.
 * @param name: the name of the user
 * @param points: the number of points the user has scored
 */
Widget podiumCell(context, String name, int points) {
  // var nameStyle = TextStyle(
  //   fontFamily: 'Inter',
  //   fontSize: 11.0,
  //   fontWeight: FontWeight.w500,
  //   height: 17.0 / 11.0,
  //   letterSpacing: 0.0,
  // );
  var nameStyle = TextStyle(
    color: Color(0xFF000000), // Color(0xFF000000) represents the color #000
    fontFamily: 'Inter',
    fontSize: 11.392, // Font size in logical pixels
    fontStyle: FontStyle.normal,
    fontWeight: FontWeight.w500,
    height: 1.5, // Corresponds to a line height of 150%
  );

  var pointStyle = TextStyle(
    color: Color(0xFF000000), // Color(0xFF000000) represents the color #000
    fontFamily: 'Inter',
    fontSize: 11.392, // Font size in logical pixels
    fontStyle: FontStyle.normal,
    fontWeight: FontWeight.w400,
    height: 1.5, // Corresponds to a line height of 150%
  );
  // var pointStyle = TextStyle(
  //   fontFamily: 'Inter',
  //   fontSize: 11.0,
  //   fontWeight: FontWeight.w400,
  //   height: 17.0 / 11.0,
  //   letterSpacing: 0.0,
  // );
  if (name.length > 13) name = name.substring(0, 10) + "...";
  return Container(
      width: 78,
      height: 88.824,
      child: Column(children: [
        Container(
          width: 49.128,
          height: 49.128,
          decoration: BoxDecoration(
              color: constructColorFromUserName(name),
              borderRadius: BorderRadius.circular(49.128)),
        ),
        Text(name, style: nameStyle, textAlign: TextAlign.center),
        Text(points.toString() + " points",
            style: pointStyle, textAlign: TextAlign.center),
      ]));
}
