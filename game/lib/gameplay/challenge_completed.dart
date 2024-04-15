import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:game/api/geopoint.dart';
import 'package:flutter/cupertino.dart';

import 'package:flutter_svg/flutter_svg.dart';

class ChallengeCompleted extends StatefulWidget {
  final String description;
  final int points;
  final int numHintsLeft;

  const ChallengeCompleted(
      {Key? key,
      required this.description,
      required this.points,
      required this.numHintsLeft})
      : super(key: key);

  @override
  State<ChallengeCompleted> createState() => _ChallengeCompletedState();
}

class LoadingBar extends StatelessWidget {
  final int num_challenges;
  final int num_completed;

  const LoadingBar(
    this.num_completed,
    this.num_challenges,
  );

  @override
  Widget build(BuildContext context) {
    double progress = num_completed / num_challenges;
    return Row(mainAxisSize: MainAxisSize.max, children: [
      Expanded(
        flex: 8,
        child: Container(
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15.0),
          ),
          height: 20.0,
          width: double.infinity,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Positioned.fill(
                child: LinearProgressIndicator(
                    value: progress,
                    color: Color(0xE6ED5656),
                    backgroundColor: Color(0xFFF1F1F1)),
              ),
            ],
          ),
        ),
      ),
      Expanded(
          flex: 2,
          child: Row(children: [
            Text(" "),
            SvgPicture.asset("assets/icons/pin.svg"),
            Text(
              " 1/3",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
              ),
            )
          ]))
    ]);
  }
}

class _ChallengeCompletedState extends State<ChallengeCompleted> {
  bool journey = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(children: [
      Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: SvgPicture.asset(
            'assets/images/challenge-completed-bg.svg', // Replace with your SVG file path
            fit: BoxFit.cover,
          )),
      Container(
          margin: EdgeInsets.only(
              top: MediaQuery.of(context).size.height * 0.47,
              left: 20,
              right: 20),
          height: MediaQuery.of(context).size.height * 0.53,
          child: Column(children: [
            Container(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                journey ? "Journey in Progress!" : 'Challenge Complete!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.only(bottom: 15),
              child: Text(
                'You’ve found the Statue on the Arts Quad!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18.0,
                ),
              ),
            ),
            if (journey)
              Container(
                  padding: EdgeInsets.only(left: 30, bottom: 10),
                  alignment: Alignment.centerLeft,
                  child: LoadingBar(1, 3)),
            Container(
              padding: EdgeInsets.only(left: 30, bottom: 10),
              alignment: Alignment.centerLeft,
              child: Text(
                'Points',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (!journey) ...[
              Container(
                  margin: EdgeInsets.only(left: 30, bottom: 10, right: 30),
                  child: Row(
                    children: [
                      SvgPicture.asset(
                        'assets/icons/locationCompleted.svg', // Replace with your SVG file path
                        fit: BoxFit.cover,
                      ),
                      Text(
                        "   Location Found",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Spacer(),
                      Text(
                        "+ 100 points",
                        style: TextStyle(color: Colors.white, fontSize: 16.0),
                      ),
                    ],
                  )),
              if (widget.numHintsLeft < 3)
                Container(
                    margin: EdgeInsets.only(left: 30, bottom: 10, right: 30),
                    child: Row(
                      children: [
                        SvgPicture.asset(
                          'assets/icons/hint.svg', // Replace with your SVG file path
                          fit: BoxFit.cover,
                        ),
                        Text(
                          "   Used 1st Hint",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Spacer(),
                        Text(
                          "- 25 points",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.0,
                          ),
                        ),
                      ],
                    )),
              if (widget.numHintsLeft < 2)
                Container(
                    margin: EdgeInsets.only(left: 30, bottom: 10, right: 30),
                    child: Row(
                      children: [
                        SvgPicture.asset(
                          'assets/icons/hint.svg', // Replace with your SVG file path
                          fit: BoxFit.cover,
                        ),
                        Text(
                          "   Used 2nd Hint",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Spacer(),
                        Text(
                          "- 25 points",
                          style: TextStyle(color: Colors.white, fontSize: 16.0),
                        ),
                      ],
                    )),
              if (widget.numHintsLeft < 1)
                Container(
                    margin: EdgeInsets.only(left: 30, bottom: 10, right: 30),
                    child: Row(
                      children: [
                        SvgPicture.asset(
                          'assets/icons/hint.svg', // Replace with your SVG file path
                          fit: BoxFit.cover,
                        ),
                        Text(
                          "   Used 3rd Hint",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Spacer(),
                        Text(
                          "- 25 points",
                          style: TextStyle(color: Colors.white, fontSize: 16.0),
                        ),
                      ],
                    )),
              Spacer(),
            ] else ...[
              Container(
                  margin: EdgeInsets.only(left: 30, bottom: 10, right: 30),
                  child: Row(
                    children: [
                      SvgPicture.asset(
                        'assets/icons/locationCompleted.svg', // Replace with your SVG file path
                        fit: BoxFit.cover,
                      ),
                      Text(
                        "   Challenge 1",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Spacer(),
                      Text(
                        "+ 100 points",
                        style: TextStyle(color: Colors.white, fontSize: 16.0),
                      ),
                    ],
                  )),
              Container(
                  margin: EdgeInsets.only(left: 30, bottom: 10, right: 30),
                  child: Row(
                    children: [
                      SvgPicture.asset(
                        'assets/icons/locationCompleted.svg', // Replace with your SVG file path
                        fit: BoxFit.cover,
                      ),
                      Text(
                        "   Challenge 2",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Spacer(),
                      Text(
                        "+ 100 points",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.0,
                        ),
                      ),
                    ],
                  )),
            ]
          ])),
      Container(
          alignment: Alignment.bottomCenter,
          margin: EdgeInsets.only(bottom: 130),
          child: Text(
            "Total Points: " +
                (widget.points - 25 * (3 - widget.numHintsLeft)).toString(),
            style: TextStyle(
              color: Colors.white,
              fontSize: 25.0,
              fontWeight: FontWeight.bold,
            ),
          )),
      Container(
        alignment: Alignment.bottomCenter,
        margin: EdgeInsets.only(bottom: 70),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color.fromARGB(255, 237, 86, 86),
            padding: EdgeInsets.only(right: 15, left: 15, top: 10, bottom: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10), // button's shape,
            ),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(
              "Journey Progress ",
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 21,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFFFFFFFF)),
            ),
            SvgPicture.asset("assets/icons/forwardcarrot.svg")
          ]),
          onPressed: () {
            journey = true;
            setState(() {});
          },
        ),
      ),
    ]));
  }
}
