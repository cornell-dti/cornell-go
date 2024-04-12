import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/**
 * This file contains the 6 possible podium widgets to appear in the leaderboard 
 * page. For each podium position (FirstPodium, SecndPodium, ThridPodium) there is a red and orange asset svg variation,
 * which is orange if that is the user's current spot and red otherwise.
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

  return Center(
      child: Container(
          width: 106,
          height: 112,
          child:
              Stack(alignment: FractionalOffset(0.5, 0.58), children: <Widget>[
            SvgPicture.asset(
              svgAssetPath,
              semanticsLabel: '1st Podium',
            ),

            SizedBox(
              width: 60,
              height: 29,
              child: FittedBox(
                alignment: Alignment.center,
                fit: BoxFit.scaleDown,
                child: Text(points.toString() + " PTS", style: pointsStyle),
              ),
            ),
            // Text(points.toString() + " PTS"
          ])));
}

Widget SecondPodium(context, int points, bool isUser) {
  String svgAssetPath = isUser
      ? 'assets/icons/podium2highlighted.svg'
      : 'assets/icons/podium2red.svg';

  return Center(
      child: Container(
          width: 106,
          height: 86,
          child:
              Stack(alignment: FractionalOffset(0.5, 0.63), children: <Widget>[
            SvgPicture.asset(
              svgAssetPath,
              semanticsLabel: '2nd Podium',
            ),

            SizedBox(
              width: 60,
              height: 29,
              child: FittedBox(
                alignment: Alignment.center,
                fit: BoxFit.scaleDown,
                child: Text(points.toString() + " PTS", style: pointsStyle),
              ),
            ),
            // Text(points.toString() + " PTS"
          ])));
}

Widget ThirdPodium(context, int points, bool isUser) {
  String svgAssetPath = isUser
      ? 'assets/icons/podium3highlighted.svg'
      : 'assets/icons/podium3red.svg';
  return Center(
      child: Container(
          width: 106,
          height: 62,
          child:
              Stack(alignment: FractionalOffset(0.5, 0.75), children: <Widget>[
            SvgPicture.asset(
              svgAssetPath,
              semanticsLabel: '3rd Podium',
            ),

            SizedBox(
              width: 60,
              height: 29,
              child: FittedBox(
                alignment: Alignment.center,
                fit: BoxFit.scaleDown,
                child: Text(points.toString() + " PTS", style: pointsStyle),
              ),
            ),
            // Text(points.toString() + " PTS"
          ])));
}
