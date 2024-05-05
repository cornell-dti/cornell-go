import 'package:flutter/material.dart';
import 'package:game/api/game_client_dto.dart';
import 'package:game/details_page/details_page.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_svg/flutter_svg.dart';

/**
 * The register page. Allows the user to select their enrollment type.
 * Comes from the SplashPageWidget.
 */
class RegisterPageWidget extends StatefulWidget {
  // The user's Google account. Must be kept track of to sign in.
  final GoogleSignInAccount? user;
  final String? idToken;
  RegisterPageWidget(
      {Key? key,
      required GoogleSignInAccount? this.user,
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
      body: Padding(
        padding: const EdgeInsets.only(top: 50.0, left: 25, right: 25),
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
                                          ? Color.fromARGB(255, 255, 170, 91)
                                          : Color.fromARGB(255, 217, 217, 217)),
                                  borderRadius: BorderRadius.circular(10.0))),
                          backgroundColor: name == _selectedOption
                              ? MaterialStatePropertyAll<Color>(
                                  Color.fromARGB(102, 255, 170, 91))
                              : MaterialStatePropertyAll<Color>(Colors.white)),
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
              SizedBox(height: 150.0),
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
                  print(widget.user);
                  print(widget.idToken);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => DetailsPageWidget(
                        userType: entryToEnrollmentType[_selectedOption]!,
                        user: widget.user,
                        idToken: widget.idToken,
                      ),
                    ),
                  );
                },
              ),
            ]),
      ),
    );
  }
}
