import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:game/gameplay/gameplay_page.dart';
import 'package:game/api/game_api.dart';
import 'package:game/api/game_client_dto.dart';
import 'package:provider/provider.dart';

enum previewType { challenge, journey }

/** Returns a preview of a challenge given the challenge name, description, 
 * difficulty, points, and bonus points for challenge mode. Used for
 * both Challenges and Journeys. */
class Preview extends StatefulWidget {
  final String eventId;
  final String challengeName;
  final Image thumbnail;
  final String description;
  final String difficulty;
  final String location;
  final String category;
  final int points;
  final double distance;
  final previewType type;

  final int locationCount;
  final int numberCompleted;

// newly added parameters; need to implement higher up in hierarchy
  // final int
  //     totalDistance;

  static Color backgroundColor = Color.fromARGB(255, 217, 214, 213);
  static Color purpleColor = Color.fromARGB(255, 131, 90, 124);
  static Color greyColor = Color.fromARGB(255, 110, 110, 110);

  //Temporary image for now. Will have to change later
  // final String imgPath = "assets/images/38582.jpg";

  Preview(
      this.eventId,
      this.challengeName,
      this.thumbnail,
      this.description,
      this.difficulty,
      this.location,
      this.category,
      this.points,
      this.distance,
      this.type,
      {this.locationCount = 1,
      this.numberCompleted = 0,
      // required this.totalDistance,
      Key? key})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _PreviewState(
      eventId,
      challengeName,
      thumbnail,
      description,
      difficulty,
      location,
      category,
      points,
      distance,
      type,
      locationCount,
      numberCompleted);
}

/**Builds a widget based on the current state which is needed for toggleable 
 * challenge_on button */
class _PreviewState extends State<Preview> {
  final String eventId;
  final String challengeName;
  final Image thumbnail;
  final String description;
  final String difficulty;
  final String location;
  final String category;
  final int points;
  final double distance;
  final previewType type;

  bool _challenge_on = false;

  static Color backgroundRed = Color.fromARGB(255, 237, 86, 86);
  static Color backgroundRedMuted = Color.fromARGB(191, 237, 86, 86);

  //fields unique to journeys
  final int locationCount;
  final int numberCompleted;

  //Temporary image for now. Will have to change later
  // final String imgPath = "assets/images/38582.jpg";

  _PreviewState(
      this.eventId,
      this.challengeName,
      this.thumbnail,
      this.description,
      this.difficulty,
      this.location,
      this.category,
      this.points,
      this.distance,
      this.type,
      this.locationCount,
      this.numberCompleted);
  @override
  Widget build(BuildContext context) {
    //The popup box
    return SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.0),
            topRight: Radius.circular(20.0),
          ),

          //Overall Container
          child: Container(
              height: MediaQuery.of(context).size.height * 0.75,
              width: MediaQuery.of(context).size.width,
              color: Colors.white,
              child: Column(
                children: [
                  //Image
                  Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(3.0),
                          topRight: Radius.circular(3.0),
                        ),
                        image: DecorationImage(
                            image: thumbnail.image, fit: BoxFit.cover)),
                    height: 150,
                    alignment: Alignment.topCenter,
                    //drag bar icon
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                            child: SizedBox(
                                child: Align(
                          alignment: Alignment(1.1, -1.1),
                          child: Container(
                            width: 48,
                            height: 4,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.rectangle,
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(20.0)),
                            ),
                          ),
                        )))
                      ],
                    ),
                  ),
                  SizedBox(height: 20),

                  // Row with starting location and distance
                  Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 25.0, vertical: 5),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Row(children: [
                          Icon(Icons.tour,
                              size: 24, color: Preview.purpleColor),
                          Text(location,
                              style: TextStyle(
                                  fontSize: 20, color: Preview.purpleColor)),
                          if (type == previewType.journey) SizedBox(width: 10),
                          if (type == previewType.journey)
                            Icon(Icons.directions_walk,
                                size: 24, color: Preview.greyColor),
                          if (type == previewType.journey)
                            Text(distance.toString() + "mi",
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
                                              padding: const EdgeInsets.only(
                                                  left: 8, right: 8),
                                              child: Align(
                                                alignment: Alignment.center,
                                                child: Text(
                                                  (points).toString() + "PTS",
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
                  (type == previewType.journey)
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
                            print("Unimplemented. Starting Challenge!");
                            Consumer<ApiClient>(
                              builder: (context, apiClient, child) {
                                apiClient.serverApi?.setCurrentEvent(eventId);
                                return Container();
                              },
                            );
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => GameplayPage()));
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
        ));
  }
}
