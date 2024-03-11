import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

enum PreviewType { challenge, journey }

/** Returns a preview of a challenge given the challenge name, description, 
 * difficulty, points, and bonus points for challenge mode. Used for
 * both Challenges and Journeys. */
class Preview extends StatefulWidget {
  final String challengeName;
  final String description;
  final String difficulty;
  final int points;
  final PreviewType type;

  final int locationCount;
  final int numberCompleted;

// newly added parameters; need to implement higher up in hierarchy
  // final int
  //     totalDistance;
  // final String
  //     location;

  static Color backgroundColor = Color.fromARGB(255, 217, 214, 213);
  static Color purpleColor = Color.fromARGB(255, 131, 90, 124);
  static Color greyColor = Color.fromARGB(255, 110, 110, 110);

  //Temporary image for now. Will have to change later
  final String imgPath = "assets/images/38582.jpg";

  Preview(this.challengeName, this.description, this.difficulty, this.points,
      this.type,
      {this.locationCount = 1,
      this.numberCompleted = 0,
      // required this.totalDistance,
      // required this.location,
      Key? key})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _PreviewState(challengeName,
      description, difficulty, points, type, locationCount, numberCompleted
      // need to figure out newly added parameters; commented out for now
      // totalDistance,
      // location
      );
}

class MyFlutterApp {
  MyFlutterApp._();

  static const _kFontFam = 'MyFlutterApp';
  static const String? _kFontPkg = null;

  static const IconData pin_icon =
      IconData(0xe800, fontFamily: _kFontFam, fontPackage: _kFontPkg);
}

/**Builds a widget based on the current state which is needed for toggleable 
 * challenge_on button */
class _PreviewState extends State<Preview> {
  final String challengeName;
  final String description;
  final String difficulty;
  final int points;
  final PreviewType type;
  // newly added parameter; need to implement higher up in hierarchy
  // final int
  //     totalDistance;
  // final String
  //     location;
  bool _challenge_on = false;

  static Color backgroundRed = Color.fromARGB(255, 237, 86, 86);
  static Color backgroundRedMuted = Color.fromARGB(191, 237, 86, 86);

  //fields unique to journeys
  final int locationCount;
  final int numberCompleted;

  //Temporary image for now. Will have to change later
  final String imgPath = "assets/images/38582.jpg";

  _PreviewState(this.challengeName, this.description, this.difficulty,
      this.points, this.type, this.locationCount, this.numberCompleted);
  @override
  Widget build(BuildContext context) {
    //The dialog
    return Dialog(
      //Overall Container
      child: Container(
          height: (type == PreviewType.challenge) ? 420 : 500,
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
                            width: 48,
                            height: 4,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
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
                                  (points).toString() + " points",
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.black),
                                ),
                              ),
                            ),
                            decoration: new BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(20.0)),
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
                  Text("Beat the timer (+ " + points.toString() + " points)",
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
                                : backgroundRed,
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
              (type == PreviewType.journey)
                  ? Column(children: [
                      SizedBox(height: 20),
                      Padding(
                        padding:
                            const EdgeInsets.only(left: 25, right: 25, top: 15),
                        child: Row(children: [
                          Icon(Icons.tour,
                              size: 24, color: Preview.purpleColor),
                          Text(
                              "Location placeholder", // should call new parameter; replace later
                              style: TextStyle(
                                  fontSize: 20, color: Preview.purpleColor)),
                          SizedBox(width: 10),
                          Icon(Icons.directions_walk,
                              size: 24, color: Preview.greyColor),
                          Text(
                              "25" + // should call new parameter; replace later
                                  "mi",
                              style: TextStyle(
                                  fontSize: 20, color: Preview.greyColor))
                        ]),
                      )
                    ])
                  : Padding(
                      padding: const EdgeInsets.only(
                          left: 25.0, right: 25.0, bottom: 5),
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
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(description,
                      style: TextStyle(
                          // fontWeight: FontWeight.bold,
                          fontSize: 16,
                          fontFamily: 'Poppins',
                          color: Preview.greyColor)),
                ),
              ),
              (type == PreviewType.journey)
                  ? Column(children: [
                      SizedBox(height: 5),
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 25, right: 25, bottom: 15),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Expanded(
                                child: SizedBox(
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                            padding: const EdgeInsets.only(
                                                top: 10.0, right: 5),
                                            child: Container(
                                              height: 36,
                                              alignment: Alignment.centerLeft,
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: Color.fromARGB(
                                                      255, 249, 237, 218),
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                ),
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          left: 8, right: 8),
                                                  child: Align(
                                                    alignment: Alignment.center,
                                                    child: Text(
                                                      difficulty[0]
                                                              .toUpperCase() +
                                                          difficulty
                                                              .substring(1),
                                                      style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.black),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            )),
                                        Padding(
                                            padding: const EdgeInsets.only(
                                                left: 4, top: 10.0),
                                            child: Container(
                                              height: 36,
                                              alignment: Alignment.centerLeft,
                                              child: Container(
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          left: 8, right: 8),
                                                  child: Align(
                                                    alignment: Alignment.center,
                                                    child: Text(
                                                      (points).toString() +
                                                          "PTS",
                                                      style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.white),
                                                    ),
                                                  ),
                                                ),
                                                decoration: new BoxDecoration(
                                                  border: Border.all(
                                                    color: Color.fromARGB(
                                                        255, 255, 199, 55),
                                                  ),
                                                  color: Color.fromARGB(
                                                      255, 189, 135, 31),
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  shape: BoxShape.rectangle,
                                                ),
                                              ),
                                            )),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            ]),
                      ),
                      Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 25),
                          child: Stack(children: [
                            Container(
                              width: 345,
                              height: 24,
                              alignment: Alignment.centerLeft,
                              child: Container(
                                decoration: new BoxDecoration(
                                  color: Color.fromARGB(255, 241, 241, 241),
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
                                  345,
                              height: 24,
                              alignment: Alignment.centerLeft,
                              child: Container(
                                decoration: new BoxDecoration(
                                  color: backgroundRedMuted,
                                  shape: BoxShape.rectangle,
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(16.0)),
                                ),
                              ),
                            ),
                          ])),
                      // SizedBox(height: 30),
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 25, right: 25, bottom: 15, top: 3),
                        child: Row(children: [
                          Expanded(
                            child: SizedBox(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Spacer(),
                                      Icon(Icons.location_on,
                                          size: 15, color: Preview.purpleColor),
                                      Text(
                                          numberCompleted.toString() +
                                              "/" +
                                              locationCount.toString(),
                                          style: TextStyle(
                                              fontSize: 15,
                                              color: Colors.black))
                                    ]),
                              ),
                            ),
                          )
                        ]),
                      ),
                    ])
                  : SizedBox(height: 30),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 25),
                child: SizedBox(
                    height: 50,
                    width: 345,
                    child: TextButton(
                      style: ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.all(backgroundRed),
                          shape:
                              MaterialStateProperty.all<RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                      side: BorderSide(color: backgroundRed)))),
                      onPressed: () {
                        print("Unimplemented. Starting Challenge!");
                      },
                      child: Text(
                        "Continue exploring",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            fontFamily: "Poppins",
                            color: Colors.white),
                      ),
                    )),
              )
            ],
          )),
    );
  }
}
