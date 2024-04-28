import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

@Deprecated('achievements/achievement_cell.dart')
/**
 * Widget that represents each individual achievement
 * @param name: Name of the achievement
 * @param tasksFinished: Number of currently completed tasks towards the achievement
 * @param totalTasks: Total number of tasks needed to gain achievement
 * @param picture: picture that is associated with the achievement
 */
Widget achievementCell(
    String name, int tasksFinished, int totalTasks, String picture) {
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Container(
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Container(
                        width: 215,
                        child: Text(
                          name,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Stack(children: [
                      Container(
                        width: 170,
                        height: 13,
                        alignment: Alignment.centerLeft,
                        child: Container(
                          decoration: new BoxDecoration(
                            color: Color.fromARGB(255, 241, 241, 241),
                            shape: BoxShape.rectangle,
                            borderRadius:
                                BorderRadius.all(Radius.circular(16.0)),
                          ),
                        ),
                      ),
                      Container(
                        width:
                            (totalTasks > 0 ? tasksFinished / totalTasks : 0) *
                                170,
                        height: 13,
                        alignment: Alignment.centerLeft,
                        child: Container(
                          decoration: new BoxDecoration(
                            color: Color.fromARGB(197, 237, 86, 86),
                            shape: BoxShape.rectangle,
                            borderRadius:
                                BorderRadius.all(Radius.circular(16.0)),
                          ),
                        ),
                      ),
                    ]),
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text(
                        tasksFinished.toString() + "/" + totalTasks.toString(),
                      ),
                    ),
                  ],
                ),
              ],
            )
          ],
        )),
  );
}
