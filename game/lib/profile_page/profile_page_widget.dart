import 'package:flutter/material.dart';
import 'package:game/profile_page/completed_cell.dart';
import 'package:game/profile_page/achievement_cell.dart';
import 'package:provider/provider.dart';

/**
 * This widget defines the leaderboard page. 
 */
class ProfilePageWidget extends StatefulWidget {
  const ProfilePageWidget({Key? key}) : super(key: key);

  @override
  _ProfilePageWidgetState createState() => _ProfilePageWidgetState();
}

/**
 * This widget is the mutable state of the user profile. It uses other widgets
 * such as achievement cells, completed cells, and profile header cells. 
 */
class _ProfilePageWidgetState extends State<ProfilePageWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  @override
  Widget build(BuildContext context) {
    var leaderboardStyle = TextStyle(
      color: Colors.white,
      fontFamily: 'Lato',
      fontSize: 24.0,
      fontWeight: FontWeight.w700,
      height: 29.0 / 24.0,
      letterSpacing: 0.0,
    );

    return Scaffold(
        key: scaffoldKey,
        backgroundColor: Color(0xFFF8F1),
        body: Padding(
          padding: const EdgeInsets.only(top: 0),
          child: Column(
            children: [
              //Title Container
              Container(
                height: 29.0,
                margin: EdgeInsets.only(top: 51.0, left: 25),
                child: Text(
                  "Leaderboard",
                  style: leaderboardStyle,
                ),
              ),
            ],
          ),
        ));
  }
}
