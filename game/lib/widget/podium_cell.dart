import 'package:flutter/material.dart';
import 'package:game/constants/constants.dart';
import 'package:game/utils/utility_functions.dart';

/**
 * This widget represents the users which are in the top 3 positions! They have
 * a different representation than the other users in the leaderboard because
 * they are on the podium.
 * @param name: the name of the user
 */
Widget podiumCell(context, String name, bool isUser) {
  var nameStyle = TextStyle(
    color: AppColors.darkText,
    fontSize: 14,
    fontFamily: 'Poppins',
    fontWeight: FontWeight.w500,
    height: 0,
  );

  return Container(
    width: 78,
    height: 88.824,
    child: Column(
      children: [
        Container(
          width: 49.128,
          height: 49.128,
          decoration: BoxDecoration(
            color: constructColorFromUserName(name),
            borderRadius: BorderRadius.circular(49.128),
            border:
                isUser ? Border.all(color: AppColors.orange, width: 2.5) : null,
          ),
        ),
        SizedBox(
          width: 80,
          height: 20,
          child: Text(
            textAlign: TextAlign.center,
            name,
            style: nameStyle,
            // Allowing wrapping of the names in the podium
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}
