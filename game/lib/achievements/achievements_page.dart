import 'package:flutter/cupertino.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:game/achievements/achievement_cell.dart';
import 'package:game/api/game_api.dart';
import 'package:game/api/game_client_dto.dart';
import 'package:game/model/challenge_model.dart';
import 'package:game/model/event_model.dart';
import 'package:game/model/group_model.dart';
import 'package:game/model/tracker_model.dart';
import 'package:game/model/user_model.dart';
import 'package:provider/provider.dart';
import 'package:game/journeys/filter_form.dart';

class AchievementsPage extends StatefulWidget {
  const AchievementsPage({super.key});

  @override
  State<AchievementsPage> createState() => _AchievementsPageState();
}

class _AchievementsPageState extends State<AchievementsPage> {
  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
          color: Color(0xFFED5656),
        ),
        child: SafeArea(
            bottom: false,
            child: Scaffold(
              appBar: AppBar(
                title: const Text('Achievements'),
              ),
              body: Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: Color.fromARGB(255, 255, 248, 241),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(30),
                    child: Column(
                      children: [
                        Expanded(child: Consumer4<EventModel, GroupModel,
                                TrackerModel, ChallengeModel>(
                            builder: (context, myEventModel, groupModel,
                                trackerModel, challengeModel, child) {
                          List<Widget> eventCells = [];
                          if (myEventModel.searchResults == null) {
                            myEventModel.searchEvents(
                                0,
                                1000,
                                [
                                  EventTimeLimitationDto.PERPETUAL,
                                  EventTimeLimitationDto.LIMITED_TIME
                                ],
                                false,
                                false,
                                false);
                          }
                          final events = myEventModel.searchResults ?? [];
                          if (!events.any((element) =>
                              element.id == groupModel.curEventId)) {
                            final curEvent = myEventModel
                                .getEventById(groupModel.curEventId ?? "");
                            if (curEvent != null) events.add(curEvent);
                          }
                          for (EventDto event in events) {
                            print(event);
                            var tracker =
                                trackerModel.trackerByEventId(event.id);
                            var numberCompleted =
                                tracker?.prevChallenges?.length ?? 0;
                            var complete =
                                (numberCompleted == event.challenges?.length);
                            var locationCount = event.challenges?.length ?? 0;
                            DateTime now = DateTime.now();
                            DateTime endtime =
                                HttpDate.parse(event.endTime ?? "");

                            Duration timeTillExpire = endtime.difference(now);
                            if (locationCount != 1) continue;
                            var challenge = challengeModel
                                .getChallengeById(event.challenges?[0] ?? "");

                            if (challenge == null) continue;
                            if (!complete)
                              eventCells.add(
                                StreamBuilder(
                                  stream: Stream.fromFuture(
                                      Future.delayed(timeTillExpire)),
                                  builder: (stream, value) => timeTillExpire
                                          .isNegative
                                      ? Consumer<ApiClient>(
                                          builder: (context, apiClient, child) {
                                            if (event.id ==
                                                groupModel.curEventId) {
                                              apiClient.serverApi
                                                  ?.setCurrentEvent(
                                                      SetCurrentEventDto(
                                                          eventId: ""));
                                            }
                                            return Container();
                                          },
                                        )
                                      : AchievementCell(
                                          key: UniqueKey(),
                                          challenge.location?.name ?? "",
                                          challenge.name ?? "",
                                          Image.network(
                                              "https://picsum.photos/250?image=9"),
                                          complete,
                                          challenge.description ?? "",
                                          event.difficulty?.name ?? "",
                                          challenge.points ?? 0,
                                          event.id),
                                ),
                              );
                          }
                          return ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            itemCount: eventCells.length + 1,
                            itemBuilder: (context, index) {
                              if (index == eventCells.length) {
                                // Footer widget
                                return Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 50.0),
                                    child: Center(
                                      child: Image(
                                        image: AssetImage(
                                            'assets/images/go-logo.png'),
                                        width: 200,
                                        height: 200,
                                      ),
                                    ));
                              }
                              return eventCells[index];
                            },
                            physics: BouncingScrollPhysics(),
                            separatorBuilder: (context, index) {
                              return SizedBox(height: 10);
                            },
                          );
                        }))
                      ],
                    ),
                  )),
            )));
  }
}
