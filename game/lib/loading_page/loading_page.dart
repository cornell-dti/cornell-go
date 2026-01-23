import 'package:flutter/material.dart';
import 'package:game/navigation_page/bottom_navbar.dart';
import 'package:game/splash_page/splash_page.dart';

/**
 * `LoadingPageWidget` - Displays a loading screen while awaiting the result of a re-login attempt
 * and redirects the user based on the result.
 * 
 * @remarks
 * This widget is used to show a loading indicator while the app awaits the result of a re-login attempt.
 * Once the result is available, it navigates to the appropriate screen:
 * - If the re-login is successful, the user is redirected to the main app page.
 * - If the re-login fails, the user is redirected to the splash screen.
 * The widget ensures that any necessary updates, such as notifying listeners, are completed before navigating.
 * 
 * @param relogResult - The [Future<bool>] representing the result of the re-login operation.
 *   - `true`: If the re-login attempt is successful, the user is redirected to the main page.
 *   - `false`: If the re-login attempt fails, the user is redirected to the splash screen.
 */
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
                    builder: (context) =>
                        snapshot.data! ? BottomNavBar() : SplashPageWidget(),
                  ),
                );
              });
            }

            return CircularProgressIndicator();
          },
        ),
      ),
    );
  }
}
