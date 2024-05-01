import 'package:flutter/material.dart';
import 'package:game/gameplay/gameplay_page.dart';
import 'package:game/navigation_page/bottom_navbar.dart';
import 'package:game/progress_indicators/circular_progress_indicator.dart';

// for backend connection
import 'package:provider/provider.dart';
import 'package:game/api/game_client_dto.dart';
import 'package:game/api/game_api.dart';
import 'package:game/model/event_model.dart';
import 'package:game/model/tracker_model.dart';
import 'package:game/model/group_model.dart';
import 'package:game/model/challenge_model.dart';

import 'package:flutter_svg/flutter_svg.dart';

class ChallengeCompletedPage extends StatefulWidget {
  const ChallengeCompletedPage({
    Key? key,
  }) : super(key: key);

  @override
  State<ChallengeCompletedPage> createState() => _ChallengeCompletedState();
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
          child: Stack(children: [
            Container(
              width: MediaQuery.sizeOf(context).width * 0.66,
              height: 24,
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: new BoxDecoration(
                  color: Color.fromARGB(255, 241, 241, 241),
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.all(Radius.circular(16.0)),
                ),
              ),
            ),
            Container(
              width:
                  (progress + 0.05) * MediaQuery.sizeOf(context).width * 0.66,
              height: 24,
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: new BoxDecoration(
                  color: Color(0xE6ED5656),
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.all(Radius.circular(16.0)),
                ),
              ),
            ),
          ])
          // child: Container(
          //   clipBehavior: Clip.hardEdge,
          //   decoration: BoxDecoration(
          //     borderRadius: BorderRadius.circular(15.0),
          //   ),
          //   height: 20.0,
          //   width: double.infinity,
          //   child: Stack(
          //     alignment: Alignment.centerLeft,
          //     children: [
          //       Positioned.fill(
          //         child: LinearProgressIndicator(
          //             value: progress,
          //             color: Color(0xE6ED5656),
          //             backgroundColor: Color(0xFFF1F1F1)),
          //       ),
          //     ],
          //   ),
          // ),
          ),
      Expanded(
          flex: 2,
          child: Row(children: [
            Text(" "),
            SvgPicture.asset("assets/icons/pin.svg"),
            Text(
              num_completed.toString() + "/" + num_challenges.toString(),
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

class _ChallengeCompletedState extends State<ChallengeCompletedPage> {
  bool journeyPage = false;
  bool journeyCompleted = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final int hintsDeduction = 25;

    return Consumer5<ChallengeModel, EventModel, TrackerModel, ApiClient,
            GroupModel>(
        builder: (context, challengeModel, eventModel, trackerModel, apiClient,
            groupModel, _) {
      var eventId = groupModel.curEventId;
      var event = eventModel.getEventById(eventId ?? "");
      var tracker = trackerModel.trackerByEventId(eventId ?? "");
      if (tracker == null) {
        return CircularIndicator();
      }

      // if this event is a journey
      if ((event?.challenges?.length ?? 0) > 1)
        // determine whether the journey is done
        journeyCompleted =
            tracker.prevChallenges.length == (event?.challenges?.length ?? 0);

      var challenge = challengeModel
          .getChallengeById(tracker.prevChallenges.last.challengeId);

      if (challenge == null) {
        return Scaffold(
          body: Text("No challenge data"),
        );
      }

      // build list of completed challenge text fields to display later
      var total_pts = 0;
      List<Widget> completedChallenges = [];
      for (PrevChallengeDto prevChal in tracker.prevChallenges) {
        var completedChal =
            challengeModel.getChallengeById(prevChal.challengeId);
        if (completedChal == null) continue;
        var pts =
            (completedChal.points ?? 0) - (prevChal.hintsUsed * hintsDeduction);
        total_pts += pts;

        completedChallenges.add(Container(
            margin: EdgeInsets.only(left: 30, bottom: 10, right: 30),
            child: Row(
              children: [
                SvgPicture.asset(
                  'assets/icons/locationCompleted.svg',
                  fit: BoxFit.cover,
                ),
                Text(
                  "   " + (completedChal.name ?? ""),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                Text(
                  "+ " + pts.toString() + " points",
                  style: TextStyle(color: Colors.white, fontSize: 16.0),
                ),
              ],
            )));
      }

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
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    journeyPage
                        ? (journeyCompleted
                            ? "Journey Complete"
                            : "Journey in Progress!")
                        : 'Challenge Complete!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.only(bottom: 15),
                  child: Text(
                    challenge.description ?? "NO DESCRIPTION",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (journeyPage)
                  Container(
                      padding: EdgeInsets.only(left: 30, bottom: 10),
                      alignment: Alignment.centerLeft,
                      child: LoadingBar(tracker.prevChallenges.length,
                          event?.challenges?.length ?? 0)),
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
                if (!journeyPage) ...[
                  Container(
                      margin: EdgeInsets.only(left: 30, bottom: 10, right: 30),
                      child: Row(
                        children: [
                          SvgPicture.asset(
                            'assets/icons/locationCompleted.svg',
                            fit: BoxFit.cover,
                          ),
                          Text(
                            "   Found Location",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Spacer(),
                          Text(
                            "+ " +
                                (challenge.points ?? 0).toString() +
                                " points",
                            style:
                                TextStyle(color: Colors.white, fontSize: 16.0),
                          ),
                        ],
                      )),
                  if (tracker.prevChallenges.last.hintsUsed > 0)
                    Container(
                        margin:
                            EdgeInsets.only(left: 30, bottom: 10, right: 30),
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
                              "- " + hintsDeduction.toString() + " points",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16.0,
                              ),
                            ),
                          ],
                        )),
                  if (tracker.prevChallenges.last.hintsUsed > 1)
                    Container(
                        margin:
                            EdgeInsets.only(left: 30, bottom: 10, right: 30),
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
                              "- " + hintsDeduction.toString() + " points",
                              style: TextStyle(
                                  color: Colors.white, fontSize: 16.0),
                            ),
                          ],
                        )),
                  if ((tracker.prevChallenges.last.hintsUsed) > 2)
                    Container(
                        margin:
                            EdgeInsets.only(left: 30, bottom: 10, right: 30),
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
                              "- " + hintsDeduction.toString() + " points",
                              style: TextStyle(
                                  color: Colors.white, fontSize: 16.0),
                            ),
                          ],
                        )),
                ] else
                  Container(
                      height: MediaQuery.sizeOf(context).height * 0.15,
                      child: ListView(
                          padding: EdgeInsets.zero,
                          children: completedChallenges)),
                SizedBox(height: 10),
                Text(
                  journeyPage
                      ? "Total Points: " + total_pts.toString()
                      : "Points Earned: " +
                          ((challenge.points ?? 0) -
                                  (tracker.prevChallenges.last.hintsUsed) *
                                      hintsDeduction)
                              .toString(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 25.0,
                    fontWeight: FontWeight.bold,
                  ),
                )
              ],
            )),
        journeyPage
            ? Container(
                alignment: Alignment.bottomCenter,
                margin: EdgeInsets.all(40),
                child: journeyCompleted
                    ? ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromARGB(255, 237, 86, 86),
                          padding: EdgeInsets.only(
                              right: 15, left: 15, top: 10, bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(10), // button's shape,
                          ),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text(
                            "Return Home ",
                            style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 21,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFFFFFFFF)),
                          ),
                          SvgPicture.asset("assets/icons/forwardcarrot.svg")
                        ]),
                        onPressed: () {
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => BottomNavBar()));
                        },
                      )
                    : Row(
                        children: [
                          ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Color.fromARGB(0, 255, 255, 255),
                                shadowColor: Color.fromARGB(0, 255, 255, 255),
                                padding: EdgeInsets.only(
                                    right: 15, left: 15, top: 10, bottom: 10),
                                shape: RoundedRectangleBorder(
                                  side: BorderSide(color: Colors.white),
                                  borderRadius: BorderRadius.circular(
                                      10), // button's shape,
                                ),
                              ),
                              onPressed: () => Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => BottomNavBar())),
                              child: Text(
                                "Leave",
                                style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 20,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xFFFFFFFF)),
                              )),
                          Spacer(),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color.fromARGB(255, 237, 86, 86),
                              padding: EdgeInsets.only(
                                  right: 15, left: 15, top: 10, bottom: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    10), // button's shape,
                              ),
                            ),
                            onPressed: () => Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => GameplayPage())),
                            child:
                                Row(mainAxisSize: MainAxisSize.min, children: [
                              Text(
                                "Next Challenge ",
                                style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 20,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xFFFFFFFF)),
                              ),
                              SvgPicture.asset("assets/icons/forwardcarrot.svg")
                            ]),
                          ),
                        ],
                      ),
              )
            : Container(
                alignment: Alignment.bottomCenter,
                margin: EdgeInsets.only(bottom: 40),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 237, 86, 86),
                    padding: EdgeInsets.only(
                        right: 15, left: 15, top: 10, bottom: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(10), // button's shape,
                    ),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(
                      ((event?.challenges?.length ?? 0) > 1)
                          ? "Journey Progress "
                          : "Return Home ",
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 21,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFFFFFFFF)),
                    ),
                    SvgPicture.asset("assets/icons/forwardcarrot.svg")
                  ]),
                  onPressed: () {
                    if ((event?.challenges?.length ?? 0) > 1) {
                      journeyPage = true;
                      setState(() {});
                    } else {
                      Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => BottomNavBar()));
                    }
                  },
                ),
              ),
      ]));
    });
  }
}
