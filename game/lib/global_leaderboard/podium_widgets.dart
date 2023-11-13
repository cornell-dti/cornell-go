import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class PodiumWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
        child: Container(
      width: 328,
      height: 112,
      child: SvgPicture.asset(
        'assets/images/podium.svg',
        semanticsLabel: 'Podium',
      ),
    ));
  }
}

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
      height: 59,
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
      height: 59,
      child: SvgPicture.asset(
        'assets/icons/red3podium.svg',
        semanticsLabel: '3rd Red Podium',
      ),
    ));
  }
}
