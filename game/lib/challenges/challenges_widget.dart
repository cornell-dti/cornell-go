import 'package:flutter/material.dart';
import 'package:game/model/challenge_model.dart';
import 'package:game/model/event_model.dart';
import 'package:game/model/tracker_model.dart';
import 'package:game/model/user_model.dart';
import 'package:game/api/game_client_dto.dart';

import 'package:game/widget/back_btn.dart';
import 'package:game/widget/challenge_cell.dart';
import 'package:provider/provider.dart';

class ChallengesWidget extends StatefulWidget {
  ChallengesWidget({Key? key}) : super(key: key);

  @override
  _ChallengesWidgetState createState() => _ChallengesWidgetState();
}

class _ChallengesWidgetState extends State<ChallengesWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      floatingActionButton: backBtn(scaffoldKey, context, "Challenges"),
      backgroundColor: Color.fromARGB(255, 43, 47, 50),
      body: Padding(
        padding: const EdgeInsets.only(top: 150),
        child: Container(
          child: Padding(
            padding: const EdgeInsets.only(left: 8.0, right: 8.0),
            child: Column(
              children: [
                Expanded(child: Consumer4<UserModel, EventModel, ChallengeModel,
                        TrackerModel>(
                    builder: (context, myUserModel, myEventModel,
                        myChallengeModel, myTrackerModel, child) {
                  if (myUserModel.userData == null) {
                    return ListView();
                  } else {
                    List<Widget> challengeCells = [];
                    final events = myUserModel.userData!.trackedEventIds;
                    for (String eventId in events) {
                      final challenges =
                          myEventModel.getEventById(eventId)!.challengeIds;
                      for (String challengeId in challenges) {
                        final UpdateChallengeDataChallengeDto challenge =
                            myChallengeModel.getChallengeById(challengeId)!;
                        final UpdateEventDataEventDto event =
                            myEventModel.getEventById(eventId)!;
                        final UpdateEventTrackerDataEventTrackerDto tracker =
                            myTrackerModel.trackerByEventId(eventId)!;
                        challengeCells.add(challengeCell(
                            context,
                            challenge.name,
                            challenge.completionDate,
                            challenge.imageUrl,
                            tracker.curChallengeId == challengeId,
                            !tracker.prevChallengeIds.contains(challengeId),
                            event.skippingEnabled));
                      }
                    }
                    return ListView(
                        shrinkWrap: true,
                        scrollDirection: Axis.vertical,
                        children: challengeCells);
                  }
                }))
                // Expanded(
                //     child: ListView(
                //         shrinkWrap: true,
                //         scrollDirection: Axis.vertical,
                //         children: [
                //       challengeCell(context, "Sage Chapel", "4/19/2021", 5,
                //           "assets/images/38582.jpg", false, false, false),
                //       challengeCell(context, "Sage Chapel", "4/19/2021", 5,
                //           "assets/images/38582.jpg", true, true, false),
                //       challengeCell(context, "Sage Chapel", "4/19/2021", 5,
                //           "assets/images/38582.jpg", false, true, false),
                //       challengeCell(context, "Sage Chapel", "4/19/2021", 5,
                //           "assets/images/38582.jpg", false, true, true),
                //     ]))
              ],
            ),
          ),
        ),
      ),
    );
  }
}
