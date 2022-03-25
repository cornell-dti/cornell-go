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
        floatingActionButton: FloatingActionButton(
            elevation: 8.0,
            child: Icon(Icons.check),
            backgroundColor: Carnelian,
            onPressed: () {
              print('pressed');
            }),
        body: Center(
          child: Container(child: _userNameInputWidget()),
        ));
  }

  Widget _userNameInputWidget() {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text("Change your username here!",
          style: GoogleFonts.lato(
              textStyle: TextStyle(
                  color: Carnelian,
                  fontWeight: FontWeight.bold,
                  fontSize: 18))),
      Padding(
          padding: const EdgeInsets.only(top: 16.0, left: 12.0, right: 12.0),
          child: Container(
            width: 225,
            height: 50,
            child: TextField(
              style: GoogleFonts.lato(
                  textStyle: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.normal,
                      fontSize: 16)),
              cursorColor: Carnelian,
              decoration: new InputDecoration(
                  focusColor: Colors.white,
                  fillColor: Colors.white,
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white, width: 2.0),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Carnelian, width: 2.0),
                  ),
                  hintText: 'Username',
                  hintStyle: GoogleFonts.lato(
                      textStyle: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.normal,
                          fontSize: 16))),
            ),
          )),
    ]);
  }
}
