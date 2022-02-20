import 'package:flutter/material.dart';
import 'package:game/Widgets/back_btn.dart';
import 'package:game/Widgets/leaderboard_cell.dart';

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
            child: ListView(
              shrinkWrap: true,
              scrollDirection: Axis.vertical,
              children: [
                leaderBoardCell(context, "User", "1", "23", true),
                leaderBoardCell(context, "User 2", "2", "20", false),
                leaderBoardCell(context, "User 3", "3", "19", false),
                leaderBoardCell(context, "User 4", "4", "19", false),
                leaderBoardCell(context, "User 5", "5", "19", false),
                leaderBoardCell(context, "User 6", "6", "19", false),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
