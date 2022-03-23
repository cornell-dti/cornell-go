import 'package:flutter/material.dart';
import 'package:game/widget/back_btn.dart';

class UserNameWidget extends StatefulWidget {
  UserNameWidget({Key? key}) : super(key: key);

  @override
  _UserNameWidget createState() => _UserNameWidget();
}

class _UserNameWidget extends State<UserNameWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: scaffoldKey,
        floatingActionButton:
            backBtn(scaffoldKey, context, "Choose username.dart"),
        backgroundColor: Color(0xFFDBE2E7),
        body: Center(child: Text("TODO")));
  }
}
