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
  context,
  String name,
  int position,
  int points,
  bool isUser,
) {
  //Creating the styles to use for the position, name, and points
  var posStyle = TextStyle(
    color: Color(0xFF474747),
    fontSize: 20,
    fontFamily: 'Poppins',
    fontWeight: FontWeight.w500,
    height: 0,
  );
  var nameStyle = TextStyle(
    color: Color(0xFF474747),
    fontSize: 14,
    fontFamily: 'Poppins',
    fontWeight: FontWeight.w500,
    height: 0,
  );

  var pointStyle = TextStyle(
    color: Colors.black.withOpacity(0.699999988079071),
    fontSize: 12,
    fontFamily: 'Poppins',
    fontWeight: FontWeight.w600,
    height: 0,
  );

  return Container(
    decoration: ShapeDecoration(
      // Leaderboard cell is highlighted if it is the user
      color: (isUser) ? Color(0xFFFFF8F1) : Colors.white,
      shape: RoundedRectangleBorder(
        side: (isUser)
            ? BorderSide(width: 2, color: Color(0xFFFBDDAF))
            : BorderSide.none,
        borderRadius: BorderRadius.circular(10),
      ),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 13),
      child: Container(
        height: MediaQuery.sizeOf(context).height * 0.075,
        child: Row(
          children: [
            // Position number
            Text(
              position.toString() + ".",
              style: posStyle,
              textAlign: TextAlign.center,
            ),
            // Avatar
            Padding(
              padding: const EdgeInsets.only(left: 12.0),
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: constructColorFromUserName(name),
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
            // Name - takes remaining space
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 10, right: 10),
                child: Text(
                  name,
                  style: nameStyle,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ),
            // Points - fixed width to prevent overflow
            Text(points.toString() + " pts", style: pointStyle),
          ],
        ),
      ),
    ),
  );
}
