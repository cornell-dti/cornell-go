import 'package:flutter/material.dart';
import 'package:game/api/game_client_dto.dart';
import 'package:game/model/event_model.dart';
import 'package:game/model/group_model.dart';
import 'package:game/model/user_model.dart';
import 'package:game/widget/back_btn.dart';
import 'package:game/widget/leaderboard_cell.dart';
import 'package:game/widget/leaderboard_user_cell.dart';
import 'package:provider/provider.dart';

class EventsLeaderboardWidget extends StatefulWidget {
  EventsLeaderboardWidget({Key? key}) : super(key: key);

  @override
  _EventsLeaderboardWidgetState createState() => _EventsLeaderboardWidgetState();
}

class _EventsLeaderboardWidgetState extends State<EventsLeaderboardWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      floatingActionButton: backBtn(scaffoldKey, context, "Events Leaderboard"),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.only(top: 150),
        child: Container(
          child: Padding(
            padding: const EdgeInsets.only(left: 8.0, right: 8.0),
            child: Consumer3<GroupModel, EventModel, UserModel>(
              builder:
                  (context, myGroupModel, myEventModel, myUserModel, child) {
                int position = 1;
                if (myGroupModel.curEventId == null) return ListView();
                final List<UpdateLeaderDataUserDto> list = myEventModel
                    .getTopPlayersForEvent(myGroupModel.curEventId!, 1000);
                return Column(children: [
                  for (int i = 0; i < list.length; i++)
                    if (myUserModel.userData?.id != null &&
                        myUserModel.userData!.id == list.elementAt(i).userId)
                      leaderBoardUserCell(context, list.elementAt(i).username,
                          i + 1, list.length, list.elementAt(i).score),
                  Expanded(
                      child: ListView(
                    shrinkWrap: true,
                    scrollDirection: Axis.vertical,
                    children: [
                      for (UpdateLeaderDataUserDto user in list)
                        leaderBoardCell(context, user.username, position++,
                            user.score, user.userId == myUserModel.userData?.id)
                    ],
                  ))
                ]);
              },
            ),
          ),
        ),
      ),
    );
  }
}
