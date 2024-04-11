import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:game/utils/utility_functions.dart';

/**
 * Widget that represents each individual completed journey or challenge
 * @param name: Name of the challenge or journey completed
 * @param type: an enum of type CompeltedType either a journey or challenge
 * @param date: Date that the journey / challenge was completed
 * @param difficulty: level of the task, either easy, medium, or hard
 * @param points: Points that the completed journey / challenge had

 */
Widget completedCell(String name, String picture, String type, String date,
    String difficulty, int points) {
  return Container(
      width: 345,
      height: 88,
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.0),
          boxShadow: [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.25),
              offset: Offset(0, 4),
              blurRadius: 4,
            ),
          ]),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image(
                  width: 80,
                  height: 80,
                  image: AssetImage(picture),
                  fit: BoxFit.cover,
                )),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    name,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Text(
                      "From " + type + " - ",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    Text(date)
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Container(
                    width: 200,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 80,
                          height: 25,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.purple, // Set the outline color
                              width: 2.0, // Set the outline width
                            ),
                            borderRadius: BorderRadius.circular(
                                15.0), // Set border radius
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SvgPicture.asset(
                                'assets/icons/flag.svg',
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 50,
                          height: 25,
                          decoration: BoxDecoration(
                            color: Color.fromRGBO(249, 236, 217, 1),
                            borderRadius: BorderRadius.circular(
                                20.0), // Set border radius
                          ),
                          child: Center(
                            child: Text(
                              difficulty,
                              style: TextStyle(
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: 50,
                          height: 25,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Color.fromRGBO(
                                  189, 135, 31, 1), // Set the outline color
                              width: 1.38, // Set the outline width
                            ),
                            color: Color.fromRGBO(255, 199, 55, 1),
                            borderRadius: BorderRadius.circular(
                                15.0), // Set border radius
                          ),
                          child: Center(
                            child: Text(
                              points.toString() + " PTS",
                              style: TextStyle(
                                fontSize: 10,
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ));
}
