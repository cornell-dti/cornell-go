import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:game/api/game_api.dart';
import 'package:permission_handler/permission_handler.dart';

class LoginWidget extends StatefulWidget {
  final FlutterSecureStorage storage;
  final String API_URL;
  LoginWidget({Key? key, required this.storage, required this.API_URL})
      : super(key: key);

  @override
  _LoginWidgetState createState() => _LoginWidgetState();
}

class _LoginWidgetState extends State<LoginWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    print(widget.API_URL);
    print(widget.storage);
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
                  child: SignInButton(
                    Buttons.Google,
                    onPressed: () async {
                      final client = ApiClient(widget.storage, widget.API_URL);
                      final isAuth = await client.connectGoogle();
                      print(isAuth);
                    },
                  ),
                )
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
