import 'package:flutter/material.dart';
import 'package:game/Widgets/back_btn.dart';

class VisitedPlacesWidget extends StatefulWidget {
  VisitedPlacesWidget({Key? key}) : super(key: key);

  @override
  _VisitedPlacesWidgetState createState() => _VisitedPlacesWidgetState();
}

class _VisitedPlacesWidgetState extends State<VisitedPlacesWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      floatingActionButton: backBtn(scaffoldKey, context, "Previouly visited"),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.only(top: 150),
        child: Container(
          child: Padding(
            padding: const EdgeInsets.only(left: 8.0, right: 8.0),
            child: Column(
              children: [
                Container(
                  child: Text("Search Bar")
                  ),
                Container(
                  child: ListView(
                    shrinkWrap: true,
                    scrollDirection: Axis.vertical,
                    children: [Text("Sage Chapel")])
                ),
              ],
                ),
            ),
          ),
        ),
      ),
    );
  }
}
