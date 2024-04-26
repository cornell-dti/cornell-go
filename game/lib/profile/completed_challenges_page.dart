import 'package:flutter/material.dart';
import 'package:game/api/game_client_dto.dart';
import 'package:game/model/challenge_model.dart';
import 'package:game/model/event_model.dart';
import 'package:game/model/tracker_model.dart';
import 'package:game/model/user_model.dart';
import 'package:game/profile/profile_page.dart';
import 'package:game/profile/completed_challenge_cell.dart';
import 'package:game/utils/utility_functions.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart';

/* The page view of all the completed challenges */

class CompletedChallengesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Color.fromARGB(255, 255, 248, 241),
        appBar: AppBar(
          backgroundColor: Color.fromARGB(255, 237, 86, 86),
          leading: IconButton(
            icon: const Icon(Icons.navigate_before),
            color: Colors.white,
            onPressed: () {
              Navigator.pop(
                context,
              );
            },
          ),
          title: const Text(
            'Completed',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [],
        ),
        body: Consumer4<UserModel, EventModel, TrackerModel, ChallengeModel>(
            builder: (context, userModel, eventModel, trackerModel,
                challengeModel, child) {
          if (userModel.userData == null) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          List<Tuple2<DateTime, EventDto>> completedEvents = [];

          //Get completed events
          for (var eventId in userModel.userData!.trackedEvents!) {
            var tracker = trackerModel.trackerByEventId(eventId);
            EventDto? event = eventModel.getEventById(eventId);
            if (tracker == null || event == null) {
              continue;
            }
            if (tracker.prevChallenges.length != event.challenges!.length) {
              continue;
            }

            try {
              // prevChallenges.last will throw StateError if prevChallenges
              // is empty, meaning the challenge was not completed properly
              var completedDate = tracker.prevChallenges.last.dateCompleted;
              DateTime date =
                  DateFormat("E, d MMM y HH:mm:ss").parse(completedDate);
              completedEvents.add(Tuple2<DateTime, EventDto>(date, event));
            } catch (e) {
              displayToast("Error with completing challenge", Status.error);
            }
          }
          //Sort so that the most recent events are first
          completedEvents.sort((a, b) => b.item1.compareTo(a.item1));
          final itemCount = completedEvents.length;
          return ListView.builder(
              itemBuilder: (context, index) {
                var event = completedEvents[index].item2;
                var date = completedEvents[index].item1;
                var type =
                    event.challenges!.length > 1 ? "Journeys" : "Challenge";

                var pictureList = <String>[];
                var locationList = [];
                var totalPoints = 0;
                for (var challengeId in event.challenges ?? []) {
                  var challenge = challengeModel.getChallengeById(challengeId);
                  if (challenge != null) {
                    pictureList.add(challenge.imageUrl!);
                    locationList.add(
                        friendlyLocation[challenge.location?.name ?? 'ANY']);
                    totalPoints += challenge.points ?? 0;
                  }
                }

                return CompletedChallengeFull(
                  name: event.name!,
                  pictures: pictureList,
                  type: type,
                  date: DateFormat("MMMM d, y").format(date),
                  location: locationList[0],
                  difficulty: friendlyDifficulty[event.difficulty]!,
                  points: totalPoints,
                );
              },
              itemCount: itemCount);
        }));
  }
}
