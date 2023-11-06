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

class FirstPodium extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
        child: Container(
      width: 106,
      height: 112,
      child: SvgPicture.asset(
        'assets/icons/Podium1stRed.svg',
        semanticsLabel: 'Podium',
      ),
    ));
  }
}

class SecondPodium extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
        child: Container(
      width: 106,
      height: 86,
      child: SvgPicture.asset(
        'assets/icons/Podium2ndRed.svg',
        semanticsLabel: 'Podium2',
      ),
    ));
  }
}

class ThirdPodium extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
        child: Container(
      width: 106,
      height: 59,
      child: SvgPicture.asset(
        'assets/icons/Podium3rdRed.svg',
        semanticsLabel: 'Podium3',
      ),
    ));
  }
}
