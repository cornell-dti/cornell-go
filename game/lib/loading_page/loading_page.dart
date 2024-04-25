import 'package:flutter/material.dart';
import 'package:game/api/game_api.dart';
import 'package:game/navigation_page/bottom_navbar.dart';
import 'package:game/splash_page/splash_page.dart';
import 'package:provider/provider.dart';

class LoadingPageWidget extends StatelessWidget {
  LoadingPageWidget({Key? key}) : super(key: key);
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    ApiClient client = Provider.of<ApiClient>(context);
    Future<bool> relogResult = client.tryRelog();

    return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: StreamBuilder(
            stream: Stream.fromFuture(relogResult),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => snapshot.data!
                              ? BottomNavBar()
                              : SplashPageWidget()));
                  ;
                });
              }

              return SplashPageWidget();
            },
          ),
        ));
  }
}
