import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LoadingBar extends StatelessWidget {
  final int totalTasks;
  final int tasksFinished;

  const LoadingBar(
    this.tasksFinished,
    this.totalTasks,
  );

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 200,
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
                  width: (totalTasks > 0 ? tasksFinished / totalTasks : 0) *
                          constraints.maxWidth -
                      16,
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
            tasksFinished.toString() + "/" + totalTasks.toString(),
          ),
        ),
      ],
    );
  }
}

class AchievementCell extends StatefulWidget {
  final SvgPicture thumbnail;
  final String description;
  final int tasksFinished;
  final int totalTasks;

  const AchievementCell(
      this.description, this.thumbnail, this.tasksFinished, this.totalTasks,
      {Key? key})
      : super(key: key);

  @override
  State<StatefulWidget> createState() =>
      _AchievementCellState(description, thumbnail, tasksFinished, totalTasks);
}

class _AchievementCellState extends State<AchievementCell> {
  final String description;
  final SvgPicture thumbnail;
  final int tasksFinished;
  final int totalTasks;
  // newly added field
  // final int totalDistance;

  _AchievementCellState(
      this.description, this.thumbnail, this.tasksFinished, this.totalTasks
      // newly added field
      // this.totalDistance
      );

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {},
      child: Container(
        padding: EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Color.fromARGB(255, 198, 198, 198),
              blurRadius: 2,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Container(
          margin: EdgeInsets.all(10),
          height: 64,
          child: Row(
            children: [
              Container(margin: EdgeInsets.only(right: 12), child: thumbnail),
              Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      description,
                      style: TextStyle(
                        color: Color.fromARGB(204, 0, 0, 0),
                        fontSize: 14,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Spacer(),
                  Align(
                      alignment: Alignment.bottomCenter,
                      child: LoadingBar(3, 4)),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
