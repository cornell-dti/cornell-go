import 'package:flutter/material.dart';
import 'package:game/preview/preview.dart';

class ChallengeCell extends StatefulWidget {
  final String location;
  final String challengeName;
  final Image thumbnail;
  final bool isCompleted;
  final String description;
  final String difficulty;
  final int points;
  final int challenge_points;

  const ChallengeCell(
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

class _ChallengeCellState extends State<ChallengeCell> {
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
                  difficulty, points, PreviewType.CHALLENGE, "MY LOCATION"));
        },
        child: Container(
          color: Color.fromARGB(51, 217, 217, 217),
          height: 85.0,
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
                      Flexible(
                        child: Row(
                          children: [
                            Container(
                              color: Color.fromARGB(204, 0, 0, 0),
                              child: Text(
                                location,
                                style: TextStyle(
                                  color: Color.fromARGB(230, 255, 255, 255),
                                  fontSize: 8,
                                  fontFamily: 'Lato',
                                ),
                              ),
                            ),
                            if (isCompleted) ...[
                              Expanded(
                                child: Row(
                                  children: [
                                    Spacer(),
                                    Text(
                                      "COMPLETED",
                                      style: TextStyle(
                                        color: Color.fromARGB(255, 71, 71, 71),
                                        fontSize: 10,
                                        fontFamily: 'Lato',
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
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
                    ],
                  ),
                )
              ],
            ),
          ),
        ));
  }
}
