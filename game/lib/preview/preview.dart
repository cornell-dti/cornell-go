import 'package:flutter/material.dart';
import 'package:game/api/game_api.dart';
import 'package:game/gameplay/gameplay_page.dart';
import 'package:provider/provider.dart';
import 'package:game/api/game_client_dto.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum PreviewType { CHALLENGE, JOURNEY }

/** Returns a preview of a challenge given the challenge name, description, 
 * difficulty, points, and bonus points for challenge mode. Used for
 * both Challenges and Journeys. */
class Preview extends StatefulWidget {
  final String challengeName;
  final String description;
  final String imgUrl;
  final String difficulty;
  final int points;
  final PreviewType type;

  final int locationCount;
  final int numberCompleted;
  final String location;
  final String eventId;

// newly added parameters; need to implement higher up in hierarchy
  // final int
  //     totalDistance;

  static Color backgroundColor = Color.fromARGB(255, 217, 214, 213);
  static Color purpleColor = Color.fromARGB(255, 131, 90, 124);
  static Color greyColor = Color.fromARGB(255, 110, 110, 110);

  Preview(this.challengeName, this.description, this.imgUrl, this.difficulty,
      this.points, this.type, this.location, this.eventId,
      {this.locationCount = 1,
      this.numberCompleted = 0,
      // required this.totalDistance,
      Key? key})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _PreviewState(
      challengeName,
      description,
      imgUrl,
      difficulty,
      points,
      type,
      locationCount,
      numberCompleted,
      location,
      eventId
      // need to figure out newly added parameters; commented out for now
      // totalDistance,
      );
}

/**Builds a widget based on the current state which is needed for toggleable 
 * challenge_on button */
class _PreviewState extends State<Preview> {
  final String challengeName;
  final String description;
  final String imgUrl;
  final String difficulty;
  final int points;
  final PreviewType type;
  // newly added parameter; need to implement higher up in hierarchy
  // final int
  //     totalDistance;
  final String location;

  static Color backgroundRed = Color.fromARGB(255, 237, 86, 86);
  static Color backgroundRedMuted = Color.fromARGB(191, 237, 86, 86);

  //fields unique to journeys
  final int locationCount;
  final int numberCompleted;
  final String eventId;

  _PreviewState(
      this.challengeName,
      this.description,
      this.imgUrl,
      this.difficulty,
      this.points,
      this.type,
      this.locationCount,
      this.numberCompleted,
      this.location,
      this.eventId
      // newly added; commented out for now
      // this.totalDistance,
      );
  @override
  Widget build(BuildContext context) {
    //The popup box
    return SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(10.0),
            topRight: Radius.circular(10.0),
            topLeft: Radius.circular(10.0),
            topRight: Radius.circular(10.0),
          ),

          //Overall Container
          child: Container(
              color: Colors.white,
              child: Column(
                children: [
                  //Image
                  Image.network(imgUrl,
                      height: 200, width: 500, fit: BoxFit.cover),
                  SizedBox(height: 20),

                  // Row with starting location and distance
                  Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 25.0, vertical: 5),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Row(children: [
                          Icon(Icons.location_on,
                              size: 24, color: Preview.purpleColor),
                          Text(location,
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
                      )),
                  Padding(
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
                  Container(
                    height: MediaQuery.of(context).size.height * 0.12,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 25.0, vertical: 8.0),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Text(description,
                            style: TextStyle(
                                // fontWeight: FontWeight.bold,
                                fontSize: 16,
                                fontFamily: 'Poppins',
                                color: Preview.greyColor)),
                      ),
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 25, right: 25, bottom: 15),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Expanded(
                            child: SizedBox(
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                              padding: const EdgeInsets.only(
                                                  left: 8, right: 8),
                                              child: Align(
                                                alignment: Alignment.center,
                                                child: Text(
                                                  difficulty[0].toUpperCase() +
                                                      difficulty.substring(1),
                                                  style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w400,
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
                                          child: Row(children: [
                                            SvgPicture.asset(
                                              "assets/icons/bearcoins.svg",
                                              width: 40,
                                              height: 40,
                                            ),
                                            Text(
                                                ' ' +
                                                    points.toString() +
                                                    " PTS",
                                                style: TextStyle(
                                                    fontSize: 23,
                                                    fontWeight: FontWeight.w500,
                                                    color: Color(0xFFC17E19)))
                                          ]),
                                        )),
                                  ],
                                ),
                              ),
                            ),
                          )
                        ]),
                  ),
                  (type == PreviewType.JOURNEY)
                      ? Column(children: [
                          SizedBox(height: 5),
                          Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 25),
                              child: Stack(children: [
                                Container(
                                  width: 345,
                                  height: 24,
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    decoration: new BoxDecoration(
                                      color: Color.fromARGB(255, 241, 241, 241),
                                      shape: BoxShape.rectangle,
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(16.0)),
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
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(16.0)),
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
                                              size: 15,
                                              color: Preview.purpleColor),
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
                              shape: MaterialStateProperty.all<
                                      RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                      side: BorderSide(color: backgroundRed)))),
                          onPressed: () {
                            Provider.of<ApiClient>(context, listen: false)
                                .serverApi
                                ?.setCurrentEvent(
                                    SetCurrentEventDto(eventId: eventId));
                            print("setting current event to " + eventId);
                            Navigator.pop(context);
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => GameplayPage()));
                          },
                          child: Text(
                            (numberCompleted == 0)
                                ? "Let's Go!"
                                : "Continue exploring",
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
        ));
  }
}
