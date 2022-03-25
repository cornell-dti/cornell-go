import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:game/api/game_api.dart';
import 'package:game/home_page/home_page_widget.dart';
import 'package:provider/provider.dart';
import 'package:game/model/user_model.dart';
import 'package:game/username/username_widget.dart';

class LoginWidget extends StatefulWidget {
  final FlutterSecureStorage storage;
  final String API_URL;
  LoginWidget({Key? key, required this.storage, required this.API_URL})
      : super(key: key);

  @override
  _LoginWidgetState createState() => _LoginWidgetState();
}

class _LoginWidgetState extends State<LoginWidget> {
  bool didCheck = false;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
  }

  Future<void> checkLoggedIn(apiClient) async {
    if (!didCheck) {
      didCheck = !didCheck;
      if (await apiClient.tryRelog()) {
        _toHomePage(context);
      } else {}
    }
  }

  void _toHomePage(context) {
    Navigator.pop(context);
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => HomePageWidget()));
  }

  @override
  Widget build(BuildContext context) {
    TextEditingController usernameController = new TextEditingController();
    Color Carnelian = Color(0xFFB31B1B);
    return Scaffold(
        key: scaffoldKey,
        backgroundColor: Colors.black,
        body: Center(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                Container(
                    child: Image.asset('assets/images/logo_hires.png'),
                    width: 200,
                    height: 200),
                Text("CornellGO!",
                    style: GoogleFonts.lato(
                        textStyle: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 35))),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text("INTERACTIVE SCAVENGER HUNT",
                      style: GoogleFonts.lato(
                          textStyle:
                              TextStyle(color: Colors.white, fontSize: 14))),
                )
              ],
            ),
            Column(
              children: [
                Padding(
                    padding:
                        const EdgeInsets.only(left: 30, right: 30, bottom: 30),
                    child: Container(
                      width: 225,
                      height: 50,
                      child: TextField(
                        controller: usernameController,
                        style: GoogleFonts.lato(
                            textStyle: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.normal,
                                fontSize: 16)),
                        cursorColor: Carnelian,
                        decoration: new InputDecoration(
                            focusColor: Colors.white,
                            fillColor: Colors.white,
                            focusedBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.white, width: 2.0),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: Carnelian, width: 2.0),
                            ),
                            hintText: 'Username',
                            hintStyle: GoogleFonts.lato(
                                textStyle: TextStyle(
                                    color: Colors.grey,
                                    fontWeight: FontWeight.normal,
                                    fontSize: 16))),
                      ),
                    )),
                Padding(
                    padding: const EdgeInsets.only(bottom: 0),
                    child: Consumer<ApiClient>(
                      builder: (context, apiClient, child) {
                        // checkLoggedIn(apiClient);
                        return Container(
                          width: 225,
                          height: 50,
                          child: TextButton(
                            style: ButtonStyle(
                              backgroundColor:
                                  MaterialStateProperty.all<Color>(Carnelian),
                              foregroundColor: MaterialStateProperty.all<Color>(
                                  Colors.white),
                            ),
                            onPressed: () async {
                              final username = usernameController.text;
                              if (username == "") {
                                _showDialog("Please enter a username.");
                              } else {
                                final auth =
                                    await apiClient.connectId(username);
                                if (!auth) {
                                  _showDialog(
                                      "An error occurred while signing you in. Please check your connection and try again.");
                                } else {
                                  _toHomePage(context);
                                }
                              }
                            },
                            child: Text("Sign in with username"),
                          ),
                        );
                      },
                    )),
                const Divider(
                  height: 50,
                  thickness: 2,
                  indent: 50,
                  color: Colors.grey,
                  endIndent: 50,
                ),
                Padding(
                    padding: const EdgeInsets.only(bottom: 0),
                    child: Consumer<ApiClient>(
                      builder: (context, apiClient, child) {
                        // checkLoggedIn(apiClient);
                        return Container(
                          width: 225,
                          height: 50,
                          child:
                              SignInButton(Buttons.Google, onPressed: () async {
                            final bool isAuth = await apiClient.connectGoogle();
                            if (!isAuth) {
                              _showDialog(
                                  "An error occurred while signing you in. Please check your connection and try again.");
                            } else {
                              _toHomePage(context);
                            }
                          }),
                        );
                      },
                    )),
              ],
            )
          ],
        )));
  }

  Future<void> _showDialog(String message) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Alert'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(message),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Okay'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
