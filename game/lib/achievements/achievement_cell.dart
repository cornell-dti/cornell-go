import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:game/widget/progress_bar.dart';

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
        width: MediaQuery.sizeOf(context).width * 0.85,

        //padding: EdgeInsets.all(5),
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
          padding: EdgeInsets.all(10),
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
                    child: Container(
                      width: MediaQuery.sizeOf(context).width * 0.45,
                      child: Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.clip,
                        style: TextStyle(
                          color: Color.fromARGB(204, 0, 0, 0),
                          fontSize: 14,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  Align(
                      alignment: Alignment.bottomCenter,
                      child: LoadingBar(this.tasksFinished, this.totalTasks)),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
