import 'package:flutter/material.dart';
import 'package:game/widget/back_btn.dart';

class SuggestionsWidget extends StatefulWidget {
  SuggestionsWidget({Key? key}) : super(key: key);

  @override
  _VisitedPlacesWidgetState createState() => _VisitedPlacesWidgetState();
}

class _VisitedPlacesWidgetState extends State<SuggestionsWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      floatingActionButton: backBtn(scaffoldKey, context, "Suggestions"),
      backgroundColor: Color(0xFFDBE2E7),
      body: Center(child: Text("TODO")),
    );
  }
}
