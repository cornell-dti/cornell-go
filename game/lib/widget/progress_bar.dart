import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LoadingBar extends StatelessWidget {
  final int totalTasks;
  final int tasksFinished;

  const LoadingBar(this.tasksFinished, this.totalTasks);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return Stack(
                children: [
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
                      0,
                    ),
                    margin: EdgeInsets.only(left: 8, top: 3),
                    alignment: Alignment.centerLeft,
                    decoration: new BoxDecoration(
                      color: Color(0x99F3C6C6),
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.all(Radius.circular(5.0)),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        SizedBox(width: 8),
        Text(tasksFinished.toString() + "/" + totalTasks.toString()),
      ],
    );
  }
}
