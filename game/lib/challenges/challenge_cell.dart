import 'package:flutter/material.dart';
import 'package:game/preview/preview.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:game/constants/constants.dart';

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
  final double? distanceFromChallenge;
  final bool featured;

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
    this.distanceFromChallenge,
    this.featured, {
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
        featured,
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
  final double? distanceFromChallenge;
  final bool featured;

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
    this.distanceFromChallenge,
    this.featured,
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
              color: AppColors.silverGray,
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
                  child: Image.network(
                    imgUrl,
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
                            color: AppColors.purple,
                          ),
                          Expanded(
                            child: Text(
                              location,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.purple,
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
                              color: AppColors.grayText,
                            ),
                            Text(
                              ' ' +
                                  (distanceFromChallenge! / 1609.34)
                                      .toStringAsFixed(1) +
                                  ' mi away',
                              style: TextStyle(
                                color: AppColors.grayText,
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
                        color: AppColors.black80,
                        fontSize: deviceHeight * 0.02,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        if (featured) ...[
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: deviceWidth * 0.02,
                              vertical: deviceHeight * 0.003,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.dangerRed,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Featured',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: deviceHeight * 0.014,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          SizedBox(width: deviceWidth * 0.01),
                        ],
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: deviceWidth * 0.02,
                            vertical: deviceHeight * 0.003,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.cream,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            difficulty,
                            style: TextStyle(
                              color: AppColors.black80,
                              fontSize: deviceHeight * 0.014,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ),
                        SizedBox(width: deviceWidth * 0.01),
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SvgPicture.asset(
                                "assets/icons/bearcoins.svg",
                                width: deviceWidth * 0.05,
                              ),
                              Flexible(
                                child: Text(
                                  ' ' + points.toString() + " PTS",
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: deviceHeight * 0.016,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.gold,
                                  ),
                                ),
                              ),
                            ],
                          ),
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
