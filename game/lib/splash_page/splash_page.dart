import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:game/api/game_api.dart';
import 'package:game/utils/utility_functions.dart';
import 'package:game/register_page/register_page.dart';

class SplashPageWidget extends StatelessWidget {
  SplashPageWidget({Key? key}) : super(key: key);
  final scaffoldKey = GlobalKey<ScaffoldState>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            left: 0,
            top: -50,
            height: 200,
            width: 200,
            child: Container(
                height: 200,
                width: 200,
                decoration: BoxDecoration(
                    image: DecorationImage(
                        image: AssetImage("assets/images/splash_top.png")))),
          ),
          Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                LatoText("CornellGo", 60.0, Colors.black, FontWeight.w700),
                SizedBox(height: 75),
                LatoText(
                    "Login to CornellGo", 20.0, Colors.black, FontWeight.w600),
                SizedBox(height: 32.5),
                Consumer<ApiClient>(
                  builder: (context, apiClient, child) {
                    return ElevatedButton(
                      style: ButtonStyle(
                          backgroundColor:
                              MaterialStatePropertyAll<Color>(Colors.white)),
                      onPressed: () async {
                        final GoogleSignInAccount? account =
                            await apiClient.connectGoogle();
                        if (account == null) {
                          displayToast("An error occured while signing you up.",
                              Status.error);
                        } else {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => RegisterPageWidget(
                                  user: account, idToken: null),
                            ),
                          );
                        }
                      },
                      child: Container(
                        width: 255,
                        height: 50,
                        child: Align(
                          alignment: Alignment.center,
                          child: LatoText("Continue with Google", 16.0,
                              Colors.black, FontWeight.w600),
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: 16),
                Row(children: <Widget>[
                  SizedBox(width: 69),
                  Expanded(child: Divider()),
                  SizedBox(width: 8),
                  LatoText("OR", 14.0, Colors.black, FontWeight.w600),
                  SizedBox(width: 8),
                  Expanded(child: Divider()),
                  SizedBox(width: 69),
                ]),
                SizedBox(height: 16),
                ElevatedButton(
                    style: ButtonStyle(
                        backgroundColor:
                            MaterialStatePropertyAll<Color>(Colors.white)),
                    onPressed: () async {
                      final String? id = await getId();
                      print("GOT ID");
                      print(id);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              RegisterPageWidget(user: null, idToken: id),
                        ),
                      );
                    },
                    child: Container(
                      width: 255,
                      height: 53,
                      child: Align(
                        alignment: Alignment.center,
                        child: LatoText("Continue as guest", 16.0, Colors.black,
                            FontWeight.w600),
                      ),
                    ))
              ]),
          Positioned(
            right: 0,
            bottom: -60,
            height: 200,
            width: 200,
            child: Container(
                height: 200,
                width: 200,
                decoration: BoxDecoration(
                    image: DecorationImage(
                        image: AssetImage("assets/images/splash_bottom.png")))),
          )
        ],
      ),
    );
  }
}
