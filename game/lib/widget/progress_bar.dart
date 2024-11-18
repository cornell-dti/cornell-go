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

/**
 * Formats a number into a readable string with a "K" suffix for thousands.
 * 
 * Converts numbers to a string format using different precision based on their size to ensure readability in UI displays.
 * For numbers between 1,000 and 9,999, one decimal is shown; numbers exactly at 1,000 or 10,000 are shown without decimals.
 * Numbers above 10,000 and up to 99,999 are rounded to the nearest thousand. The function throws an exception for numbers exceeding 100,000.
 *
 * @param number - The number to format.
 * @returns A string representing the formatted number or throws a FormatException for numbers above 100,000.
 * 
 */
  String formatNumber(int number) {
    if (number < 1000) {
      return number.toString();
    } else {
      if (number == 1000) {
        return "1K";
      } else if (number > 1000 && number < 10000) {
        return (number / 1000).toStringAsFixed(1) + 'K';
      } else if (number == 10000) {
        return "10K";
      } else if (number > 10000 && number < 100000) {
        return (number / 1000).toStringAsFixed(0) + 'K';
      } else {
        // Throw an exception for numbers greater than 100,000
        throw FormatException('Number too large to format');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: MediaQuery.sizeOf(context).width * 0.415,
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
            padding: EdgeInsets.only(left: 2.0),
            child: Container(
                // Explicit container for the text
                // color: Colors.cyan,
                width: MediaQuery.sizeOf(context).width * 0.16,
                alignment: Alignment.center, // Center text within the container
                child: Text(
                  "${formatNumber(tasksFinished)}/${formatNumber(totalTasks)}",
                )))
      ],
    );
  }
}
