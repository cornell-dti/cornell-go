import 'package:flutter/material.dart';
import 'package:game/utils/utility_functions.dart';
import 'package:google_fonts/google_fonts.dart';

class UserNameWidget extends StatefulWidget {
  UserNameWidget({Key? key}) : super(key: key);

  @override
  _UserNameWidget createState() => _UserNameWidget();
}

class _UserNameWidget extends State<UserNameWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final userNameController = new TextEditingController();
  Color Carnelian = Color(0xFFB31B1B);
  Color bgColor = Color.fromRGBO(0, 0, 0, 1.0);
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: scaffoldKey,
        backgroundColor: bgColor,
        floatingActionButton: FloatingActionButton(
            elevation: 8.0,
            child: Icon(Icons.check),
            backgroundColor: Carnelian,
            onPressed: () {
              final validCharacters = RegExp(r'^[a-zA-Z0-9_]+$');
              var userName = userNameController.text;
              if (userName == "") {
                showAlert("You can't have an empty username!", context);
              } else if (!validCharacters.hasMatch(userName)) {
                showAlert(
                    "Your username can only have letters, numbers, and underscores",
                    context);
              } else if (userName.length > 64) {
                showAlert("Username can't be more than 64 characters", context);
              } else {
                var hashCode = userName.hashCode;
                while (numDigs(hashCode) != 9) {
                  if (numDigs(hashCode) < 9) {
                    hashCode *= 10;
                  } else {
                    hashCode = hashCode ~/ 10;
                  }
                }
                List<int> vals = [];
                for (var i = 0; i < 3; i++) {
                  vals.add(((hashCode % 1000) / 1000 * 255).round());
                  hashCode = hashCode ~/ 1000;
                }
                setState(() {
                  bgColor = Color.fromRGBO(vals[2], vals[1], vals[0], 1.0);
                });
              }
            }),
        body: Center(
          child: Container(child: _userNameInputWidget()),
        ));
  }

  Widget _userNameInputWidget() {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
          child: Image.asset('assets/images/logo_hires.png'),
          width: 200,
          height: 200),
      Text("Change your username here!",
          style: GoogleFonts.lato(
              textStyle: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18))),
      Padding(
          padding: const EdgeInsets.only(top: 16.0, left: 12.0, right: 12.0),
          child: Container(
            width: 225,
            height: 50,
            child: TextField(
              controller: userNameController,
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
