import 'package:flutter/material.dart';
import 'package:game/api/game_client_dto.dart';
import 'package:game/challenges/challenges_page.dart';
import 'package:game/main.dart';
import 'package:game/navigation_page/bottom_navbar.dart';
import 'package:game/splash_page/splash_page.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:game/utils/utility_functions.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:game/profile/settings_page.dart';

/// This page allows the user to select their interests. Connection to backend
/// (creating the user) happens here.
class InterestsPageWidget extends StatefulWidget {
  InterestsPageWidget(
      {Key? key,
      required LoginEnrollmentTypeDto this.userType,
      required String? this.idToken,
      GoogleSignInAccount? this.googleUser,
      AuthorizationCredentialAppleID? this.appleUser,
      required String this.username,
      required String? this.college,
      required String? this.major,
      required String? this.year})
      : super(key: key);
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final LoginEnrollmentTypeDto userType;
  final String? idToken;
  final GoogleSignInAccount? googleUser;
  final AuthorizationCredentialAppleID? appleUser;
  final String username;
  final String? college;
  final String? major;
  final String? year;
  @override
  _InterestsPageWidgetState createState() => _InterestsPageWidgetState();
}

class _InterestsPageWidgetState extends State<InterestsPageWidget> {
  GoogleSignInAccount? user = null;
  @override
  void initState() {
    super.initState();
  }

  List<String> _categories = ["Food", "Nature", "History", "Cafes", "Dorms"];

  List<bool> _checked = [false, false, false, false, false, false];

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(
                top: 20.0, left: 25, right: 25, bottom: 30),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: SvgPicture.asset("assets/icons/back.svg")),
                  SvgPicture.asset("assets/images/interests_progress.svg"),
                  SizedBox(height: 40.0),
                  Text("What are your interests?",
                      style: TextStyle(
                        color: Color.fromARGB(255, 71, 71, 71),
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      )),
                  Text("Select one or more categories below.",
                      style: TextStyle(
                        color: Color.fromARGB(255, 186, 186, 186),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      )),
                  for (int i = 0; i < _categories.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: CheckboxListTile(
                          title: Text(_categories[i],
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              )),
                          value: _checked[i],
                          controlAffinity: ListTileControlAffinity.leading,
                          tileColor: _checked[i]
                              ? Color.fromARGB(77, 255, 170, 91)
                              : Colors.white,
                          fillColor: MaterialStateProperty.all<Color>(
                              _checked[i]
                                  ? Colors.white
                                  : Color.fromARGB(25, 0, 0, 0)),
                          checkColor: Color.fromARGB(255, 110, 74, 40),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                                width: 2,
                                color: _checked[i]
                                    ? Color.fromARGB(255, 255, 170, 91)
                                    : Color.fromARGB(255, 228, 228, 228)),
                          ),
                          checkboxShape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(2),
                          ),
                          side: BorderSide.none,
                          onChanged: (newValue) {
                            setState(() {
                              _checked[i] = newValue!;
                            });
                          }),
                    ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                  TextButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        List<String> interests = [];
                        for (int i = 0; i < _checked.length; i++) {
                          if (_checked[i]) interests.add(_categories[i]);
                        }

                        var connectionResult;

                        // Handle Google Sign-In user
                        if (widget.googleUser != null) {
                          connectionResult = await client.connectGoogle(
                              widget.googleUser!,
                              this.widget.year ?? "",
                              this.widget.userType,
                              this.widget.username,
                              this.widget.college ?? "",
                              this.widget.major ?? "",
                              interests);
                        }
                        // Handle Apple Sign-In user
                        else if (widget.appleUser != null) {
                          connectionResult = await client.connectApple(
                              widget.appleUser!,
                              this.widget.year ?? "",
                              this.widget.userType,
                              this.widget.username,
                              this.widget.college ?? "",
                              this.widget.major ?? "",
                              interests);
                        }

                        if (connectionResult == null) {
                          displayToast(
                              "An error occurred while signing you up!",
                              Status.error);
                        } else {
                          //  Sucess case - Navigation handled by splash_page.dart StreamBuilder
                          print(
                              "Registration successful - automatic navigation will occur");
                        }
                      }
                    },
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
