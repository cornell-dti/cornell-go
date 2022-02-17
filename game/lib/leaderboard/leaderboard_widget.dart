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
      floatingActionButton: backBtn(scaffoldKey, context),
      floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.only(top: 150),
        child: Container(
          child: ListView(
            shrinkWrap: true,
            scrollDirection: Axis.vertical,
            children: [
              leaderBoardCell(context, "Nirbhay", "1", "23", true),
              leaderBoardCell(context, "Nirbhay 2", "2", "20", false),
              leaderBoardCell(context, "Nirbhay 3", "3", "19", false)
            ],
          ),
        ),
      ),
    );
  }
}
