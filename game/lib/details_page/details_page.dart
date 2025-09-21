import 'package:flutter/material.dart';
import 'package:game/api/game_client_dto.dart';
import 'package:game/interests/interests_page.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:game/details_page/dropdown_widget.dart';

class DetailsPageWidget extends StatefulWidget {
  DetailsPageWidget(
      {Key? key,
      required LoginEnrollmentTypeDto this.userType,
      required String? this.idToken,
      GoogleSignInAccount? this.googleUser,
      AuthorizationCredentialAppleID? this.appleUser})
      : super(key: key);
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final LoginEnrollmentTypeDto userType;
  final String? idToken;
  final GoogleSignInAccount? googleUser;
  final AuthorizationCredentialAppleID? appleUser;

  @override
  _DetailsPageWidgetState createState() => _DetailsPageWidgetState();
}

/* A form page in the onboarding flow for collecting user academic details.

This widget allows users to input their username (required), college, major,
and graduation year. The major dropdown updates dynamically based on the
selected college. All inputs are validated before proceeding.

Upon successful validation, the user is navigated to [InterestsPageWidget]
with their entered details and authentication info (user type, ID token, etc.).

Key features include:
- Dynamic dropdowns for college, major, and year
- Form validation using [_formKey]
- State-managed inputs with real-time updates

This page is a required step in the onboarding process before collecting interests. */
class _DetailsPageWidgetState extends State<DetailsPageWidget> {
  String _name = "";
  String? _college;
  String? _major;
  String? _year;
  GoogleSignInAccount? user = null;
  @override
  void initState() {
    super.initState();
  }

  final _formKey = GlobalKey<FormState>();

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

  List<String> _years = [
    "2025",
    "2026",
    "2027",
    "2028",
    "2029",
    "2030",
    "Alumni"
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

  @override
  Widget build(BuildContext context) {
    // define major dropdown separately as it depends on the state of _college
    DropdownWidget majorDropdown = DropdownWidget(
      // assigning UniqueKey will rebuild widget upon state change
      key: UniqueKey(),
      null,
      _college == null ? null : _majors[_college],
      notifyParent: (val) {
        _major = val;
      },
    );

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
                                  color: Color.fromARGB(51, 0, 0, 0),
                                  width: 1.5),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10.0))),
                          focusedBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(10.0)),
                            borderSide: BorderSide(
                              color: Color.fromARGB(255, 255, 170, 91),
                              width: 1.5,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(10.0)),
                            borderSide: BorderSide(
                              color: Color.fromARGB(153, 233, 87, 85),
                              width: 1.5,
                            ),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(10.0)),
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
                      DropdownWidget(
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
                      majorDropdown
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
                      DropdownWidget(
                        null,
                        _years,
                        notifyParent: (val) {
                          _year = val;
                        },
                      )
                    ],
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                  TextButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => InterestsPageWidget(
                              userType: widget.userType,
                              googleUser: widget.googleUser,
                              appleUser: widget.appleUser,
                              idToken: widget.idToken,
                              username: _name,
                              college: _college,
                              major: _major,
                              year: _year,
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
            ),
          ),
        ),
      ),
    );
  }
}
