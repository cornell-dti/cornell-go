import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UserNameWidget extends StatefulWidget {
  UserNameWidget({Key? key}) : super(key: key);

  @override
  _UserNameWidget createState() => _UserNameWidget();
}

class _UserNameWidget extends State<UserNameWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  var step = 1;
  Color Carnelian = Color(0xFFB31B1B);

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: scaffoldKey,
        backgroundColor: Colors.black,
        body: Center(
          child: Container(
              child: step == 1 ? _initWidget() : _userNameInputWidget()),
        ));
  }

  Widget _initWidget() {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text("Hi 👋🏻",
          style: GoogleFonts.lato(
              textStyle: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 25))),
      Text("Looks like you're new here",
          style: GoogleFonts.lato(
              textStyle: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20))),
      Padding(
        padding: const EdgeInsets.all(12.0),
        child: ElevatedButton(
          onPressed: () => {step += 1, print(step)},
          child: Icon(Icons.arrow_right_alt_rounded, color: Colors.white),
          style: TextButton.styleFrom(
              backgroundColor: Carnelian,
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)))),
        ),
      )
    ]);
  }

  Widget _userNameInputWidget() {
    return Text(
      'hi',
      style: TextStyle(color: Colors.white),
    );
  }
}
