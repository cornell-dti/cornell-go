import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:game/details_page/dropdown_widget.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:game/progress_indicators/circular_progress_indicator.dart';
import 'package:game/model/user_model.dart';
import 'package:provider/provider.dart';

/**
 * `EditProfileWidget` - A form interface for editing user profile information.
 * 
 * @remarks
 * This widget provides a complete form for users to edit their profile details including
 * username, college, major, and graduation year. It uses dropdown selectors for predefined
 * options and text input for the username. The widget automatically detects changes to
 * enable/disable the update button and communicates with the UserModel to persist changes.
 * 
 */
class EditProfileWidget extends StatefulWidget {
  EditProfileWidget({
    Key? key,
  }) : super(key: key);

  @override
  _EditProfileState createState() => _EditProfileState();
}

/**
 * The profile editing page of the app that allows the user to update their profile information.
 * `EditProfileWidget` Component - A page where the user can modify their username, college, major, and graduation year.
 * 
 * @remarks
 * This component serves as the screen where users can edit their profile information in the CornellGO app. It communicates with the UserModel provider to update the user's profile. It includes fields for updating:
 * - Username
 * - College
 * - Major (dynamically populated based on selected college)
 * - Graduation Year
 * 
 * The component is designed to be responsive, adapting to screen sizes using flexible layout strategies such as `LayoutBuilder` and `ValueListenableBuilder`. It uses a custom `DropdownWidget` for selecting college, major, and graduation year.
 * 
 * The page ensures that only non-empty and valid fields are allowed to update, and provides real-time updates to the "Update" button's state based on changes made to any of the fields. It consumes data from the `UserModel` and updates user profile information using the `updateUserData` method.
 * 
 * The app also uses the `GoogleSignInAccount` for user-related data, and the profile page reacts accordingly if the user is not signed in or if their data is unavailable.
 * 
 * @param key - Optional Flutter widget key for identification and testing.
 * 
 * @returns A StatefulWidget that displays a form to edit the user's profile information.

 * @privateRemarks
 * The state uses ValueNotifier objects to trigger rebuilds of specific widget
 * subtrees when dependent values change, which is more efficient than calling
 * setState() for the entire widget.
 */
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
    "Computing and Information Science",
    "Engineering",
    "Human Ecology",
    "Industrial and Labor Relations (ILR)",
    "Public Policy",
    "Cornell Tech",
    "Law School",
    "Veterinary Medicine",
    "Weill Cornell Medicine"
  ];

  Map<String, List<String>> _majors = {
    "Agriculture and Life Sciences": [
      "Agricultural Sciences",
      "Animal Science",
      "Applied Economics & Management",
      "Atmospheric Science",
      "Biological Engineering",
      "Biological Sciences",
      "Biology & Society",
      "Biometry & Statistics",
      "Communication",
      "Earth & Atmospheric Sciences",
      "Entomology",
      "Environment & Sustainability",
      "Environmental Engineering",
      "Food Science",
      "Global & Public Health Sciences",
      "Global Development",
      "Information Science",
      "Interdisciplinary Studies",
      "Landscape Architecture",
      "Nutritional Sciences",
      "Plant Sciences",
      "Viticulture & Enology"
    ],
    "Architecture, Art and Planning": [
      "Architecture",
      "Fine Arts",
      "History of Architecture",
      "Urban and Regional Studies"
    ],
    "Business": ["Applied Economics and Management", "Hotel Administration"],
    "Engineering": [
      "Biological Engineering",
      "Biomedical Engineering",
      "Chemical Engineering",
      "Civil Engineering",
      "Computer Science",
      "Earth and Atmospheric Sciences",
      "Electrical and Computer Engineering",
      "Engineering Physics",
      "Environmental Engineering",
      "Independent Major",
      "Information Science, Systems, and Technology",
      "Materials Science and Engineering",
      "Mechanical Engineering",
      "Operations Research and Engineering"
    ],
    "Arts and Sciences": [
      "Africana Studies",
      "American Studies",
      "Anthropology",
      "Archaeology",
      "Asian Studies",
      "Astronomy",
      "Biological Sciences",
      "Biology and Society",
      "Chemistry",
      "China and Asia-Pacific Studies",
      "Classics (Classics, Greek, Latin, Classical Civilization)",
      "Cognitive Science",
      "College Scholar/Independent Major",
      "Comparative Literature",
      "Computer Science",
      "Earth and Atmospheric Sciences",
      "Economics",
      "English",
      "Environment and Sustainability",
      "Feminist, Gender, and Sexuality Studies",
      "French",
      "German Studies",
      "Government",
      "History",
      "History of Art",
      "Information Science",
      "Italian",
      "Jewish Studies",
      "Linguistics",
      "Mathematics",
      "Music",
      "Near Eastern Studies",
      "Performing and Media Arts",
      "Philosophy",
      "Physics",
      "Psychology",
      "Public Policy",
      "Religious Studies",
      "Science and Technology Studies",
      "Sociology",
      "Spanish",
      "Statistical Science",
      "Undecided"
    ],
    "Human Ecology": [
      "Design and Environmental Analysis",
      "Fashion Design and Management",
      "Fiber Science",
      "Global and Public Health Sciences",
      "Human Biology, Health, and Society",
      "Human Development",
      "Nutritional Sciences",
      "Undecided"
    ],
    "Industrial and Labor Relations (ILR)": [],
    "Public Policy": ["Health Care Policy", "Public Policy"],
    "Computing and Information Science": [
      "Biometry and Statistics",
      "Computer Science",
      "Information Science",
      "Information Science, Systems, and Technology",
      "Statistical Science"
    ],
    "Cornell Tech": [],
    "Law School": [],
    "Veterinary Medicine": [],
    "Weill Cornell Medicine": []
  };

  List<String> _years = ["2025", "2026", "2027", "2028", "2029", "2030"];

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

          // Initialize fields only if they haven't been already
          if (newUsername == null) newUsername = currUsername ?? '';

          if (newYear == null) {
            newYear = currYear;
            if (newYear != null && newYear!.isEmpty) {
              newYear = null;
            }
          }

          if (newCollege == null) {
            newCollege = currCollege;
            if (newCollege != null && newCollege!.isEmpty) {
              newCollege = null;
            }
          }

          if (newMajor == null) {
            newMajor = currMajor;
            if (newMajor != null && newMajor!.isEmpty) {
              newMajor = null;
            }
          }

          // Determines if any profile fields have been changed from their original values.
          bool fieldsChanged() {
            if (newUsername == null ||
                newCollege == null ||
                newYear == null ||
                newMajor == null) {
              return false;
            }
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
                child: SingleChildScrollView(
                  child: Column(
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
                      Padding(
                        padding: const EdgeInsets.only(top: 30, bottom: 60),
                        child: ValueListenableBuilder<double>(
                          valueListenable: updateButtonKey,
                          builder: (BuildContext context, double keyValue,
                              Widget? child) {
                            return Container(
                              width: double.infinity,
                              child: TextButton(
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
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                ),
                                child: Text(
                                  'Update',
                                  style: buttonStyle,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ));
          });
        })));
  }
}
