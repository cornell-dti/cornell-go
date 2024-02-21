import 'package:flutter/material.dart';
import 'package:game/preview/preview.dart';

class JourneyCell extends StatefulWidget {
  final int locationCount;
  final String journeyName;
  final Image thumbnail;
  final String description;
  final int numberCompleted;
  final bool isCompleted;
  final String difficulty;
  final int points;
  final int challengePoints;

  const JourneyCell(
      this.journeyName,
      this.thumbnail,
      this.description,
      this.locationCount,
      this.numberCompleted,
      this.isCompleted,
      this.difficulty,
      this.points,
      this.challengePoints,
      {Key? key})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _JourneyCellState(
      journeyName,
      thumbnail,
      description,
      locationCount,
      numberCompleted,
      isCompleted,
      difficulty,
      points,
      challengePoints);
}

class _JourneyCellState extends State<JourneyCell> {
  final int locationCount;
  final String journeyName;
  final Image thumbnail;
  final String description;
  final int numberCompleted;
  final bool isCompleted;
  final String difficulty;
  final int points;
  final int challengePoints;

  _JourneyCellState(
      this.journeyName,
      this.thumbnail,
      this.description,
      this.locationCount,
      this.numberCompleted,
      this.isCompleted,
      this.difficulty,
      this.points,
      this.challengePoints);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await showDialog(
            context: context,
            builder: (context) => Preview(
                  journeyName,
                  description,
                  difficulty,
                  points,
                  challengePoints,
                  previewType.journey,
                  locationCount: locationCount,
                  numberCompleted: numberCompleted,
                ));
      },
      child: Container(
        decoration: BoxDecoration(
            border: Border.all(
              color: Color.fromARGB(255, 255, 255, 255),
            ),
            borderRadius: BorderRadius.all(Radius.circular(20))),
        height: 236.0,
        width: 345,
        child: Padding(
          padding: EdgeInsets.all(3.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                  padding: const EdgeInsets.only(right: 2),
                  child: Container(
                      width: MediaQuery.of(context).size.width,
                      height: 113,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          fit: BoxFit.fitWidth,
                          image:
                              NetworkImage("https://picsum.photos/250?image=9"),
                        ),
                      )
                      // alignment:
                      // child: [
                      //   ClipRRect(
                      //     borderRadius: BorderRadius.all(Radius.circular(4.6)),
                      //     child: thumbnail,
                      //   ),
                      // ]

                      )),
              if (isCompleted)
                Flexible(
                  child: Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Text(
                        //   "COMPLETED",
                        //   style: TextStyle(
                        //     color: Color.fromARGB(255, 71, 71, 71),
                        //     fontSize: 10,
                        //     fontWeight: FontWeight.w700,
                        //     fontFamily: 'Lato',
                        //   ),
                        // ),
                        // Column(
                        //   children: [
                        //     FractionallySizedBox(
                        //       alignment: Alignment.topLeft,
                        //       widthFactor: (locationCount > 0
                        //           ? numberCompleted / locationCount
                        //           : 0),
                        //       child: Container(
                        //           color: Color.fromARGB(255, 0, 0, 0)),
                        //     ),
                        //     Icon(Icons.location_on,
                        //         size: 20, color: Colors.purple),
                        //     Text(
                        //       numberCompleted.toString(),
                        //       style: TextStyle(
                        //         color: Color.fromARGB(179, 0, 0, 0),
                        //         fontSize: 12,
                        //         fontFamily: 'Lato',
                        //       ),
                        //     ),
                        //   ],
                        // ),
                      ],
                    ),
                  ),
                ),
              Container(
                  height: 24,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Icon(Icons.tour, size: 15, color: Color.fromARGB(255, 131, 90, 124)),
                      Text(
                        "location",
                        style: TextStyle(
                          color: Color.fromARGB(255, 131, 90, 124),
                          fontSize: 16,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      Spacer(),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 3),
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
                      SizedBox(width: 10), // Add spacing between buttons
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
                            challengePoints.toString() + "PTS",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  )),
              Container(
                height: 25,
                child: Text(
                  journeyName,
                  style: TextStyle(
                      color: Color.fromARGB(255, 0, 0, 0),
                      fontSize: 16,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                height: 21,
                child: Text(
                  description,
                  style: TextStyle(
                    color: Color.fromARGB(179, 0, 0, 0),
                    fontSize: 14,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 9),
                child: Row(
                  children: [
                    Container(
                      width: 260,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          height: 20.0,
                          width: 10.0,
                          // width: double.infinity,
                          color: Color.fromARGB(255, 255, 255, 255),
                          child: FractionallySizedBox(
                            alignment: Alignment.topLeft,
                            widthFactor: (locationCount > 0
                                ? numberCompleted / locationCount
                                : 0),
                            child:
                                Container(color: Color.fromARGB(191, 237, 86, 86)),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Container(
                      width: 50,
                      child: Row(children: [
                        Icon(Icons.location_on, size: 10, color: Color.fromARGB(255, 131, 90, 124)),
                        Text(
                          numberCompleted.toString() + "/_",
                          style: TextStyle(
                            color: Color.fromARGB(255, 110, 110, 110),
                            fontSize: 16,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ]),
                    )
                    // Container(
                    //   height: 3,
                    //   child: Text(
                    //     numberCompleted.toString(),
                    //     style: TextStyle(
                    //       color: Color.fromARGB(255, 0, 0, 0),
                    //       fontSize: 18,
                    //       fontFamily: 'Lato',
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
