import 'package:flutter/material.dart';
import 'package:game/preview/preview.dart';

class JourneyCell extends StatefulWidget {
  final int locationCount;
  final String journeyName;
  final String description;
  final int numberCompleted;
  final bool isCompleted;
  final String difficulty;
  final int points;
  final int challengePoints;

  const JourneyCell(
      this.journeyName,
      this.description,
      this.locationCount,
      this.numberCompleted,
      this.isCompleted,
      this.difficulty,
      this.points,
      this.challengePoints,
      {Key? key})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _JourneyCellState(
      journeyName,
      description,
      locationCount,
      numberCompleted,
      isCompleted,
      difficulty,
      points,
      challengePoints);
}

class _JourneyCellState extends State<JourneyCell> {
  final int locationCount;
  final String journeyName;
  final String description;
  final int numberCompleted;
  final bool isCompleted;
  final String difficulty;
  final int points;
  final int challengePoints;

  _JourneyCellState(
      this.journeyName,
      this.description,
      this.locationCount,
      this.numberCompleted,
      this.isCompleted,
      this.difficulty,
      this.points,
      this.challengePoints);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await showDialog(
            context: context,
            builder: (context) => Preview(
                  journeyName,
                  description,
                  difficulty,
                  points,
                  challengePoints,
                  previewType.journey,
                  locationCount: locationCount,
                  numberCompleted: numberCompleted,
                ));
      },
      child: Container(
        color: Color.fromARGB(51, 217, 217, 217),
        height: 180.0,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isCompleted)
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "COMPLETED",
                        style: TextStyle(
                          color: Color.fromARGB(255, 71, 71, 71),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Lato',
                        ),
                      ),
                    ],
                  ),
                ),
              Container(
                height: 18,
                child: Text(
                  locationCount == 1
                      ? '${locationCount} location'
                      : '${locationCount} locations',
                  style: TextStyle(
                    color: Color.fromARGB(153, 0, 0, 0),
                    fontSize: 12,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
              Container(
                height: 27,
                child: Text(
                  journeyName,
                  style: TextStyle(
                    color: Color.fromARGB(255, 0, 0, 0),
                    fontSize: 18,
                    fontFamily: 'Lato',
                  ),
                ),
              ),
              Container(
                height: 18,
                child: Text(
                  description,
                  style: TextStyle(
                    color: Color.fromARGB(179, 0, 0, 0),
                    fontSize: 12,
                    fontFamily: 'Lato',
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 18),
                child: Container(
                  height: 10.0,
                  width: double.infinity,
                  color: Color.fromARGB(255, 255, 255, 255),
                  child: FractionallySizedBox(
                    alignment: Alignment.topLeft,
                    widthFactor: (locationCount > 0
                        ? numberCompleted / locationCount
                        : 0),
                    child: Container(color: Color.fromARGB(255, 0, 0, 0)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
