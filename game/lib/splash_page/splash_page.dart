import 'package:flutter/material.dart';
import 'package:game/api/game_client_dto.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:game/api/game_api.dart';
import 'package:game/utils/utility_functions.dart';
import 'package:game/register_page/register_page.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:game/navigation_page/bottom_navbar.dart';

class SplashPageWidget extends StatelessWidget {
  SplashPageWidget({Key? key}) : super(key: key);
  final scaffoldKey = GlobalKey<ScaffoldState>();
  @override
  Widget build(BuildContext context) {
    final client = Provider.of<ApiClient>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            left: -5,
            top: -5,
            child: SvgPicture.asset(
              'assets/images/splash.svg',
              width: MediaQuery.of(context).size.width + 10,
            ),
          ),
          Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                StreamBuilder(
                    stream: client.clientApi.connectedStream,
                    builder: (context, snapshot) {
                      if (client.serverApi != null) {
                        print("ServerApi != null");
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => BottomNavBar()));
                          displayToast("Signed in!", Status.success);
                        });
                      }

                      return Container();
                    }),
                Consumer<ApiClient>(
                  builder: (context, apiClient, child) {
                    return TextButton(
                      style: ButtonStyle(
                          backgroundColor:
                              MaterialStatePropertyAll<Color>(Colors.white),
                          fixedSize:
                              MaterialStatePropertyAll<Size>(Size(250, 50)),
                          shape: MaterialStatePropertyAll<OutlinedBorder>(
                              RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0)))),
                      onPressed: () async {
                        final GoogleSignInAccount? account =
                            await apiClient.signinGoogle();

                        if (account == null) {
                          displayToast(
                              "An error occured while signing you into Google!",
                              Status.error);
                          return;
                        }

                        if (!account.email.contains("@cornell.edu")) {
                          displayToast(
                              "Only Cornell-affiliated users may use Google Sign-in!",
                              Status.error);
                          return;
                        }

                        final gRelogResult =
                            await apiClient.connectGoogleNoRegister(account);

                        if (gRelogResult != null) {
                          return;
                        }

                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => RegisterPageWidget(
                                user: account, idToken: null),
                          ),
                        );
                      },
                      child: Container(
                        width: 255,
                        height: 50,
                        child: Align(
                          alignment: Alignment.center,
                          child: Text("Cornell Login",
                              style: TextStyle(
                                  color: Color.fromARGB(255, 93, 100, 112),
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500)),
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: 16),
                Row(children: <Widget>[
                  SizedBox(width: 69),
                  Expanded(
                      child: Divider(
                    color: Colors.white,
                  )),
                  SizedBox(width: 8),
                  LatoText("OR", 14.0, Colors.white, FontWeight.w600),
                  SizedBox(width: 8),
                  Expanded(child: Divider(color: Colors.white)),
                  SizedBox(width: 69),
                ]),
                SizedBox(height: 16),
                TextButton(
                    style: ButtonStyle(
                        backgroundColor:
                            MaterialStatePropertyAll<Color>(Colors.white),
                        fixedSize:
                            MaterialStatePropertyAll<Size>(Size(250, 50)),
                        shape: MaterialStatePropertyAll<OutlinedBorder>(
                            RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0)))),
                    onPressed: () async {
                      final connectionResult = await client.connectDevice(
                          "", LoginEnrollmentTypeDto.GUEST, "", "", "", []);

                      if (connectionResult == null) {
                        displayToast("An error occurred while signing you up!",
                            Status.error);
                      }
                    },
                    child: Container(
                      width: 255,
                      height: 53,
                      child: Align(
                        alignment: Alignment.center,
                        child: Text("Continue as Guest",
                            style: TextStyle(
                                color: Color.fromARGB(255, 93, 100, 112),
                                fontSize: 20,
                                fontWeight: FontWeight.w500)),
                      ),
                    )),
                SizedBox(height: 80),
              ]),
        ],
      ),
    );
  }
}
