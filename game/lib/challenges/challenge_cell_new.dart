import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';

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
              builder: (context) => ChallengePreview(challengeName, description,
                  difficulty, points, challenge_points));
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

class ChallengePreview extends StatefulWidget {
  final String challengeName;
  final String description;
  final String difficulty;
  final int points;
  final int challenge_points;

  static Color backgroundColor = Color.fromARGB(255, 217, 214, 213);

  //Temporary image for now. Will have to change later
  final String imgPath = "assets/images/38582.jpg";

  ChallengePreview(this.challengeName, this.description, this.difficulty,
      this.points, this.challenge_points,
      {Key? key})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _ChallengePreviewState(
      challengeName, description, difficulty, points, challenge_points);
}

class _ChallengePreviewState extends State<ChallengePreview> {
  final String challengeName;
  final String description;
  final String difficulty;
  final int points;
  final int challenge_points;
  bool _challenge_on = false;

  static Color backgroundColor = Color.fromARGB(255, 217, 214, 213);

  //Temporary image for now. Will have to change later
  final String imgPath = "assets/images/38582.jpg";

  _ChallengePreviewState(this.challengeName, this.description, this.difficulty,
      this.points, this.challenge_points);
  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
          height: 420,
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                    image: DecorationImage(
                        image: AssetImage(imgPath), fit: BoxFit.cover)),
                height: 150,
                alignment: Alignment.topLeft,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                        padding: const EdgeInsets.only(
                            left: 10, top: 10.0, right: 5),
                        child: Container(
                          height: 25,
                          alignment: Alignment.centerLeft,
                          child: Container(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8, right: 8),
                              child: Align(
                                alignment: Alignment.center,
                                child: Text(
                                  difficulty[0].toUpperCase() +
                                      difficulty.substring(1),
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.black),
                                ),
                              ),
                            ),
                            decoration: new BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.rectangle,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(16.0)),
                              boxShadow: [
                                BoxShadow(
                                  color: Color.fromARGB(255, 198, 198, 198),
                                  blurRadius: 2,
                                  offset: Offset(0, 4), // Shadow position
                                ),
                              ],
                            ),
                          ),
                        )),
                    Padding(
                        padding: const EdgeInsets.only(left: 4, top: 10.0),
                        child: Container(
                          height: 25,
                          alignment: Alignment.centerLeft,
                          child: Container(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8, right: 8),
                              child: Align(
                                alignment: Alignment.center,
                                child: Text(
                                  (points +
                                              (_challenge_on
                                                  ? challenge_points
                                                  : 0))
                                          .toString() +
                                      " points",
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.black),
                                ),
                              ),
                            ),
                            decoration: new BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.rectangle,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(16.0)),
                              boxShadow: [
                                BoxShadow(
                                  color: Color.fromARGB(255, 198, 198, 198),
                                  blurRadius: 2,
                                  offset: Offset(0, 4), // Shadow position
                                ),
                              ],
                            ),
                          ),
                        )),
                    Expanded(
                        child: SizedBox(
                            child: Align(
                      alignment: Alignment(1.1, -1.1),
                      child: CloseButton(),
                    )))
                  ],
                ),
              ),
              SizedBox(height: 20),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 25.0, vertical: 5),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(challengeName,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 25,
                          color: Colors.black)),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 25.0, vertical: 5),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(description,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.black)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 25.0, right: 25, top: 15),
                child: Row(children: [
                  Text(
                      "Beat the timer (+ " +
                          challenge_points.toString() +
                          " points)",
                      style: TextStyle(fontSize: 16, color: Colors.black)),
                  Expanded(
                      child: SizedBox(
                          child: Align(
                    alignment: Alignment.centerRight,
                    child: Stack(children: [
                      Container(
                        width: 40.0,
                        height: 20.0,
                        child: Container(
                          decoration: new BoxDecoration(
                            color: _challenge_on
                                ? Colors.lightBlue
                                : backgroundColor,
                            shape: BoxShape.rectangle,
                            borderRadius:
                                BorderRadius.all(Radius.circular(16.0)),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(
                            left: _challenge_on ? 20.0 : 4.0, top: 2),
                        child: new Container(
                          width: 16,
                          height: 16,
                          decoration: new BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Container(
                        width: 40,
                        height: 20,
                        child: TextButton(
                            onPressed: () {
                              setState(
                                () {
                                  _challenge_on = !_challenge_on;
                                },
                              );
                            },
                            child: Text("")),
                      ),
                    ]),
                  )))
                ]),
              ),
              SizedBox(height: 30),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 25),
                child: Row(children: [
                  SizedBox(width: 60),
                  Container(
                      height: 50,
                      width: 200,
                      child: TextButton(
                        style: ButtonStyle(
                            backgroundColor:
                                MaterialStateProperty.all(backgroundColor),
                            shape: MaterialStateProperty.all<
                                    RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                    side: BorderSide(color: backgroundColor)))),
                        onPressed: () {
                          print("Unimplemented. Starting Challenge!");
                        },
                        child: Text(
                          "START EXPLORING →",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                              color: Colors.black),
                        ),
                      )),
                ]),
              )
            ],
          )),
    );
  }
}
