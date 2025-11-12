import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:game/utils/utility_functions.dart';
import 'package:velocity_x/velocity_x.dart';

/**
 * Widget that represents each individual completed journey or challenge
 * @param name: Name of the challenge or journey completed
 * @param type: an enum of type CompeltedType either a journey or challenge
 * @param date: Date that the journey / challenge was completed
 * @param difficulty: level of the task, either easy, medium, or hard
 * @param points: Points that the completed journey / challenge had

 */
Widget completedCell(
    BuildContext context,
    String name,
    String picture,
    String type,
    String date,
    String difficulty,
    int totalHintsUsed,
    int points) {
  return Container(
      width: MediaQuery.sizeOf(context).width * 0.85,
      height: MediaQuery.sizeOf(context).height * 0.11,
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
                  width: 64,
                  height: 64,
                  image: NetworkImage(picture),
                  fit: BoxFit.cover,
                )),
          ),
          Expanded(
            // this prevents overflow issues
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text.rich(
                    // for multiple fonts usage
                    TextSpan(
                      children: [
                        TextSpan(
                          text: "From " + type + " - ",
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        TextSpan(
                          text: date,
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 5.0),
                    child: Container(
                      width: 200,
                      child: Row(children: [
                        SvgPicture.asset(
                          "assets/icons/bearcoins.svg",
                          width: 20,
                        ),
                        Text(
                            ' ' +
                                calculateHintAdjustedPoints(
                                        points, totalHintsUsed)
                                    .toString() +
                                "/" +
                                points.toString() +
                                " PTS",
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFFC17E19)))
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ));
}
