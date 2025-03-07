import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:game/details_page/dropdown_widget.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:game/progress_indicators/circular_progress_indicator.dart';

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

  final majorDropdownKey = ValueNotifier<double>(0);
  final updateButtonKey = ValueNotifier<double>(0);

  String? newCollege;
  String? newMajor;
  String? newYear;
  String? newUsername;

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
    var headerStyle = TextStyle(
      color: Color(0xFFFFF8F1),
      fontSize: 20,
      fontFamily: 'Poppins',
      fontWeight: FontWeight.w600,
    );

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
            title: Padding(
              padding: EdgeInsets.only(
                  top: MediaQuery.of(context).size.height * 0.01),
              child: Text(
                'Edit Profile',
                style: headerStyle,
              ),
            ),
            actions: [],
            centerTitle: true),
        body: Center(
            child: Consumer<UserModel>(builder: (context, userModel, child) {
          if (userModel.userData == null) {
            return CircularIndicator();
          }

          String? currUsername = userModel.userData?.username;
          String? currYear = userModel.userData?.year;
          String? currCollege = userModel.userData?.college;
          String? currMajor = userModel.userData?.major;

// can't repress update bar when username is changed (no option to select it, whereas for college, major, if they are changed you can reclick update button)
// how to check if username already exists: check admin/Users, prisma postgres 
//if no database of usernames, make one in backend 

          newUsername = currUsername;
          newYear = currYear;
          if (newYear != null && newYear!.isEmpty) {
            newYear = null;
          }
          newCollege = currCollege;
          if (newCollege != null && newCollege!.isEmpty) {
            newCollege = null;
          }
          newMajor = currMajor;
          if (newMajor != null && newMajor!.isEmpty) {
            newMajor = null;
          }

          bool fieldsChanged() {
            if (newCollege == null ||
                newYear == null ||
                newMajor == null) {
              return false;
            } 
            //previously returned false if username was null or 
            //if any of the other options were null, so if the 
            // username was changed, would still return false if other ones werent changed
            
            //doesnt allow username to be empty; username is never null
            if (newUsername!.isEmpty) {
              return false;
            }
            // return true if any of the fields are different
            return (newUsername != currUsername ||
                newYear != currYear ||
                newMajor != currMajor ||
                newCollege != currCollege);
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
                                initialValue: newUsername,
                                onChanged: (value) {
                                  newUsername = value;
                                  updateButtonKey.value++;
                                },
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
                              DropdownWidget(newCollege, _colleges,
                                  notifyParent: (val) {
                                newCollege = val;
                                majorDropdownKey.value++;
                                updateButtonKey.value++;
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
                              ValueListenableBuilder<double>(
                                  valueListenable: majorDropdownKey,
                                  builder: (BuildContext context,
                                      double keyValue, Widget? child) {
                                    return DropdownWidget(
                                        // assigning UniqueKey will rebuild widget upon state change
                                        key: ValueKey(keyValue),
                                        (_majors[newCollege] == null ||
                                                !_majors[newCollege]!
                                                    .contains(newMajor))
                                            ? null
                                            : newMajor,
                                        newCollege == null
                                            ? null
                                            : _majors[newCollege],
                                        notifyParent: (val) {
                                      newMajor = val;
                                      updateButtonKey.value++;
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
                              Text('Graduation Year', style: headingStyle),
                              SizedBox(height: 5),
                              DropdownWidget(newYear, _years,
                                  notifyParent: (val) {
                                newYear = val;
                                updateButtonKey.value++;
                              })
                            ],
                          )),
                      SizedBox(height: 100),
                      ValueListenableBuilder<double>(
                          valueListenable: updateButtonKey,
                          builder: (BuildContext context, double keyValue,
                              Widget? child) {
                            return TextButton(
                              key: ValueKey(keyValue),
                              onPressed: !fieldsChanged()
                                  ? null
                                  : () {
                                      userModel.updateUserData(
                                          userModel.userData?.id ?? "",
                                          newUsername,
                                          newCollege,
                                          newMajor,
                                          newYear);
                                      setState(() {});
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
                            );
                          })
                    ]));
          });
        })));
  }
}
