import 'package:flutter/material.dart';
import 'package:game/preview/preview.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ChallengeCell extends StatefulWidget {
  final String location;
  final String challengeName;
  final double? challengeLat;
  final double? challengeLong;
  final String imgUrl;
  final bool isCompleted;
  final String description;
  final String difficulty;
  final int points;
  final String eventId;

  const ChallengeCell(
      this.location,
      this.challengeName,
      this.challengeLat,
      this.challengeLong,
      this.imgUrl,
      this.isCompleted,
      this.description,
      this.difficulty,
      this.points,
      this.eventId,
      {Key? key})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _ChallengeCellState(
      location,
      challengeName,
      challengeLat,
      challengeLong,
      imgUrl,
      isCompleted,
      description,
      difficulty,
      points,
      eventId);
}

class _ChallengeCellState extends State<ChallengeCell> {
  final String location;
  final String challengeName;
  final double? challengeLat;
  final double? challengeLong;
  final String imgUrl;
  final bool isCompleted;
  final String description;
  final String difficulty;
  final int points;
  final String eventId;
  // newly added field
  // final int totalDistance;

  _ChallengeCellState(
      this.location,
      this.challengeName,
      this.challengeLat,
      this.challengeLong,
      this.imgUrl,
      this.isCompleted,
      this.description,
      this.difficulty,
      this.points,
      this.eventId
      // newly added field
      // this.totalDistance
      );

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) => Preview(
                challengeName,
                challengeLat,
                challengeLong,
                description,
                imgUrl,
                difficulty,
                points,
                PreviewType.CHALLENGE,
                location,
                eventId));
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Color.fromARGB(255, 198, 198, 198),
              blurRadius: 2,
              offset: Offset(0, 4),
            ),
          ],
        ),
        height: 135.0,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 14),
                child: ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(4.6)),
                  child: Image.network(imgUrl,
                      width: 100, height: 100, fit: BoxFit.cover),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Icon(Icons.location_on,
                            size: 20, color: Color.fromARGB(255, 131, 90, 124)),
                        Text(
                          location,
                          style: TextStyle(
                            color: Color.fromARGB(255, 131, 90, 124),
                            fontSize: 14,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 4,
                    ),
                    Text(
                      challengeName,
                      style: TextStyle(
                        color: Color.fromARGB(204, 0, 0, 0),
                        fontSize: 16.5,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(
                      height: 12,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                          decoration: BoxDecoration(
                            color: Color.fromARGB(255, 249, 237, 218),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            difficulty,
                            style: TextStyle(
                              color: Color.fromARGB(204, 0, 0, 0),
                              fontSize: 10,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
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
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
