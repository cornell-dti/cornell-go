import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/**
 * This file contains the 6 possible podium widgets to appear in the leaderboard 
 * page. For each podium position (1,2,3) there is a red and yellow widget,
 * which is yellow if that is the user's current spot and red otherwise.
 */
// class FirstPodiumRed extends StatelessWidget {
// @override

var pointsStyle = TextStyle(
  color: Colors.white,
  fontSize: 14,
  fontFamily: 'Poppins',
  fontWeight: FontWeight.w500,
  height: 0,
);

Widget FirstPodium(context, int points, bool isUser) {
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
              semanticsLabel: '1st Red Podium',
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

class FirstPodiumYellow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
        child: Container(
      width: 106,
      height: 112,
      child: SvgPicture.asset(
        'assets/icons/yellow1podium.svg',
        semanticsLabel: '1st Yellow Podium',
      ),
    ));
  }
}

// class SecondPodiumRed extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Center(
//         child: Container(
//       width: 106,
//       height: 86,
//       child: SvgPicture.asset(
//         'assets/icons/podium2red.svg',
//         semanticsLabel: '2nd Red Podium',
//       ),
//     ));
//   }
// }

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
              semanticsLabel: '2nd Red Podium',
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

class SecondPodiumYellow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
        child: Container(
      width: 106,
      height: 86,
      child: SvgPicture.asset(
        'assets/icons/yellow2podium.svg',
        semanticsLabel: '2nd Yellow Podium',
      ),
    ));
  }
}

class ThirdPodiumYellow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
        child: Container(
      width: 106,
      height: 62,
      child: SvgPicture.asset(
        'assets/icons/yellow3podium.svg',
        semanticsLabel: '3rd Yellow Podium',
      ),
    ));
  }
}

// class ThirdPodiumRed extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Center(
//         child: Container(
//       width: 106,
//       height: 62,
//       child: SvgPicture.asset(
//         'assets/icons/podium3red.svg',
//         semanticsLabel: '3rd Red Podium',
//       ),
//     ));
//   }
// }

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
              semanticsLabel: '3rd Red Podium',
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
