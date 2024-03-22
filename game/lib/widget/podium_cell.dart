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
  var nameStyle = TextStyle(
    color: Color(0xFF1E1E1E),
    fontSize: 14,
    fontFamily: 'Poppins',
    fontWeight: FontWeight.w500,
    height: 0,
  );

  var pointStyle = TextStyle(
    color: Color(0xFF000000),
    fontFamily: 'Inter',
    fontSize: 11.392,
    fontStyle: FontStyle.normal,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  // if (name.length > 7) name = name.substring(0, 7) + "...";
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

        // Flexible(child: Text(name, style: nameStyle))
        SizedBox(
          width: 80,
          height: 38,
          child: Text(
            textAlign: TextAlign.center,
            name,
            style: nameStyle,
            overflow:
                TextOverflow.ellipsis, // or TextOverflow.clip for clipping
            softWrap: true, // Allow wrapping
            maxLines: 2,
          ),
        )

        // Text(name, style: nameStyle, textAlign: TextAlign.center),
      ]));
}
