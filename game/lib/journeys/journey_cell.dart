import 'package:flutter/material.dart';

class JourneyCell extends StatelessWidget {
  final int locationCount;
  final String journeyName;
  final String description;
  final int numberCompleted;
  const JourneyCell(this.journeyName, this.description, this.locationCount,
      this.numberCompleted,
      {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color.fromARGB(51, 217, 217, 217),
      height: 300,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(locationCount == 1
                ? '${locationCount} location'
                : '${locationCount} locations'),
            Text(journeyName),
            Text(description),
            Container(
              height: 10.0,
              width: double.infinity,
              color: Color.fromARGB(255, 255, 255, 255),
              child: FractionallySizedBox(
                alignment: Alignment.topLeft,
                widthFactor:
                    (locationCount > 0 ? numberCompleted / locationCount : 0),
                child: Container(color: Color.fromARGB(255, 0, 0, 0)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
