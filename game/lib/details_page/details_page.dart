
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:game/journeys/journeys_page.dart';
import 'package:game/main.dart';
import 'package:game/navigation_page/bottom_navbar.dart';
import 'package:game/interests/interests_page.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:game/utils/utility_functions.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:game/details_page/dropdown_widget.dart';

import 'package:velocity_x/velocity_x.dart';

class DetailsPageWidget extends StatefulWidget {
  DetailsPageWidget(
      {Key? key,
      required String this.userType,
      required String? this.idToken,
      required GoogleSignInAccount? this.user})
      : super(key: key);
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final String userType;
  final String? idToken;
  final GoogleSignInAccount? user;

  @override
  _DetailsPageWidgetState createState() => _DetailsPageWidgetState();
}

class _DetailsPageWidgetState extends State<DetailsPageWidget> {
  String _name = "";
  String? _college = "Arts and Sciences";
  GoogleSignInAccount? user = null;
  @override
  void initState() {
    super.initState();
  }

  final _formKey = GlobalKey<FormState>();

  DropdownWidget collegeDropdown =
      DropdownWidget(null, null, notifyParent: (val) {});

  List<String> _colleges = [
    "Agriculture and Life Sciences",
    "Architecture, Art and Planning",
    "Arts and Sciences",
    "Business",
    // "Computing and Information Science",
    "Engineering",
    "Human Ecology",
    "Industrial and Labor Relations (ILR)",
    "Public Policy",
    "Cornell Tech",
    "Law School",
    // "Veterinary Medicine",
    // "Weill Cornell Medicine"
  ];

  DropdownWidget yearDropdown =
      DropdownWidget(null, null, notifyParent: (val) {});

  List<String> _years = ["2024", "2025", "2026", "2027"];

  DropdownWidget majorDropdown =
      DropdownWidget(null, null, notifyParent: (val) {});

  Map<String, List<String>> _majors = {
    "Agriculture and Life Sciences": [],
    "Architecture, Art and Planning": [],
    "Business": [],
    "Engineering": [
      "Computer Science",
      "Information Science",
      "Chemical Engineering"
    ],
    "Arts and Sciences": [
      "Computer Science",
      "Mathematics",
      "Chemistry",
      "Biology",
      "Psychology"
    ],
    "Human Ecology": [],
    "Industrial and Labor Relations (ILR)": [],
    "Public Policy": [],
    "Cornell Tech": [],
    "Law School": [],
  };

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
                SvgPicture.asset("assets/images/details_progress.svg"),
                SizedBox(height: 40.0),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Username*",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        )),
                    TextFormField(
                      onChanged: (newValue) => setState(() {
                        _name = newValue;
                      }),
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.only(
                            left: 20.0, right: 20.0, top: 10, bottom: 10),
                        labelStyle: TextStyle(
                            color: Color.fromARGB(51, 0, 0, 0),
                            fontWeight: FontWeight.w400),
                        labelText: 'e.g. CornellianLover123',
                        enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Color.fromARGB(51, 0, 0, 0), width: 1.5),
                            borderRadius:
                                BorderRadius.all(Radius.circular(10.0))),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10.0)),
                          borderSide: BorderSide(
                            color: Color.fromARGB(255, 255, 170, 91),
                            width: 1.5,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10.0)),
                          borderSide: BorderSide(
                            color: Color.fromARGB(153, 233, 87, 85),
                            width: 1.5,
                          ),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10.0)),
                          borderSide: BorderSide(
                            color: Color.fromARGB(153, 233, 87, 85),
                            width: 1.5,
                          ),
                        ),
                      ),

                      // The validator receives the text that the user has entered.
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your username';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("College",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        )),
                    collegeDropdown = DropdownWidget(
                      null,
                      _colleges,
                      notifyParent: (val) => {
                        setState(() {
                          _college = val;
                        })
                      },
                    )
                  ],
                ),
                SizedBox(height: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Major",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        )),
                    majorDropdown = DropdownWidget(
                      null,
                      _college == null ? null : _majors[_college],
                      notifyParent: (val) {},
                    )
                  ],
                ),
                SizedBox(height: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Graduation Year",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        )),
                    yearDropdown = DropdownWidget(
                      null,
                      _years,
                      notifyParent: (val) {},
                    )
                  ],
                ),
                SizedBox(height: 150.0),
                TextButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => InterestsPageWidget(
                            userType: widget.userType,
                            user: widget.user,
                            idToken: widget.idToken,
                            username: _name,
                            college: collegeDropdown.value,
                            major: majorDropdown.value,
                            year: yearDropdown.value,
                          ),
                        ),
                      );
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
