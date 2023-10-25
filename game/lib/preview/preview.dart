import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

enum previewType { challenge, journey }

/** Returns a preview of a challenge given the challenge name, description, difficulty, points, and bonus points for challenge mode */
class Preview extends StatefulWidget {
  final String challengeName;
  final String description;
  final String difficulty;
  final int points;
  final int challenge_points;
  final previewType type;

  final int locationCount;
  final int numberCompleted;

  static Color backgroundColor = Color.fromARGB(255, 217, 214, 213);

  //Temporary image for now. Will have to change later
  final String imgPath = "assets/images/38582.jpg";

  Preview(this.challengeName, this.description, this.difficulty, this.points,
      this.challenge_points, this.type,
      {this.locationCount = 1, this.numberCompleted = 0, Key? key})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _PreviewState(
      challengeName,
      description,
      difficulty,
      points,
      challenge_points,
      type,
      locationCount,
      numberCompleted);
}

/**Builds a widget based on the current state which is needed for toggleable challenge_on button */
class _PreviewState extends State<Preview> {
  final String challengeName;
  final String description;
  final String difficulty;
  final int points;
  final int challenge_points;
  final previewType type;
  bool _challenge_on = false;

  //fields unique to journeys
  final int locationCount;
  final int numberCompleted;

  static Color backgroundColor = Color.fromARGB(255, 217, 214, 213);

  //Temporary image for now. Will have to change later
  final String imgPath = "assets/images/38582.jpg";

  _PreviewState(
      this.challengeName,
      this.description,
      this.difficulty,
      this.points,
      this.challenge_points,
      this.type,
      this.locationCount,
      this.numberCompleted);
  @override
  Widget build(BuildContext context) {
    //The dialog
    return Dialog(
      //Overall Container
      child: Container(
          height: (type == previewType.challenge) ? 420 : 500,
          child: Column(
            children: [
              //Image and labels (difficulty and points)
              Container(
                decoration: BoxDecoration(
                    image: DecorationImage(
                        image: AssetImage(imgPath), fit: BoxFit.cover)),
                height: 150,
                alignment: Alignment.topLeft,
                //labels
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
              (type == previewType.journey)
                  ? Column(children: [
                      SizedBox(height: 20),
                      Padding(
                        padding:
                            const EdgeInsets.only(left: 25, right: 25, top: 15),
                        child: Row(children: [
                          Text("Completed",
                              style:
                                  TextStyle(fontSize: 17, color: Colors.black)),
                          Expanded(
                            child: SizedBox(
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                    numberCompleted.toString() +
                                        "/" +
                                        locationCount.toString(),
                                    style: TextStyle(
                                        fontSize: 15, color: Colors.black)),
                              ),
                            ),
                          )
                        ]),
                      ),
                      Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 25, vertical: 5),
                          child: Stack(children: [
                            Container(
                              width: 270,
                              height: 20,
                              alignment: Alignment.centerLeft,
                              child: Container(
                                decoration: new BoxDecoration(
                                  color: backgroundColor,
                                  shape: BoxShape.rectangle,
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(16.0)),
                                ),
                              ),
                            ),
                            Container(
                              width: (locationCount > 0
                                      ? numberCompleted / locationCount
                                      : 0) *
                                  270,
                              height: 20,
                              alignment: Alignment.centerLeft,
                              child: Container(
                                decoration: new BoxDecoration(
                                  color: Color.fromARGB(197, 35, 35, 35),
                                  shape: BoxShape.rectangle,
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(16.0)),
                                ),
                              ),
                            ),
                          ])),
                      SizedBox(height: 30)
                    ])
                  : SizedBox(height: 30),
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
