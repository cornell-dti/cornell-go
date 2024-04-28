import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:game/preview/preview.dart';
import 'package:flutter_svg/flutter_svg.dart';

class JourneyCell extends StatefulWidget {
  final int locationCount;
  final String location;
  final String journeyName;
  final double? challengeLong;
  final double? challengeLat;
  final String imgUrl;
  final String description;
  final int numberCompleted;
  final bool isCompleted;
  final String difficulty;
  final int points;
  final String id;

  const JourneyCell(
      this.journeyName,
      this.challengeLat,
      this.challengeLong,
      this.location,
      this.imgUrl,
      this.description,
      this.locationCount,
      this.numberCompleted,
      this.isCompleted,
      this.difficulty,
      this.points,
      this.id,
      {Key? key})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _JourneyCellState(
      journeyName,
      challengeLat,
      challengeLong,
      location,
      imgUrl,
      description,
      locationCount,
      numberCompleted,
      isCompleted,
      difficulty,
      points,
      id);
}

class _JourneyCellState extends State<JourneyCell> {
  final int locationCount;
  final String journeyName;
  final double? challengeLong;
  final double? challengeLat;
  final String location;
  final String imgUrl;
  final String description;
  final int numberCompleted;
  final bool isCompleted;
  final String difficulty;
  final int points;
  final String id;
  // final int totalDistance;

  _JourneyCellState(
    this.journeyName,
    this.challengeLat,
    this.challengeLong,
    this.location,
    this.imgUrl,
    this.description,
    this.locationCount,
    this.numberCompleted,
    this.isCompleted,
    this.difficulty,
    this.points,
    this.id,
    // this.totalDistance
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
                    journeyName,
                    challengeLat,
                    challengeLong,
                    description,
                    imgUrl,
                    difficulty,
                    points,
                    PreviewType.JOURNEY,
                    location,
                    id,
                    locationCount: locationCount,
                    numberCompleted: numberCompleted));
      },
      child: Container(
        width: MediaQuery.sizeOf(context).width * 0.9,
        height: MediaQuery.sizeOf(context).height * 0.3,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: Color.fromARGB(255, 255, 255, 255),
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 1,
              blurRadius: 2,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Container(
                width: double.infinity,
                height: MediaQuery.sizeOf(context).height * 0.15,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10)),
                  image: DecorationImage(
                    fit: BoxFit.cover,
                    image: NetworkImage(imgUrl),
                  ),
                )),
            Positioned(
              top: 10.0,
              left: 16.0,
              child: Container(
                height: 31.58,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: ShapeDecoration(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset(
                      "assets/images/locationVector.png",
                      alignment: Alignment.centerLeft,
                    ),
                    Padding(padding: EdgeInsets.symmetric(horizontal: 5)),
                    Text(
                      widget.location,
                      style: TextStyle(
                        color: Color(0xFF835A7C),
                        fontSize: 16,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w400,
                        height: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              child: Container(
                width: MediaQuery.sizeOf(context).width,
                decoration: ShapeDecoration(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(10),
                          bottomRight: Radius.circular(10))),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 17.0, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.journeyName,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      widget.description,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    SizedBox(height: 5),
                    Row(
                      children: [
                        Container(
                          width: 70,
                          height: 25,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 2, vertical: 2),
                          decoration: ShapeDecoration(
                            color: Color(0xFFF9EDDA),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              widget.difficulty,
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w400,
                                height: 0,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Row(children: [
                          SvgPicture.asset(
                            "assets/icons/bearcoins.svg",
                            width: 25,
                          ),
                          Text(' ' + points.toString() + " PTS",
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFFC17E19)))
                        ]),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 15.0, bottom: 5),
                      child: Row(
                        children: [
                          Stack(children: [
                            Container(
                              width: MediaQuery.sizeOf(context).width * 0.66,
                              height: 22,
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
                                  MediaQuery.sizeOf(context).width *
                                  0.66,
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
                          SizedBox(width: 8),
                          Container(
                            width: 50,
                            child: Row(children: [
                              SvgPicture.asset("assets/icons/pin.svg"),
                              Text(
                                " " +
                                    numberCompleted.toString() +
                                    "/" +
                                    locationCount.toString(),
                                style: TextStyle(
                                  color: Color.fromARGB(255, 110, 110, 110),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ]),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
