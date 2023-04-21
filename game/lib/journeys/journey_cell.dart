import 'package:flutter/material.dart';

class JourneyCell extends StatefulWidget {
  final int locationCount;
  final String journeyName;
  final String description;
  final int numberCompleted;
  final bool isCompleted;
  final String difficulty;
  final int points;
  final int challenge_points;

  const JourneyCell(
      this.journeyName,
      this.description,
      this.locationCount,
      this.numberCompleted,
      this.isCompleted,
      this.difficulty,
      this.points,
      this.challenge_points,
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
      challenge_points);
}

class _JourneyCellState extends State<JourneyCell> {
  final int locationCount;
  final String journeyName;
  final String description;
  final int numberCompleted;
  final bool isCompleted;
  final String difficulty;
  final int points;
  final int challenge_points;

  _JourneyCellState(
      this.journeyName,
      this.description,
      this.locationCount,
      this.numberCompleted,
      this.isCompleted,
      this.difficulty,
      this.points,
      this.challenge_points);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await showDialog(
            context: context,
            builder: (context) => JourneyPreview(
                journeyName,
                description,
                locationCount,
                numberCompleted,
                isCompleted,
                difficulty,
                points,
                challenge_points));
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

class JourneyPreview extends StatefulWidget {
  final int locationCount;
  final String journeyName;
  final String description;
  final int numberCompleted;
  final bool isCompleted;
  final String difficulty;
  final int points;
  final int challenge_points;

  static Color backgroundColor = Color.fromARGB(255, 217, 214, 213);

  //Temporary image for now. Will have to change later
  final String imgPath = "assets/images/38582.jpg";

  JourneyPreview(
      this.journeyName,
      this.description,
      this.locationCount,
      this.numberCompleted,
      this.isCompleted,
      this.difficulty,
      this.points,
      this.challenge_points,
      {Key? key})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _JourneyPreviewState(
      journeyName,
      description,
      locationCount,
      numberCompleted,
      isCompleted,
      difficulty,
      points,
      challenge_points);
}

class _JourneyPreviewState extends State<JourneyPreview> {
  final int locationCount;
  final String journeyName;
  final String description;
  final int numberCompleted;
  final bool isCompleted;
  final String difficulty;
  final int points;
  final int challenge_points;
  bool _challenge_on = false;

  static Color backgroundColor = Color.fromARGB(255, 217, 214, 213);

  //Temporary image for now. Will have to change later
  final String imgPath = "assets/images/38582.jpg";

  _JourneyPreviewState(
      this.journeyName,
      this.description,
      this.locationCount,
      this.numberCompleted,
      this.isCompleted,
      this.difficulty,
      this.points,
      this.challenge_points);
  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
          height: 500,
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
                      padding:
                          const EdgeInsets.only(left: 5, top: 10.0, right: 5),
                      child: Stack(children: [
                        Container(
                          width: 80,
                          height: 25,
                          alignment: Alignment.centerLeft,
                          child: Container(
                            decoration: new BoxDecoration(
                              color: Color.fromARGB(255, 231, 231, 231),
                              shape: BoxShape.rectangle,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(16.0)),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 25,
                          width: 80,
                          child: Align(
                            alignment: Alignment.center,
                            child: Text(
                              difficulty[0].toUpperCase() +
                                  difficulty.substring(1),
                              style:
                                  TextStyle(fontSize: 12, color: Colors.black),
                            ),
                          ),
                        ),
                      ]),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: Stack(children: [
                        Container(
                          width: 80,
                          height: 25,
                          alignment: Alignment.centerLeft,
                          child: Container(
                            decoration: new BoxDecoration(
                              color: Color.fromARGB(255, 231, 231, 231),
                              shape: BoxShape.rectangle,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(16.0)),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 25,
                          width: 80,
                          child: Align(
                            alignment: Alignment.center,
                            child: Text(
                              points.toString() + " points",
                              style:
                                  TextStyle(fontSize: 12, color: Colors.black),
                            ),
                          ),
                        ),
                      ]),
                    ),
                    Expanded(
                        child: SizedBox(
                            child: Align(
                      alignment: Alignment.topRight,
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
                  child: Text(journeyName,
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
              SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.only(left: 25, right: 25, top: 15),
                child: Row(children: [
                  Text("Completed",
                      style: TextStyle(fontSize: 17, color: Colors.black)),
                  Expanded(
                    child: SizedBox(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                            numberCompleted.toString() +
                                "/" +
                                locationCount.toString(),
                            style:
                                TextStyle(fontSize: 15, color: Colors.black)),
                      ),
                    ),
                  )
                ]),
              ),
              Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 25, vertical: 5),
                  child: Stack(children: [
                    Container(
                      width: 270,
                      height: 20,
                      alignment: Alignment.centerLeft,
                      child: Container(
                        decoration: new BoxDecoration(
                          color: backgroundColor,
                          shape: BoxShape.rectangle,
                          borderRadius: BorderRadius.all(Radius.circular(16.0)),
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
                          borderRadius: BorderRadius.all(Radius.circular(16.0)),
                        ),
                      ),
                    ),
                  ])),
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
