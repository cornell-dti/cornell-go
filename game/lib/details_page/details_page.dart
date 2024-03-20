import 'package:flutter/material.dart';
import 'package:game/journeys/journeys_page.dart';
import 'package:game/main.dart';
import 'package:game/navigation_page/bottom_navbar.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:game/utils/utility_functions.dart';
import 'package:game/gameplay/gameplay_page.dart';

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
  String _year = "2025";
  String _name = "";
  GoogleSignInAccount? user = null;
  @override
  void initState() {
    super.initState();
  }

  final _formKey = GlobalKey<FormState>();

  List<String> _years = ["2025"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 50),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LatoText("Name", 18, Colors.black, FontWeight.w700),
                    SizedBox(height: 10),
                    TextFormField(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'e.g. Jane Doe',
                      ),
                      onChanged: (newValue) => setState(() {
                        _name = newValue;
                      }),
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
                    LatoText("Username", 18, Colors.black, FontWeight.w700),
                    SizedBox(height: 10),
                    TextFormField(
                      onSaved: (newValue) => setState(() {
                        _name = newValue!;
                      }),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'e.g. JaneDoe123',
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
                    LatoText("Graduation Year (optional)", 18, Colors.black,
                        FontWeight.w700),
                    SizedBox(height: 10),
                    SizedBox(
                      width: 255,
                      child: DropdownButton(
                        isExpanded: true,
                        value: _year,
                        onChanged: (newValue) {
                          setState(() {
                            _year = newValue.toString();
                          });
                        },
                        items: _years.map((year) {
                          return DropdownMenuItem(
                            child: Container(
                                width: 255,
                                height: 53,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: LatoText(year, 16.0, Colors.black,
                                      FontWeight.w600),
                                )),
                            value: year,
                          );
                        }).toList(),
                      ),
                    )
                  ],
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
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
                          _year,
                          _name);

                      if (connectionResult == null) {
                        displayToast("An error occurred while signing you up!",
                            Status.error);
                      } else {
                        //Connect to home page here.
                        print("Connection result:");
                        print(connectionResult.body);
                        displayToast("Signed in!", Status.success);
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => GameplayPage(
                                      eventId:
                                          "1e5b7d13-f13d-4245-b3ce-d7619006a5ed",
                                    )));
                      }
                    }
                  },
                  style: ButtonStyle(
                      backgroundColor:
                          MaterialStatePropertyAll<Color>(Colors.black)),
                  child: Container(
                      width: 255,
                      height: 53,
                      child: Align(
                        alignment: Alignment.center,
                        child: LatoText(
                            "Continue", 16.0, Colors.white, FontWeight.w600),
                      )),
                ),
              ],
            ),
          )),
    );
  }
}
