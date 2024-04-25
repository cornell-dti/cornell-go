import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:game/preview/preview.dart';
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
    return Container(
      width: (totalTasks > 0 ? tasksFinished / totalTasks : 0) * 170,
      height: 13,
      alignment: Alignment.centerLeft,
      child: Container(
        decoration: new BoxDecoration(
          color: Color.fromARGB(197, 237, 86, 86),
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.all(Radius.circular(16.0)),
        ),
      ),
    );
  }
}

class AchievementCell extends StatefulWidget {
  final String location;
  final String challengeName;
  final double? challengeLat;
  final double? challengeLong;
  final SvgPicture thumbnail;
  final bool isCompleted;
  final String description;
  final String difficulty;
  final int points;
  final String eventId;

  const AchievementCell(
      this.location,
      this.challengeName,
      this.challengeLat,
      this.challengeLong,
      this.thumbnail,
      this.isCompleted,
      this.description,
      this.difficulty,
      this.points,
      this.eventId,
      {Key? key})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _AchievementCellState(
      location,
      challengeName,
      challengeLat,
      challengeLong,
      thumbnail,
      isCompleted,
      description,
      difficulty,
      points,
      eventId);
}

class _AchievementCellState extends State<AchievementCell> {
  final String location;
  final String challengeName;
  final double? challengeLat;
  final double? challengeLong;
  final SvgPicture thumbnail;
  final bool isCompleted;
  final String description;
  final String difficulty;
  final int points;
  final String eventId;
  // newly added field
  // final int totalDistance;

  _AchievementCellState(
      this.location,
      this.challengeName,
      this.challengeLat,
      this.challengeLong,
      this.thumbnail,
      this.isCompleted,
      this.description,
      this.difficulty,
      this.points,
      this.eventId
      // newly added field
      // this.totalDistance
      );

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await showModalBottomSheet(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(10.0)),
            ),
            context: context,
            isScrollControlled: true,
            builder: (context) => Preview(
                challengeName,
                challengeLat,
                challengeLong,
                description,
                difficulty,
                points,
                PreviewType.CHALLENGE,
                location,
                eventId));
      },
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(margin: EdgeInsets.only(right: 12), child: thumbnail),
              Expanded(
                  child: Stack(children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      challengeName,
                      style: TextStyle(
                        color: Color.fromARGB(204, 0, 0, 0),
                        fontSize: 16.5,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                        padding: EdgeInsets.only(bottom: 10.0),
                        child: LoadingBar(3, 4)))
              ]))
            ],
          ),
        ),
      ),
    );
  }
}
