import 'package:flutter/material.dart';
import 'package:game/Widgets/back_btn.dart';

class FeedbackWidget extends StatefulWidget {
  FeedbackWidget({Key? key}) : super(key: key);

  @override
  _LeaderboardWidgetState createState() => _LeaderboardWidgetState();
}

class _LeaderboardWidgetState extends State<FeedbackWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: scaffoldKey,
        floatingActionButton: backBtn(scaffoldKey, context, "Feedback"),
        backgroundColor: Color(0xFFDBE2E7),
        body: Center(child: Text("TODO")));
  }
}
