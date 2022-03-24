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

  void _toChooseUsername(context) {
    Navigator.pop(context);
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => UserNameWidget()));
  }

  @override
  Widget build(BuildContext context) {
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
                    padding: const EdgeInsets.only(bottom: 30),
                    child: Consumer2<ApiClient, UserModel>(
                      builder: (context, apiClient, userModel, child) {
                        // checkLoggedIn(apiClient);
                        return SignInButton(
                          Buttons.Google,
                          onPressed: () async {
                            final bool isAuth = await apiClient.connectGoogle();
                            if (!isAuth) {
                              _showDialog(
                                  "An error occurred while signing you in. Please check your connection and try again.");
                            } else {
                              Future.delayed(const Duration(milliseconds: 2000),
                                  () {
                                if (userModel.userData?.username == null) {
                                  print(userModel.userData?.username);
                                  _toChooseUsername(context);
                                } else {
                                  print(userModel.userData?.username);
                                  //navigate to home page
                                  _toHomePage(context);
                                }
                                return UserNameWidget();
                              });
                            }
                          },
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
