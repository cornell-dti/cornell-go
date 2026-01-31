import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_svg/flutter_svg.dart';

/**
 * Widget that represents each completed challenge 
 * @param name: Name of the achievement
 * @param pictures: Array of images corresponding to the challenge/location
 * @param type: Whether it is a journey or challenge
 * @param date: Date user achieved/completed the challenge
 * @param location: Location of the challenge
 * @param difficulty: Difficulty level of the specific challenge
 * @param points: Number of points associated with the challenge
 */

final locationVector = "assets/images/locationVector.png";

class CompletedChallengeFull extends StatefulWidget {
  final String name;
  final List<String> pictures;
  final String type;
  final String date;
  final String location;
  final String difficulty;
  final int adjustedPoints;
  final int originalPoints;

  CompletedChallengeFull({
    Key? key,
    required this.name,
    required this.pictures,
    required this.type,
    required this.date,
    required this.location,
    required this.difficulty,
    required this.adjustedPoints,
    required this.originalPoints,
  }) : super(key: key);

  @override
  _CompletedChallengeFullState createState() => _CompletedChallengeFullState();
}

class _CompletedChallengeFullState extends State<CompletedChallengeFull> {
  final GlobalKey<CarouselSliderState> _carouselKey = GlobalKey();
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 24.0,
        right: 24.0,
        top: 24.0,
        bottom: 5.0,
      ),
      child: Container(
        width: MediaQuery.sizeOf(context).width * 0.9,
        height: MediaQuery.sizeOf(context).height * 0.6,
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            CarouselSlider(
              key: _carouselKey,
              options: CarouselOptions(
                height: MediaQuery.sizeOf(context).height,
                aspectRatio: 16 / 9,
                viewportFraction: 1.0,
                initialPage: 0,
                enableInfiniteScroll: false,
                reverse: false,
                autoPlay: false,
                enlargeCenterPage: true,
                scrollDirection: Axis.horizontal,
                onPageChanged: (index, _) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
              ),
              items: widget.pictures.map((String picture) {
                return Builder(
                  builder: (BuildContext context) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        picture,
                        fit: BoxFit.cover,
                        width: 390,
                        height: 20,
                      ),
                    );
                  },
                );
              }).toList(),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // location type label
                  Container(
                    height: 31.58,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: ShapeDecoration(
                      color: Colors.white.withOpacity(0.7),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Image.asset(
                          locationVector,
                          alignment: Alignment.centerLeft,
                        ),
                        Padding(padding: EdgeInsets.symmetric(horizontal: 5)),
                        Text(
                          widget.location,
                          style: TextStyle(
                            color: Color(0xFF835A7C),
                            fontSize: 16,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w400,
                            height: 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Spacer(),
                  // carousel number tracker label thing
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 2, horizontal: 15),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_currentIndex + 1}/${widget.pictures.length}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 500,
                    height: 122,
                    color: Colors.white,
                    child: Padding(
                      padding: EdgeInsets.only(left: 16.0, top: 30.0),
                      child: Container(
                        width: 350,
                        height: 51,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.name,
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 20,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w800,
                                height: 0.07,
                              ),
                            ),
                            SizedBox(height: 25),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'From ' + widget.type,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.black.withOpacity(0.4),
                                    fontSize: 14,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w600,
                                    height: 0.11,
                                  ),
                                ),
                                SizedBox(width: 3),
                                Text(
                                  '—',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.black.withOpacity(0.4),
                                    fontSize: 14,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w600,
                                    height: 0.11,
                                  ),
                                ),
                                SizedBox(width: 3),
                                Text(
                                  widget.date,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.black.withOpacity(0.8),
                                    fontSize: 14,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w500,
                                    height: 0.11,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 20),
                            Row(
                              children: [
                                Container(
                                  width: 70,
                                  height: 29,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 2,
                                    vertical: 4,
                                  ),
                                  decoration: ShapeDecoration(
                                    color: Color(0xFFF9EDDA),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      widget.difficulty,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w400,
                                        height: 0,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Row(
                                  children: [
                                    SvgPicture.asset(
                                      "assets/icons/bearcoins.svg",
                                      width: 25,
                                    ),
                                    Text(
                                      ' ' +
                                          widget.adjustedPoints.toString() +
                                          "/" +
                                          widget.originalPoints.toString() +
                                          " PTS",
                                      style: TextStyle(
                                        fontSize: 16,
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
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
