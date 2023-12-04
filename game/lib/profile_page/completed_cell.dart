import 'package:flutter/material.dart';
import 'package:game/utils/utility_functions.dart';

enum completedType { journey, challenge }

enum challengeLevel { easy, medium, hard }

/**
 * Widget that represents each individual completed journey or challenge
 * @param name: Name of the challenge or journey completed
 * @param type: an enum of type CompeltedType either a journey or challenge
 * @param date: Date that the journey / challenge was completed
 * @param location: picture that is associated with the achievement
 * @param difficulty: level of the task, either easy, medium, or hard
 * @param points: Points that the completed journey / challenge had

 */
Widget completedCell(context, String name, completedType type, String date,
    String location, challengeLevel difficulty, int points) {
  var nameStyle = TextStyle(
    color: Color(0xFF000000), // #000
    fontFamily: 'Poppins',
    fontSize: 10.923,
    fontStyle: FontStyle.normal,
    fontWeight: FontWeight.w600,
    height: 1.5, // 150% converted to decimal (line-height)
  );
  var dateStyle = TextStyle(
    color: Color.fromRGBO(0, 0, 0, 0.80),
    fontFamily: 'Poppins',
    fontSize: 10.203,
    fontStyle: FontStyle.normal,
    fontWeight: FontWeight.w500,
    height: 1.5,
  );
  var typeStyle = TextStyle(
    color: Color.fromRGBO(0, 0, 0, 0.40),
    fontFamily: 'Poppins',
    fontSize: 10.203,
    fontStyle: FontStyle.normal,
    fontWeight: FontWeight.w600,
    height: 1.5,
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
                  Text(name, style: nameStyle, textAlign: TextAlign.center),
                  Row(
                    children: [
                      Text("From " + type.toString() + " -",
                          style: typeStyle, textAlign: TextAlign.center),
                      Text(date, style: dateStyle, textAlign: TextAlign.center),
                    ],
                  ),
                  SizedBox(height: 11),
                  Row(
                    children: [
                      Text(location),
                      Text(difficulty.toString()),
                      Text(points.toString())
                    ],
                  )
                ],
              )
            ],
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
          ),
        ),
      ));
}
