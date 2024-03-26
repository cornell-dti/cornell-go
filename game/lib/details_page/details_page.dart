import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:game/journeys/journeys_page.dart';
import 'package:game/main.dart';
import 'package:game/navigation_page/bottom_navbar.dart';
import 'package:game/interests/interests_page.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:game/utils/utility_functions.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

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
  String _year = "Select one";
  String _college = "Select one";
  String _major = "Select one";
  String _name = "";
  GoogleSignInAccount? user = null;
  @override
  void initState() {
    super.initState();
  }

  final _formKey = GlobalKey<FormState>();

  List<String> _colleges = [
    "Select one",
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
  List<String> _years = ["Select one", "2024", "2025", "2026", "2027"];
  Map<String, List<String>> _majors = {
    "Select one": ["Select one"],
    "Agriculture and Life Sciences": ["Select one"],
    "Architecture, Art and Planning": ["Select one"],
    "Business": ["Select one"],
    "Engineering": [
      "Select one",
      "Computer Science",
      "Information Science",
      "Chemical Engineering"
    ],
    "Arts and Sciences": [
      "Select one",
      "Computer Science",
      "Mathematics",
      "Chemistry",
      "Biology",
      "Psychology"
    ],
    "Human Ecology": ["Select one"],
    "Industrial and Labor Relations (ILR)": ["Select one"],
    "Public Policy": ["Select one"],
    "Cornell Tech": ["Select one"],
    "Law School": ["Select one"],
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
                      onSaved: (newValue) => setState(() {
                        _name = newValue!;
                      }),
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.only(
                            left: 20.0, right: 20.0, top: 10, bottom: 10),
                        enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Color.fromARGB(51, 0, 0, 0), width: 1.5),
                            borderRadius:
                                BorderRadius.all(Radius.circular(10.0))),
                        labelStyle: TextStyle(
                            color: Color.fromARGB(51, 0, 0, 0),
                            fontWeight: FontWeight.w400),
                        labelText: 'e.g. CornellianLover123',
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10.0)),
                          borderSide: BorderSide(
                            color: Color.fromARGB(51, 0, 0, 0),
                            width: 1.5,
                          ),
                        ),
                      ),

                      // The validator receives the text that the user has entered.
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter some text';
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
                    DropdownButtonHideUnderline(
                      child: DropdownButton2<String>(
                        isExpanded: true,
                        dropdownStyleData: DropdownStyleData(maxHeight: 200),
                        iconStyleData: IconStyleData(
                            icon: Padding(
                          padding: const EdgeInsets.only(right: 20.0),
                          child: SvgPicture.asset("assets/icons/dropdown.svg"),
                        )),
                        buttonStyleData: ButtonStyleData(
                          decoration: BoxDecoration(
                              border: Border.all(
                                  width: 2.0,
                                  color: Color.fromARGB(255, 217, 217, 217)),
                              borderRadius: BorderRadius.circular(10.0)),
                        ),
                        style: TextStyle(
                            color: Color.fromARGB(51, 0, 0, 0),
                            fontWeight: FontWeight.w400),
                        value: _college,
                        onChanged: (newValue) {
                          setState(() {
                            _college = newValue.toString();
                          });
                        },
                        items: _colleges.map((college) {
                          return DropdownMenuItem(
                            child: Container(
                                child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(college,
                                  style: TextStyle(
                                      fontFamily: 'Poppins',
                                      color: Colors.black,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400)),
                            )),
                            value: college,
                          );
                        }).toList(),
                      ),
                    ),
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
                    DropdownButtonHideUnderline(
                      child: DropdownButton2<String>(
                        isExpanded: true,
                        dropdownStyleData: DropdownStyleData(maxHeight: 200),
                        iconStyleData: IconStyleData(
                            icon: Padding(
                          padding: const EdgeInsets.only(right: 20.0),
                          child: SvgPicture.asset("assets/icons/dropdown.svg"),
                        )),
                        buttonStyleData: ButtonStyleData(
                          decoration: BoxDecoration(
                              border: Border.all(
                                  width: 2.0,
                                  color: Color.fromARGB(255, 217, 217, 217)),
                              borderRadius: BorderRadius.circular(10.0)),
                        ),
                        style: TextStyle(
                            color: Color.fromARGB(51, 0, 0, 0),
                            fontWeight: FontWeight.w400),
                        value: _major,
                        onChanged: (newValue) {
                          setState(() {
                            _major = newValue.toString();
                          });
                        },
                        items: _majors[_college]!.map((major) {
                          return DropdownMenuItem(
                            child: Container(
                                child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(major,
                                  style: TextStyle(
                                      fontFamily: 'Poppins',
                                      color: Color.fromARGB(255, 0, 0, 0),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400)),
                            )),
                            value: major,
                          );
                        }).toList(),
                      ),
                    ),
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
                    DropdownButtonHideUnderline(
                      child: DropdownButton2<String>(
                        isExpanded: true,
                        dropdownStyleData: DropdownStyleData(maxHeight: 200),
                        iconStyleData: IconStyleData(
                            icon: Padding(
                          padding: const EdgeInsets.only(right: 20.0),
                          child: SvgPicture.asset("assets/icons/dropdown.svg"),
                        )),
                        buttonStyleData: ButtonStyleData(
                          decoration: BoxDecoration(
                              border: Border.all(
                                  width: 2.0,
                                  color: Color.fromARGB(255, 217, 217, 217)),
                              borderRadius: BorderRadius.circular(10.0)),
                        ),
                        style: TextStyle(
                            color: Color.fromARGB(51, 0, 0, 0),
                            fontWeight: FontWeight.w400),
                        value: _year,
                        onChanged: (newValue) {
                          setState(() {
                            _year = newValue.toString();
                          });
                        },
                        items: _years.map((year) {
                          return DropdownMenuItem(
                            child: Container(
                                child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(year,
                                  style: TextStyle(
                                      fontFamily: 'Poppins',
                                      color: Colors.black,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400)),
                            )),
                            value: year,
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 150.0),
                TextButton(
                  onPressed: () async {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => InterestsPageWidget(
                          userType: widget.userType,
                          user: widget.user,
                          idToken: widget.idToken,
                          username: _name,
                          college: (_college == "Select one") ? null : _college,
                          major: (_major == "Select one") ? null : _major,
                          year: (_year == "Select one") ? null : _year,
                        ),
                      ),
                    );
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
