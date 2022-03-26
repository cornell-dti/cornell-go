import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:game/api/game_api.dart';
import 'package:game/home_page/home_page_widget.dart';
import 'package:provider/provider.dart';
import 'package:game/utils/utility_functions.dart';

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
  TextEditingController idController = new TextEditingController();

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
                              displayToast(
                                  "An error occured while signing you up.",
                                  Status.error);
                            } else {
                              _toHomePage(context);
                            }
                          }),
                        );
                      },
                    )),
                TextButton(
                    child: Text("Use Test ID"),
                    onPressed: () {
                      _displayTextInputDialog(context);
                    })
              ],
            )
          ],
        )));
  }

  Future<void> _displayTextInputDialog(BuildContext context) async {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('ID Sign In'),
            content: TextField(
              controller: idController,
              decoration: InputDecoration(hintText: "Input ID here"),
            ),
            actions: <Widget>[
              TextButton(
                child: Text('CANCEL'),
                onPressed: () {
                  setState(() {
                    Navigator.pop(context);
                  });
                },
              ),
              Consumer<ApiClient>(
                builder: (context, apiClient, child) {
                  // checkLoggedIn(apiClient);
                  return TextButton(
                    child: Text('OK'),
                    onPressed: () async {
                      final bool isAuth =
                          await apiClient.connectId(idController.text);
                      if (!isAuth) {
                        showAlert(
                            "An error occurred while signing you in. Please check your connection and try again.",
                            context);
                      } else {
                        _toHomePage(context);
                      }
                    },
                  );
                },
              )
            ],
          );
        });
  }
}
