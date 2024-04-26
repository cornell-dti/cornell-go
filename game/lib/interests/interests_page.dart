import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:game/journeys/journeys_page.dart';
import 'package:game/main.dart';
import 'package:game/navigation_page/bottom_navbar.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:game/utils/utility_functions.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

class InterestsPageWidget extends StatefulWidget {
  InterestsPageWidget(
      {Key? key,
      required String this.userType,
      required String? this.idToken,
      required GoogleSignInAccount? this.user,
      required String this.username,
      required String? this.college,
      required String? this.major,
      required String? this.year})
      : super(key: key);
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final String userType;
  final String? idToken;
  final GoogleSignInAccount? user;
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
      body: Padding(
          padding: const EdgeInsets.only(left: 25, right: 25, top: 50),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SvgPicture.asset("assets/icons/back.svg"),
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
                        fillColor: MaterialStateProperty.all<Color>(_checked[i]
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
                SizedBox(height: 75.0),
                TextButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      List<String> interests = [];
                      for (int i = 0; i < _checked.length; i++) {
                        if (_checked[i]) interests.add(_categories[i]);
                      }

                      assert(widget.user != null || widget.idToken != null);
                      final auth = await widget.user?.authentication;
                      final idToken =
                          widget.user != null ? auth?.idToken : widget.idToken;
                      final endpoint_string = API_URL +
                          (widget.user != null ? "/google" : "/device-login");
                      final connectionResult = await client.connect(
                          idToken!,
                          Uri.parse(endpoint_string),
                          this.widget.userType,
                          this.widget.year ?? "",
                          this.widget.username,
                          this.widget.college ?? "",
                          this.widget.major ?? "",
                          interests);

                      if (connectionResult == null) {
                        displayToast("An error occurred while signing you up!",
                            Status.error);
                      } else {
                        //Connect to home page here.
                        print("Connection result:");
                        print(connectionResult.body);
                        displayToast("Signed in!", Status.success);
                        Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => BottomNavBar()));
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
          )),
    );
  }
}
