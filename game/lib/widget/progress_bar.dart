import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LoadingBar extends StatelessWidget {
  final int totalTasks;
  final int tasksFinished;

  const LoadingBar(
    this.tasksFinished,
    this.totalTasks,
  );

  String formatNumber(int number) {
    if (number < 1000) {
      return number.toString();
    } else {
      return (number / 1000).toStringAsFixed(1) + 'K';
    }
  }

  double calculateWidthMultiplier(int number) {
    int length = number.toString().length;
    if (length == 1) {
      return 0.5;
    } else if (length == 2) {
      return 0.47;
    } else {
      return 0.43;
    }
  }

  @override
  Widget build(BuildContext context) {
    double widthMultiplier = calculateWidthMultiplier(totalTasks);

    return Row(
      children: [
        Container(
            width: MediaQuery.sizeOf(context).width * widthMultiplier,
            child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
              return Stack(children: [
                Container(
                  width: constraints.maxWidth,
                  height: 13,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    decoration: new BoxDecoration(
                      color: Color.fromARGB(255, 241, 241, 241),
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.all(Radius.circular(16.0)),
                    ),
                  ),
                ),
                Container(
                  width: (totalTasks > 0 ? tasksFinished / totalTasks : 0) *
                      constraints.maxWidth,
                  height: 13,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    decoration: new BoxDecoration(
                      color: Color.fromARGB(197, 237, 86, 86),
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.all(Radius.circular(16.0)),
                    ),
                  ),
                ),
                Container(
                  height: 3,
                  width: max(
                      (totalTasks > 0 ? tasksFinished / totalTasks : 0) *
                              constraints.maxWidth -
                          16,
                      0),
                  margin: EdgeInsets.only(left: 8, top: 3),
                  alignment: Alignment.centerLeft,
                  decoration: new BoxDecoration(
                    color: Color(0x99F3C6C6),
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.all(Radius.circular(5.0)),
                  ),
                ),
              ]);
            })),
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Text(
            "${formatNumber(tasksFinished)}/${formatNumber(totalTasks)}",
          ),
        ),
      ],
    );
  }
}
