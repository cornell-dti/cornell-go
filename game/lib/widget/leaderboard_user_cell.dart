import 'package:flutter/material.dart';
import 'package:align_positioned/align_positioned.dart';
import 'package:game/utils/utility_functions.dart';

Widget leaderBoardUserCell(
    context, String name, int position, int total_positions, int points) {
  Color Carnelian = Color(0xFFB31B1B);
  var posStyle =
      TextStyle(fontWeight: FontWeight.bold, fontSize: 40, color: Colors.white);
  var totalPosStyle =
      TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white);
  var nameStyle =
      TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: Colors.white);
  var pointStyle = TextStyle(
      fontWeight: FontWeight.normal,
      fontSize: 18,
      color: Colors.white,
      fontStyle: FontStyle.italic);
  return Padding(
    padding: const EdgeInsets.only(top: 30.0),
    child: Container(
      height: 80,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              clipBehavior: Clip.none,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Carnelian,
                  border: Border.all(color: Colors.grey)),
              width: MediaQuery.of(context).size.width,
              child: Padding(
                padding: const EdgeInsets.all(6.0),
                child: Row(
                  children: [
                    Row(
                      children: [
                        Container(
                          child: Row(
                            children: [
                              Text(position.toString(), style: posStyle),
                              Text(
                                "/" + total_positions.toString(),
                                style: totalPosStyle,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: Text(
                        name,
                        style: nameStyle,
                      ),
                    ),
                    Text(
                      points.toString(),
                      style: pointStyle,
                    ),
                  ],
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                ),
              ),
            ),
          ),
          AlignPositioned(
              alignment: Alignment.topLeft,
              moveByChildHeight: -0.35,
              child: Container(
                alignment: Alignment.topCenter,
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 22.5,
                  child: CircleAvatar(
                      child: ClipOval(
                    child: Container(
                      decoration: BoxDecoration(
                          color: constructColorFromUserName(name)),
                      width: 100,
                      height: 100,
                    ),
                  )),
                ),
              ))
        ],
      ),
    ),
  );
}
