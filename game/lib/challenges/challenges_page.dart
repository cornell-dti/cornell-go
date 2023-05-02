import 'package:flutter/material.dart';
import 'challenge_cell_new.dart';
import 'package:game/journeys/filter_form.dart';

import 'package:game/api/game_api.dart';
import 'package:game/model/challenge_model.dart';
import 'package:game/model/event_model.dart';
import 'package:game/model/group_model.dart';
import 'package:game/model/tracker_model.dart';
import 'package:game/api/game_client_dto.dart';

import 'package:game/widget/back_btn.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ChallengesPage extends StatefulWidget {
  const ChallengesPage({Key? key}) : super(key: key);

  @override
  State<ChallengesPage> createState() => _ChallengesPageState();
}

class _ChallengesPageState extends State<ChallengesPage> {
  final cells = [
    ChallengeCell("ARTS QUAD", "Statue on the Arts Quad",
        'https://picsum.photos/250?image=9', false),
    ChallengeCell("ARTS QUAD", "Statue on the Arts Quad",
        'https://picsum.photos/250?image=9', true),
    ChallengeCell("ARTS QUAD", "Statue on the Arts Quad",
        'https://picsum.photos/250?image=9', false),
    ChallengeCell("ARTS QUAD", "Statue on the Arts Quad",
        'https://picsum.photos/250?image=9', true),
  ];

  void openFilter() {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (
          BuildContext context,
        ) {
          return FilterForm();
        });
  }

  @override
  Widget build(BuildContext context) {
    final format = DateFormat('yyyy-MM-dd');
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(30),
        child: Column(
          children: [
            Container(
              height: 30,
              color: Color.fromARGB(51, 217, 217, 217),
              child: TextField(
                decoration: InputDecoration(
                  prefixIcon: Icon(
                    Icons.search,
                    color: Color.fromARGB(204, 0, 0, 0),
                    size: 12,
                  ),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(1.0))),
                  labelText: "Search a challenge name, location, etc...",
                  labelStyle: TextStyle(
                    color: Color.fromARGB(76, 0, 0, 0),
                    fontSize: 12,
                    fontFamily: 'Lato',
                  ),
                ),
              ),
            ),
            Container(
              child: Padding(
                padding: const EdgeInsets.only(top: 24.0, bottom: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      height: 30,
                      child: TextButton.icon(
                          onPressed: openFilter,
                          icon: Icon(
                            Icons.filter_list_rounded,
                            color: Color.fromARGB(255, 0, 0, 0),
                            size: 20.0,
                          ),
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all<Color>(
                                Color.fromARGB(153, 217, 217, 217)),
                            padding: MaterialStateProperty.all(
                              EdgeInsets.only(right: 16.0, left: 16.0),
                            ),
                            shape: MaterialStateProperty.all(
                                RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(3.0),
                            )),
                          ),
                          label: Text(
                            "Filter By",
                            style: TextStyle(
                              color: Color.fromARGB(255, 0, 0, 0),
                              fontSize: 15,
                              fontFamily: 'Inter',
                            ),
                          )),
                    ),
                  ],
                ),
              ),
            ),
            // Expanded(
            //   child: ListView.separated(
            //     padding: const EdgeInsets.all(0),
            //     itemCount: cells.length,
            //     itemBuilder: (context, index) {
            //       return cells[index];
            //     },
            //     separatorBuilder: (context, index) {
            //       return SizedBox(height: 10);
            //     },
            //   ),
            // ),
            Expanded(child: Consumer5<EventModel, ChallengeModel, TrackerModel,
                    GroupModel, ApiClient>(
                builder: (context, myEventModel, myChallengeModel,
                    myTrackerModel, groupModel, apiClient, child) {
              if (groupModel.curEventId == null) {
                return ListView();
              } else {
                List<Widget> challengeCells = [];
                final eventId = groupModel.curEventId!;
                final challenges =
                    myEventModel.getEventById(eventId)?.challengeIds;
                if (challenges == null) {
                  return ListView();
                } else {
                  for (String challengeId in challenges) {
                    final ChallengeDto? challenge =
                        myChallengeModel.getChallengeById(challengeId);
                    final EventDto? event = myEventModel.getEventById(eventId);
                    final EventTrackerDto? tracker =
                        myTrackerModel.trackerByEventId(eventId);
                    if (challenge != null && event != null && tracker != null) {
                      challengeCells.add(GestureDetector(
                        onTap: () {
                          apiClient.serverApi?.setCurrentChallenge(challengeId);
                        },
                        child: ChallengeCell(
                          "Arts Quad",
                          challenge.name,
                          challenge.imageUrl,
                          false,
                          // challenge.completionDate != null,
                        ),
                      ));
                    }
                  }
                }
                return ListView(
                    shrinkWrap: true,
                    scrollDirection: Axis.vertical,
                    children: challengeCells);
              }
            }))
          ],
        ),
      ),
    );
  }
}
