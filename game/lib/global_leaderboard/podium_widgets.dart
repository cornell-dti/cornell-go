import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/**
 * This file contains the 6 possible podium widgets to appear in the leaderboard 
 * page. For each podium position (1,2,3) there is a red and yellow widget,
 * which is yellow if that is the user's current spot and red otherwise.
 */
class FirstPodiumRed extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
        child: Container(
      width: 106,
      height: 112,
      child: SvgPicture.asset(
        'assets/icons/red1podium.svg',
        semanticsLabel: '1st Red Podium',
      ),
    ));
  }
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

class SecondPodiumRed extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
        child: Container(
      width: 106,
      height: 86,
      child: SvgPicture.asset(
        'assets/icons/red2podium.svg',
        semanticsLabel: '2nd Red Podium',
      ),
    ));
  }
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

class ThirdPodiumRed extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
        child: Container(
      width: 106,
      height: 62,
      child: SvgPicture.asset(
        'assets/icons/red3podium.svg',
        semanticsLabel: '3rd Red Podium',
      ),
    ));
  }
}
