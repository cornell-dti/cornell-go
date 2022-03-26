import 'package:flutter/material.dart';
import 'package:game/api/game_client_dto.dart';
import 'package:game/model/event_model.dart';
import 'package:game/model/group_model.dart';
import 'package:game/model/user_model.dart';
import 'package:game/widget/back_btn.dart';
import 'package:game/widget/leaderboard_cell.dart';
import 'package:game/widget/leaderboard_user_cell.dart';
import 'package:provider/provider.dart';
import 'dart:math';

class LeaderboardWidget extends StatefulWidget {
  LeaderboardWidget({Key? key}) : super(key: key);

  @override
  _LeaderboardWidgetState createState() => _LeaderboardWidgetState();
}

class _LeaderboardWidgetState extends State<LeaderboardWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      floatingActionButton: backBtn(scaffoldKey, context, "Leaderboard"),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.only(top: 150),
        child: Container(
          child: Padding(
            padding: const EdgeInsets.only(left: 8.0, right: 8.0),
            child: Consumer3<GroupModel, EventModel, UserModel>(
              builder: (context, myGroupModel, myEventModel, myUserModel, child) {
                int position = 1;
                if (myGroupModel.curEventId == null) return ListView();
                final List<UpdateLeaderDataUserDto> list = myEventModel
                    .getTopPlayersForEvent(myGroupModel.curEventId!, 1000);
                return ListView(
                  shrinkWrap: true,
                  scrollDirection: Axis.vertical,
                  children: [
                    for (int i = 0; i < list.length; i++)
                      if (myUserModel.userData?.id != null && myUserModel.userData!.id == list.elementAt(i))
                        leaderBoardUserCell(context, list.elementAt(i).username, i+1, myGroupModel.members.length, list.elementAt(i).score), 
                    for (UpdateLeaderDataUserDto user in list)
                      leaderBoardCell(context, user.username, position++, user.score, true)
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
