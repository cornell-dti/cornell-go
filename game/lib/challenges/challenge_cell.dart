import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:game/preview/preview.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shimmer/shimmer.dart';

/**
 * `ChallengeCell` Widget - Individual challenge display component.
 * 
 * @remarks
 * This widget represents a single challenge card in the challenges list.
 * It displays key information about a challenge and handles tap interactions
 * to show more details.
 * 
 * Image loading uses CachedNetworkImage, with a shimmer placeholder for 
 * when the image is loading and an error icon with a gray background if 
 * the image cannot be loaded. The gray background of the error matches the
 * original size of the image.

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
  final double? distanceFromChallenge;

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
    this.distanceFromChallenge, {
    Key? key,
  }) : super(key: key);

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
        eventId,
        distanceFromChallenge,
      );
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
  final double? distanceFromChallenge;

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
    this.eventId,
    // newly added field
    // this.totalDistance
    this.distanceFromChallenge,
  );

  @override
  Widget build(BuildContext context) {
    double deviceWidth = MediaQuery.sizeOf(context).width;
    double deviceHeight = MediaQuery.sizeOf(context).height;

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
            eventId,
          ),
        );
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
        height: deviceHeight * 0.15,
        width: deviceWidth * 0.85,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 14),
                child: ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(4.6)),
                  child: CachedNetworkImage(
                    // imageUrl: 'https://invalid-domain-xyz-12345.com/image.png',
                    imageUrl:
                        'https://upload.wikimedia.org/wikipedia/commons/3/3f/Fronalpstock_big.jpg',
                    //testing error with invalid url
                    // imageUrl: imgUrl,
                    placeholder: (context, url) => Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        width: deviceHeight * 0.1,
                        height: deviceHeight * 0.1,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4.6),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: deviceHeight * 0.1,
                      height: deviceHeight * 0.1,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4.6),
                      ),
                      child: Icon(Icons.error),
                    ),
                    width: deviceHeight * 0.1,
                    height: deviceHeight * 0.1,
                    fit: BoxFit.cover,
                  ),
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
                          Icon(
                            Icons.location_on,
                            size: MediaQuery.sizeOf(context).height * 0.025,
                            color: Color.fromARGB(255, 131, 90, 124),
                          ),
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
                          //match formatting of previous distance display and text above (text shown adjacent to this icon)
                          if (distanceFromChallenge != null) ...[
                            Icon(
                              Icons.directions_walk,
                              size: MediaQuery.sizeOf(context).height * 0.02,
                              color: Color.fromARGB(255, 110, 110, 110),
                            ),
                            Text(
                              ' ' +
                                  (distanceFromChallenge! / 1609.34)
                                      .toStringAsFixed(1) +
                                  ' mi away',
                              style: TextStyle(
                                color: Color.fromARGB(255, 110, 110, 110),
                                fontSize:
                                    MediaQuery.sizeOf(context).height * 0.011,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Spacer(),
                    Text(
                      challengeName,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color.fromARGB(204, 0, 0, 0),
                        fontSize: deviceHeight * 0.02,
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
                            horizontal: deviceWidth * 0.02,
                            vertical: deviceHeight * 0.003,
                          ),
                          decoration: BoxDecoration(
                            color: Color.fromARGB(255, 249, 237, 218),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            difficulty,
                            style: TextStyle(
                              color: Color.fromARGB(204, 0, 0, 0),
                              fontSize: deviceHeight * 0.016,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ),
                        SizedBox(width: deviceWidth * 0.02),
                        Row(
                          children: [
                            SvgPicture.asset(
                              "assets/icons/bearcoins.svg",
                              width: deviceWidth * 0.06,
                            ),
                            Text(
                              ' ' + points.toString() + " PTS",
                              style: TextStyle(
                                fontSize: deviceHeight * 0.018,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFFC17E19),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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
