import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:game/preview/preview.dart';

class ChallengeCellNew extends StatefulWidget {
  final String location;
  final String challengeName;
  final Image thumbnail;
  final bool isCompleted;
  final String description;
  final String difficulty;
  final int points;
  final int challenge_points;

  const ChallengeCellNew(
      this.location,
      this.challengeName,
      this.thumbnail,
      this.isCompleted,
      this.description,
      this.difficulty,
      this.points,
      this.challenge_points,
      {Key? key})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _ChallengeCellState(
        location,
        challengeName,
        thumbnail,
        isCompleted,
        description,
        difficulty,
        points,
        challenge_points,
      );
}

class _ChallengeCellState extends State<ChallengeCellNew> {
  final String location;
  final String challengeName;
  final Image thumbnail;
  final bool isCompleted;
  final String description;
  final String difficulty;
  final int points;
  final int challenge_points;

  _ChallengeCellState(
      this.location,
      this.challengeName,
      this.thumbnail,
      this.isCompleted,
      this.description,
      this.difficulty,
      this.points,
      this.challenge_points);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await showDialog(
            context: context,
            builder: (context) => Preview(challengeName, description,
                difficulty, points, challenge_points, previewType.challenge));
      },
      child: Container(
        color: Color.fromARGB(51, 217, 217, 217),
        height: 135.0,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 14),
                child: ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(4.6)),
                  child: thumbnail,
                ),
              ),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Icon(Icons.location_on, size: 20, color: Colors.purple),
                        // SizedBox(width: 50),
                        Text(
                          location,
                          style: TextStyle(
                            color: Colors.purple,
                            fontSize: 10,
                            fontFamily: 'Lato',
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
                        fontFamily: 'Lato',
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
                          padding: EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Color.fromARGB(76, 217, 217, 217),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            difficulty,
                            style: TextStyle(
                              color: Color.fromARGB(204, 0, 0, 0),
                              fontSize: 12,
                              fontFamily: 'Lato',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(width: 10), // Add spacing between buttons
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.purple,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            challenge_points.toString() + "PTS",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontFamily: 'Lato',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 4,
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
