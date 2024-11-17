import 'package:flutter/material.dart';
import 'package:game/preview/preview.dart';
import 'package:flutter_svg/flutter_svg.dart';

/**
 * `ChallengeCell` Widget - Individual challenge display component.
 * 
 * @remarks
 * This widget represents a single challenge card in the challenges list.
 * It displays key information about a challenge and handles tap interactions
 * to show more details.
 * 
 * @param props - Contains:
 *   - `location`: Challenge location
 *   - `challengeName`: Name of the challenge
 *   - `challengeLat`: Latitude coordinate
 *   - `challengeLong`: Longitude coordinate
 *   - `imgUrl`: Challenge image URL
 *   - `isCompleted`: Completion status
 *   - `description`: Challenge description
 *   - `difficulty`: Challenge difficulty level
 *   - `points`: Points awarded for completion
 *   - `eventId`: Unique identifier for the challenge
 */
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(10.0)),
            ),
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
        height: MediaQuery.sizeOf(context).height * 0.15,
        width: MediaQuery.sizeOf(context).width * 0.85,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 14),
                child: ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(4.6)),
                  child: Image.network(imgUrl,
                      width: MediaQuery.sizeOf(context).height * 0.1,
                      height: MediaQuery.sizeOf(context).height * 0.1,
                      fit: BoxFit.cover),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: MediaQuery.sizeOf(context).height * 0.005,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Icon(Icons.location_on,
                              size: MediaQuery.sizeOf(context).height * 0.025,
                              color: Color.fromARGB(255, 131, 90, 124)),
                          Expanded(
                            child: Text(
                              location,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Color.fromARGB(255, 131, 90, 124),
                                fontSize:
                                    MediaQuery.sizeOf(context).height * 0.016,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Spacer(),
                    Text(
                      challengeName,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color.fromARGB(204, 0, 0, 0),
                        fontSize: MediaQuery.sizeOf(context).height * 0.02,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: MediaQuery.sizeOf(context).width * 0.02,
                            vertical: MediaQuery.sizeOf(context).height * 0.003,
                          ),
                          decoration: BoxDecoration(
                            color: Color.fromARGB(255, 249, 237, 218),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            difficulty,
                            style: TextStyle(
                              color: Color.fromARGB(204, 0, 0, 0),
                              fontSize:
                                  MediaQuery.sizeOf(context).height * 0.016,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ),
                        SizedBox(
                            width: MediaQuery.sizeOf(context).width * 0.02),
                        Row(children: [
                          SvgPicture.asset(
                            "assets/icons/bearcoins.svg",
                            width: MediaQuery.sizeOf(context).width * 0.06,
                          ),
                          Text(
                            ' ' + points.toString() + " PTS",
                            style: TextStyle(
                              fontSize:
                                  MediaQuery.sizeOf(context).height * 0.018,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFFC17E19),
                            ),
                          ),
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
