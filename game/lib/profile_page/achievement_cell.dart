import 'package:flutter/material.dart';
import 'package:game/utils/utility_functions.dart';

/**
 * Widget that represents each individual achievement
 * @param name: Name of the achievement
 * @param tasksFinished: Number of currently completed tasks towards the achievement
 * @param totalTasks: Total number of tasks needed to gain achievement
 * @param picture: picture that is associated with the achievement
 */
Widget achievementCell(
    context, String name, int tasksFinished, int totalTasks, String picture) {
  var nameStyle = TextStyle(
    color: Color(0xFF000000),
    fontFamily: 'Poppins',
    fontSize: 11.512,
    fontStyle: FontStyle.normal,
    fontWeight: FontWeight.w500,
    height: 1.5,
  );
  var progStyle = TextStyle(
    color: Color(0xFF6E6E6E),
    fontFamily: 'Poppins',
    fontSize: 8.741,
    fontStyle: FontStyle.normal,
    fontWeight: FontWeight.w600,
    height: 1.25,
  );

  return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 19.65, 15),
        child: Container(
          width: 261,
          height: 59,
          child: Row(
            children: [
              Container(
                width: 59,
                height: 59,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: constructColorFromUserName(name),
                    borderRadius: BorderRadius.circular(10)),
              ),
              SizedBox(width: 18),
              Column(
                children: [
                  Container(
                    child: Text("Complete these challenges on the arts quad",
                        style: nameStyle, textAlign: TextAlign.center),
                  ),
                  SizedBox(height: 9),
                  Container(
                      //Progress Bar
                      //Icon
                      //Completion Status
                      )
                ],
              )
            ],
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
          ),
        ),
      ));
}
