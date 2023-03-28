import 'package:flutter/material.dart';
import 'package:game/widget/lato_text.dart';

class SplashPageWidget extends StatelessWidget {
  SplashPageWidget({Key? key}) : super(key: key);
  final scaffoldKey = GlobalKey<ScaffoldState>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              LatoText("CornellGo", 60.0, Colors.black, FontWeight.w700),
              SizedBox(height: 75),
              LatoText(
                  "Login to CornellGo", 20.0, Colors.black, FontWeight.w600),
              SizedBox(height: 32.5),
              ElevatedButton(
                  style: ButtonStyle(
                      backgroundColor:
                          MaterialStatePropertyAll<Color>(Colors.white)),
                  onPressed: () => {print("pressed")},
                  child: Container(
                    width: 255,
                    height: 53,
                    child: Align(
                      alignment: Alignment.center,
                      child: LatoText("Continue with Google", 16.0,
                          Colors.black, FontWeight.w600),
                    ),
                  )),
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
                  onPressed: () => {print("pressed")},
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
      ),
    );
  }
}
