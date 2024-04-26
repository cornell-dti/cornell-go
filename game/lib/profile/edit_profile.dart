import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/svg.dart';
import 'package:game/details_page/dropdown_widget.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:game/progress_indicators/circular_progress_indicator.dart';

import 'package:game/api/game_client_dto.dart';
import 'package:game/model/challenge_model.dart';
import 'package:game/model/event_model.dart';
import 'package:game/model/tracker_model.dart';
import 'package:game/model/user_model.dart';
import 'package:provider/provider.dart';

class EditProfileWidget extends StatefulWidget {
  EditProfileWidget({
    Key? key,
  }) : super(key: key);

  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfileWidget> {
  GoogleSignInAccount? user = null;
  @override
  void initState() {
    super.initState();
  }

  String? myCollege;
  String? myMajor;
  String? myYear;
  String? myUsername;
  final _formKey = GlobalKey<FormState>();

  var headingStyle = TextStyle(
    color: Colors.black.withOpacity(0.8),
    fontSize: 18,
    fontFamily: 'Poppins',
    fontWeight: FontWeight.w600,
    height: 0,
  );
  var buttonStyle = TextStyle(
    color: Colors.white,
    fontSize: 16,
    fontFamily: 'Poppins',
    fontWeight: FontWeight.w600,
    height: 0,
  );
  var fieldDecoration = InputDecoration(
    contentPadding:
        EdgeInsets.only(left: 20.0, right: 20.0, top: 10, bottom: 10),
    labelStyle: TextStyle(
        color: Color.fromARGB(51, 0, 0, 0), fontWeight: FontWeight.w400),
    enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Color.fromARGB(51, 0, 0, 0), width: 1.5),
        borderRadius: BorderRadius.all(Radius.circular(10.0))),
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
    fillColor: Colors.white,
    filled: true,
  );

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
  List<String> _years = ["2024", "2025", "2026", "2027"];

  @override
  Widget build(BuildContext context) {
    myCollege = Provider.of<UserModel>(context, listen: true).userData?.college;
    // define major dropdown separately as it depends on the state of myCollege
    DropdownWidget majorDropdown = DropdownWidget(
        // assigning UniqueKey will rebuild widget upon state change
        key: UniqueKey(),
        myMajor,
        myCollege == null ? null : _majors[myCollege], notifyParent: (val) {
      myMajor = val;
    });

    return Scaffold(
        backgroundColor: Color.fromARGB(255, 255, 248, 241),
        appBar: AppBar(
          toolbarHeight: 70,
          backgroundColor: Color.fromARGB(255, 237, 86, 86),
          // Set widget before appBar title
          leading: IconButton(
            icon: const Icon(Icons.navigate_before),
            color: Colors.white,
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: const Text(
            'Edit Profile',
            style: TextStyle(
                color: Colors.white,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold),
          ),
          actions: [],
        ),
        body: Center(
            child: Consumer<UserModel>(builder: (context, userModel, child) {
          if (userModel.userData == null) {
            return CircularIndicator();
          }

          myUsername = userModel.userData?.username;
          myYear = userModel.userData?.year;
          if (myYear != null && myYear!.length == 0) {
            myYear = null;
          }
          myCollege = userModel.userData?.college;
          if (myCollege != null && myCollege!.length == 0) {
            myCollege = null;
          }
          myMajor = userModel.userData?.major;
          if (myMajor != null && myMajor!.length == 0) {
            myMajor = null;
          }

          return LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
            return SizedBox(
                width: constraints.maxWidth * 0.85,
                child: Column(
                    // crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: 30),
                        child: SvgPicture.asset(
                            "assets/images/yellow_bear_prof.svg",
                            height: 115,
                            width: 115),
                      ),
                      Container(
                          padding: EdgeInsets.only(top: 30),
                          width: double.infinity,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Username *', style: headingStyle),
                              SizedBox(height: 5),
                              TextFormField(
                                decoration: fieldDecoration,
                                initialValue: myUsername,
                                onChanged: (value) => {myUsername = value},
                              )
                            ],
                          )),
                      Container(
                          padding: EdgeInsets.only(top: 15),
                          width: double.infinity,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('College', style: headingStyle),
                              SizedBox(height: 5),
                              DropdownWidget(myCollege, _colleges,
                                  notifyParent: (val) {
                                setState(() {
                                  myCollege = val;
                                });
                              })
                            ],
                          )),
                      Container(
                          padding: EdgeInsets.only(top: 15),
                          width: double.infinity,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Major', style: headingStyle),
                              SizedBox(height: 5),
                              // Changing key forces a rebuild of child widget
                              majorDropdown
                            ],
                          )),
                      Container(
                          padding: EdgeInsets.only(top: 15),
                          width: double.infinity,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Graduation Year', style: headingStyle),
                              SizedBox(height: 5),
                              DropdownWidget(myYear, _years,
                                  notifyParent: (val) {
                                myYear = val;
                              })
                            ],
                          )),
                      SizedBox(height: 100),
                      TextButton(
                        onPressed: () {
                          userModel.updateUserData(userModel.userData?.id ?? "",
                              myUsername, myCollege, myMajor, myYear);
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: Color(0xFFE95755),
                          disabledBackgroundColor: Color(0xFFB9B9B9),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 138, vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Update',
                              style: buttonStyle,
                            ),
                          ],
                        ),
                      )
                    ]));
          });
        })));
  }
}
