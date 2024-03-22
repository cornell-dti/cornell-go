import 'package:flutter/material.dart';
import 'package:game/preview/preview.dart';

class JourneyCell extends StatefulWidget {
  final int locationCount;
  final String journeyName;
  final String eventId;
  final Image thumbnail;
  final String description;
  final int numberCompleted;
  final bool isCompleted;
  final String difficulty;
  final String location;
  final String category;
  final int totalPoints;
  final double totalDistance;

  const JourneyCell(
      this.journeyName,
      this.eventId,
      this.thumbnail,
      this.description,
      this.locationCount,
      this.numberCompleted,
      this.isCompleted,
      this.difficulty,
      this.location,
      this.category,
      this.totalPoints,
      this.totalDistance,
      {Key? key})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _JourneyCellState(
      journeyName,
      eventId,
      thumbnail,
      description,
      locationCount,
      numberCompleted,
      isCompleted,
      difficulty,
      location,
      category,
      totalPoints,
      totalDistance);
}

class _JourneyCellState extends State<JourneyCell> {
  final int locationCount;
  final String journeyName;
  final String eventId;
  final Image thumbnail;
  final String description;
  final int numberCompleted;
  final bool isCompleted;
  final String difficulty;
  final String location;
  final String category;
  final int totalPoints;
  final double totalDistance;

  _JourneyCellState(
    this.journeyName,
    this.eventId,
    this.thumbnail,
    this.description,
    this.locationCount,
    this.numberCompleted,
    this.isCompleted,
    this.difficulty,
    this.location,
    this.category,
    this.totalPoints,
    this.totalDistance,
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
              builder: (
                BuildContext context,
              ) =>
                  Preview(
                    eventId,
                    journeyName,
                    thumbnail,
                    description,
                    difficulty,
                    location,
                    category,
                    totalPoints,
                    totalDistance,
                    previewType.journey,
                    locationCount: locationCount,
                    numberCompleted: numberCompleted,
                  ));
          // await showDialog(
          //     context: context,
          //     builder: (context) => Preview(
          //           journeyName,
          //           description,
          //           difficulty,
          //           points,
          //           challengePoints,
          //           previewType.journey,
          //           locationCount: locationCount,
          //           numberCompleted: numberCompleted,
          //         ));
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: Color.fromARGB(255, 255, 255, 255),
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 1,
                blurRadius: 2,
                offset: Offset(0, 2),
              ),
            ],
          ),
          height: 236.0,
          width: 345,
          child: Padding(
            padding: EdgeInsets.all(3.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Padding(
                //     padding: const EdgeInsets.only(right: 2),
                Container(
                    width: double.infinity,
                    // width: MediaQuery.of(context).size.width,
                    height: 113,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20)),
                      image: DecorationImage(
                        fit: BoxFit.fill,
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

                    ),
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
                SizedBox(
                  height: 5,
                ),
                Container(
                    height: 24,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Icon(Icons.tour,
                            size: 15, color: Color.fromARGB(255, 131, 90, 124)),
                        Text(
                          location,
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
                            totalPoints.toString() + "PTS",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    )),
                SizedBox(
                  height: 5,
                ),
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
                      Stack(children: [
                        Container(
                          width: 260,
                          height: 20,
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
                              260,
                          height: 20,
                          alignment: Alignment.centerLeft,
                          child: Container(
                            decoration: new BoxDecoration(
                              color: Color.fromARGB(191, 237, 86, 86),
                              shape: BoxShape.rectangle,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(16.0)),
                            ),
                          ),
                        ),
                      ]),
                      // Container(
                      //   width: 260,
                      //   child: ClipRRect(
                      //     borderRadius: BorderRadius.circular(10),
                      //     child: Container(
                      //       height: 20.0,
                      //       width: 10.0,
                      //       color: Color.fromARGB(255, 255, 255, 255),
                      //       child: FractionallySizedBox(
                      //         alignment: Alignment.topLeft,
                      //         widthFactor: (locationCount > 0
                      //             ? numberCompleted / locationCount
                      //             : 0),
                      //         child: Container(
                      //             color: Color.fromARGB(191, 237, 86, 86)),
                      //       ),
                      //     ),
                      //   ),
                      // ),
                      SizedBox(width: 8),
                      Container(
                        width: 50,
                        child: Row(children: [
                          Icon(Icons.location_on,
                              size: 16,
                              color: Color.fromARGB(255, 131, 90, 124)),
                          Text(
                            numberCompleted.toString() +
                                "/" +
                                locationCount.toString(),
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
        ));
  }
}
