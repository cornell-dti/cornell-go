import 'package:flutter/material.dart';
import 'package:game/api/game_client_dto.dart';
import 'package:game/details_page/details_page.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// If the google-login or apple-login user is not registered, this page will be displayed.
/// The user will be asked to select their enrollment type. The user is created
/// only when they fill all required information (at registerpage -> details_page
/// -> interests_page).
class RegisterPageWidget extends StatefulWidget {
  final GoogleSignInAccount? googleUser;
  final AuthorizationCredentialAppleID? appleUser;
  final String? idToken;
  RegisterPageWidget(
      {Key? key,
      GoogleSignInAccount? this.googleUser,
      AuthorizationCredentialAppleID? this.appleUser,
      required String? this.idToken})
      : super(key: key);
  final scaffoldKey = GlobalKey<ScaffoldState>();
  @override
  _RegisterPageWidgetState createState() => _RegisterPageWidgetState();
}

class _RegisterPageWidgetState extends State<RegisterPageWidget> {
  String _selectedOption = "";
  @override
  void initState() {
    super.initState();
  }

  Map<String, LoginEnrollmentTypeDto> entryToEnrollmentType = {
    "Undergraduate Student": LoginEnrollmentTypeDto.UNDERGRADUATE,
    "Graduate Student": LoginEnrollmentTypeDto.GRADUATE,
    "Faculty/Staff": LoginEnrollmentTypeDto.FACULTY,
    "Alumni": LoginEnrollmentTypeDto.ALUMNI
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(
                top: 20.0, left: 25, right: 25, bottom: 30),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: SvgPicture.asset("assets/icons/back.svg")),
                  SvgPicture.asset("assets/images/register_progress.svg"),
                  SizedBox(height: 40.0),
                  Text("Who are you?",
                      style: TextStyle(
                        color: Color.fromARGB(255, 71, 71, 71),
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      )),
                  SizedBox(height: 20.0),
                  Column(
                      children: entryToEnrollmentType.keys.map((name) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: TextButton(
                          style: ButtonStyle(
                              shape: MaterialStatePropertyAll<OutlinedBorder>(
                                  RoundedRectangleBorder(
                                      side: BorderSide(
                                          width: 2.0,
                                          color: name == _selectedOption
                                              ? Color.fromARGB(
                                                  255, 255, 170, 91)
                                              : Color.fromARGB(
                                                  255, 217, 217, 217)),
                                      borderRadius:
                                          BorderRadius.circular(10.0))),
                              backgroundColor: name == _selectedOption
                                  ? MaterialStatePropertyAll<Color>(
                                      Color.fromARGB(102, 255, 170, 91))
                                  : MaterialStatePropertyAll<Color>(
                                      Colors.white)),
                          onPressed: () => {
                                setState(() {
                                  _selectedOption = name;
                                })
                              },
                          child: Container(
                            width: 345,
                            height: 50,
                            child: Align(
                              alignment: Alignment.center,
                              child: Text(name,
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  )),
                            ),
                          )),
                    );
                  }).toList()),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                  TextButton(
                    style: ButtonStyle(
                        shape: MaterialStatePropertyAll<OutlinedBorder>(
                            RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0))),
                        backgroundColor: MaterialStatePropertyAll<Color>(
                            Color.fromARGB(255, 233, 87, 85))),
                    child: Container(
                        width: 345,
                        height: 50,
                        child: Align(
                          alignment: Alignment.center,
                          child: Text("Continue",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              )),
                        )),
                    onPressed: () {
                      print(widget.googleUser);
                      print(widget.appleUser);
                      print(widget.idToken);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => DetailsPageWidget(
                            userType: entryToEnrollmentType[_selectedOption]!,
                            googleUser: widget.googleUser,
                            appleUser: widget.appleUser,
                            idToken: widget.idToken,
                          ),
                        ),
                      );
                    },
                  ),
                ]),
          ),
        ),
      ),
    );
  }
}
