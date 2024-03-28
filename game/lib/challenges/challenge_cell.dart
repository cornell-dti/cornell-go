import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:game/preview/preview.dart';

class ChallengeCell extends StatefulWidget {
  final String location;
  final String challengeName;
  final Image thumbnail;
  final bool isCompleted;
  final String description;
  final String difficulty;
  final int points;

  const ChallengeCell(this.location, this.challengeName, this.thumbnail,
      this.isCompleted, this.description, this.difficulty, this.points,
      {Key? key})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _ChallengeCellState(location,
      challengeName, thumbnail, isCompleted, description, difficulty, points);
}

class _ChallengeCellState extends State<ChallengeCell> {
  final String location;
  final String challengeName;
  final Image thumbnail;
  final bool isCompleted;
  final String description;
  final String difficulty;
  final int points;
  // newly added field
  // final int totalDistance;

  _ChallengeCellState(
    this.location,
    this.challengeName,
    this.thumbnail,
    this.isCompleted,
    this.description,
    this.difficulty,
    this.points,
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
            builder: (context) => Preview(challengeName, description,
                difficulty, points, previewType.challenge, location));
      },
      child: Container(
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
        height: 135.0,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 14),
                child: ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(4.6)),
                  child: thumbnail,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Icon(Icons.location_on,
                            size: 20, color: Color.fromARGB(255, 131, 90, 124)),
                        Text(
                          location,
                          style: TextStyle(
                            color: Color.fromARGB(255, 131, 90, 124),
                            fontSize: 14,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 4,
                    ),
                    Text(
                      challengeName,
                      style: TextStyle(
                        color: Color.fromARGB(204, 0, 0, 0),
                        fontSize: 16.5,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(
                      height: 4,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                          decoration: BoxDecoration(
                            color: Color.fromARGB(255, 249, 237, 218),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            difficulty,
                            style: TextStyle(
                              color: Color.fromARGB(204, 0, 0, 0),
                              fontSize: 14,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Color.fromARGB(255, 255, 199, 55),
                            ),
                            color: Color.fromARGB(255, 189, 135, 31),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            points.toString() + "PTS",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
