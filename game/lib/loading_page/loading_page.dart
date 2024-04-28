import 'package:flutter/material.dart';
import 'package:game/api/game_api.dart';
import 'package:game/navigation_page/bottom_navbar.dart';
import 'package:game/splash_page/splash_page.dart';
import 'package:provider/provider.dart';

class LoadingPageWidget extends StatelessWidget {
  final Future<bool> relogResult;
  LoadingPageWidget(this.relogResult, {Key? key}) : super(key: key);
  final scaffoldKey = GlobalKey<ScaffoldState>();

  Future<bool> awaitRelogResult() async {
    final result = await relogResult;
    // Wait, so we can allow the serverApi to notifyListeners() first
    await Future.delayed(Durations.medium1);
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: StreamBuilder(
            stream: Stream.fromFuture(awaitRelogResult()),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => snapshot.data!
                              ? BottomNavBar()
                              : SplashPageWidget()));
                });
              }

              return CircularProgressIndicator();
            },
          ),
        ));
  }
}
