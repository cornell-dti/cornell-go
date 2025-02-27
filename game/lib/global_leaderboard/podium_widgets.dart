import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/**
 * 'PodiumBlock' widget - Displays leaderboard podium 
 * 
 * This file contains a dynamic podium widget block to appear in the leaderboard 
 * page. For each of the 4 possible podium positions (1st,2nd,3rd,Not in top 3) there is,
 *  there is a differet image variation which highlights the corresponding podium in orange.
 * 
 * @param props - Contains:
 * - 'position': Current position of user 
 * - 'scoreList': Number of points for the top 3 users 
 */

var pointsStyle = TextStyle(
  color: Colors.white,
  fontSize: 14,
  fontFamily: 'Poppins',
  fontWeight: FontWeight.w500,
  height: 0,
);

Widget FirstPodium(context, int points, bool isUser) {
  // Choosing whetehr podum is highlighted or not by isUser condition
  String svgAssetPath = isUser
      ? 'assets/icons/podium1highlighted.svg'
      : 'assets/icons/podium1red.svg';

  return Align(
    alignment: Alignment.bottomCenter,
    child: Stack(alignment: Alignment.bottomCenter, children: <Widget>[
      SvgPicture.asset(
        width: MediaQuery.sizeOf(context).width * 0.25,
        isUser
            ? 'assets/icons/podium1user.svg'
            : 'assets/icons/podium1blank.svg',
        semanticsLabel: '1st Podium',
      ),
      Positioned(
        bottom: MediaQuery.sizeOf(context).height * 0.025,
        child: Container(
          width: 68,
          height: 29,
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          decoration: ShapeDecoration(
            color: Color.fromRGBO(234, 177, 17, 1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: Center(
            child: Text(
              points.toString() + " PTS",
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w400,
                height: 0,
              ),
            ),
          ),
        ),
      ),
    ]),
  );
}

Widget SecondPodium(context, int points, bool isUser) {
  String svgAssetPath = isUser
      ? 'assets/icons/podium2highlighted.svg'
      : 'assets/icons/podium2red.svg';

  return Align(
    alignment: Alignment.bottomCenter,
    child: Stack(alignment: Alignment.bottomCenter, children: <Widget>[
      SvgPicture.asset(
        width: MediaQuery.sizeOf(context).width * 0.25,
        isUser
            ? 'assets/icons/podium2user.svg'
            : 'assets/icons/podium2blank.svg',
        semanticsLabel: '2nd Podium',
      ),
      Positioned(
        bottom: MediaQuery.sizeOf(context).height * 0.01,
        child: Container(
          width: 68,
          height: 29,
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          decoration: ShapeDecoration(
            color: Color.fromRGBO(171, 173, 173, 1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: Center(
            child: Text(
              points.toString() + " PTS",
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w400,
                height: 0,
              ),
            ),
          ),
        ),
      ),
    ]),
  );
}

Widget ThirdPodium(context, int points, bool isUser) {
  String svgAssetPath = isUser
      ? 'assets/icons/podium3highlighted.svg'
      : 'assets/icons/podium3red.svg';

  return Align(
    alignment: Alignment.bottomCenter,
    child: Stack(alignment: Alignment.bottomCenter, children: <Widget>[
      SvgPicture.asset(
        width: MediaQuery.sizeOf(context).width * 0.25,
        isUser
            ? 'assets/icons/podium3user.svg'
            : 'assets/icons/podium3blank.svg',
        semanticsLabel: '3rd Podium',
      ),
      Positioned(
        bottom: MediaQuery.sizeOf(context).height * 0.006,
        child: Container(
          width: 68,
          height: 25,
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          decoration: ShapeDecoration(
            color: Color.fromRGBO(219, 120, 42, 1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: Center(
            child: Text(
              points.toString() + " PTS",
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w400,
                height: 0,
              ),
            ),
          ),
        ),
      ),
    ]),
  );
}
