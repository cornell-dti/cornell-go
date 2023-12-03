import 'package:flutter/material.dart';
import 'package:game/utils/utility_functions.dart';

/**
 * Widget that represents each individual leaderboard entry
 * @param name: name of the user
 * @param position: the place that the user is in overall
 * @param points: the number of points the user has
 * @param isUser: whether the cell is the current user and should be hilighted
 */
Widget leaderBoardCell(
    context, String name, int position, int points, bool isUser) {
  //Creating the styles to use for the position, name, and points
  var posStyle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 23,
    fontWeight: FontWeight.w500,
    height: 1.42,
    letterSpacing: 0.0,
    color: Colors.black,
  );
  var nameStyle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.5,
    letterSpacing: 0,
    color: Colors.black,
  );
  var pointStyle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 1.5455,
    letterSpacing: 0,
    color: Colors.black,
  );

  return Container(
      decoration: BoxDecoration(
        color: (isUser) ? Color.fromARGB(255, 251, 227, 195) : Colors.white,
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.74),
        child: ClipRRect(
          child: Container(
            width: 266,
            height: 34,
            child: Row(
              children: [
                Row(
                  children: [
                    Container(
                      child: Row(
                        children: [
                          Text(position.toString(),
                              style: posStyle, textAlign: TextAlign.center),
                          Padding(
                            padding: const EdgeInsets.only(left: 12.0),
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                  color: constructColorFromUserName(name),
                                  borderRadius: BorderRadius.circular(15)),
                            ),
                          )
                        ],
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0),
                      child: Container(
                        child: Text(name, style: nameStyle),
                      ),
                    ),
                  ],
                ),
                Container(
                  child: Text(
                    points.toString() + " points",
                    style: pointStyle,
                  ),
                )
              ],
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
            ),
          ),
        ),
      ));
}
