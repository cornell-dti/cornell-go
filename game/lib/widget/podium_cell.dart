import 'package:flutter/material.dart';
import 'package:game/utils/utility_functions.dart';

/**
 * This widget represents the users which are in the top 3 positions! They have
 * a different representation than the other users in the leaderboard because
 * they are on the podium.
 * @param name: the name of the user
 * @param position: the position the user ranked overall
 * @param points: the number of points the user has scored
 * @param isUser: whether the active user is the current podium cell
 */
Widget podiumCell(context, String name, int position, int points, bool isUser) {
  var nameStyle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 11.0,
    fontWeight: FontWeight.w500,
    height: 17.0 / 11.0,
    letterSpacing: 0.0,
  );

  var pointStyle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 11.0,
    fontWeight: FontWeight.w400,
    height: 17.0 / 11.0,
    letterSpacing: 0.0,
  );

  return Column(children: [
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
  ]);
}
