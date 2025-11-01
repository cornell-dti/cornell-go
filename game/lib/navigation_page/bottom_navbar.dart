import 'package:flutter/material.dart';
import 'package:game/api/game_api.dart';
import 'package:game/global_leaderboard/global_leaderboard_widget.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:game/profile/profile_page.dart';
import 'package:game/splash_page/splash_page.dart';
import 'package:provider/provider.dart';
import 'package:game/model/onboarding_model.dart';
import 'package:game/widgets/bear_mascot_message.dart';
import 'package:game/utils/utility_functions.dart';
import 'search_filter_home.dart';

/** 

* BottomNavBar Widget - Main navigation container for the app.
*
* A stateful widget that manages the primary navigation interface and handles
* authentication state for the main app flow.
*
* @remarks
* This widget serves as the root container for the main app interface, managing:
* - Navigation between main app sections (Home, Leaderboard, Profile)
* - Authentication state monitoring via disconnection stream
* - Automatic redirection to login when authentication is lost
* - Consistent bottom navigation bar UI across all main sections
*
* The widget uses Provider pattern to access the ApiClient and manages its own
* state for the selected navigation index.
*
* @example
* ```dart
* Navigator.pushReplacement(
*   context,
*   MaterialPageRoute(builder: (context) => BottomNavBar()),
* );
* ```
*
* @param key - Optional widget key for identification and testing.
*
* @returns A StatefulWidget that renders the main navigation interface with
* bottom navigation bar and handles authentication state.

*/

class BottomNavBar extends StatefulWidget {
  const BottomNavBar({Key? key}) : super(key: key);

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  int _selectedIndex = 0;
  static const TextStyle optionStyle =
      TextStyle(fontSize: 30, fontWeight: FontWeight.bold);
  static List<Widget> _widgetOptions = <Widget>[
    SearchFilterBar(),
    GlobalLeaderboardWidget(),
    ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    // TODO: Later load user.hasCompletedOnboarding from backend database here
  }

  @override
  Widget build(BuildContext context) {
    final client = Provider.of<ApiClient>(context);
    final onboarding = Provider.of<OnboardingModel>(
        context); // listen: true (default) so we rebuild on step completion

    // Percentage-based positioning for onboarding (from Figma design 393x852)
    const double bearLeftPercent = 0.02;
    const double bearBottomPercent = 0.08;
    const double messageLeftPercent = 0.62;
    const double messageBottomPercent = 0.31;
    return Stack(
      children: [
        // LAYER 1: Main app UI (Scaffold with content + bottom navbar)
        Scaffold(
            body: Center(
              child: StreamBuilder(
                  stream: client.clientApi.disconnectedStream,
                  builder: (context, snapshot) {
                    // Redirect to login if server api is null
                    if (client.serverApi == null) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        // Clear entire navigation stack and push to login screen
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                              builder: (context) => SplashPageWidget()),
                          (route) => false,
                        );
                        displayToast("Signed out", Status.success);
                      });
                    }
                    // Returning the main content page above the navbar [Home, Leaderboard, Profile]
                    return _widgetOptions.elementAt(_selectedIndex);
                  }),
            ),
            bottomNavigationBar: BottomNavigationBar(
              items: [
                BottomNavigationBarItem(
                  icon: SvgPicture.asset("assets/icons/home.svg",
                      colorFilter:
                          ColorFilter.mode(Colors.grey, BlendMode.srcIn)),
                  activeIcon: SvgPicture.asset("assets/icons/home.svg",
                      colorFilter:
                          ColorFilter.mode(Colors.black, BlendMode.srcIn)),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: SvgPicture.asset("assets/icons/leaderboard.svg",
                      colorFilter:
                          ColorFilter.mode(Colors.grey, BlendMode.srcIn)),
                  activeIcon: SvgPicture.asset("assets/icons/leaderboard.svg",
                      colorFilter:
                          ColorFilter.mode(Colors.black, BlendMode.srcIn)),
                  label: 'Leaderboard',
                ),
                BottomNavigationBarItem(
                  icon: SvgPicture.asset("assets/icons/profilehead.svg",
                      colorFilter:
                          ColorFilter.mode(Colors.grey, BlendMode.srcIn)),
                  activeIcon: SvgPicture.asset("assets/icons/profilehead.svg",
                      colorFilter:
                          ColorFilter.mode(Colors.black, BlendMode.srcIn)),
                  label: 'Profile',
                ),
              ],
              currentIndex: _selectedIndex,
              selectedItemColor: Colors.black,
              onTap: _onItemTapped,
            )),

        // LAYER 2: Step 0 - Welcome onboarding overlay (manual, no ShowcaseView)
        if (!onboarding.step0WelcomeComplete)
          GestureDetector(
            onTap: () {
              print('👆 Step 0: Dismissing welcome overlay');
              onboarding
                  .completeStep0(); // Triggers notifyListeners → ChallengesPage Consumer rebuilds
            },
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black.withOpacity(0.75), // Dimming overlay
              child: BearMascotMessage(
                message:
                    'Welcome to CornellGo! Explore campus through interactive scavenger hunts. Play solo or with friends while discovering hidden spots and Cornell traditions!',
                showBear: true,
                bearAsset: 'standing',
                bearLeftPercent: 0.02,
                bearBottomPercent: 0.08,
                messageLeftPercent: 0.62,
                messageBottomPercent: 0.31,
              ),
            ),
          ),

        // LAYER 3: Step 3 - Journeys explanation overlay (full-screen dimmed)
        if (onboarding.step2JourneysComplete &&
            !onboarding.step3JourneysExplanationComplete)
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black.withOpacity(0.75),
            child: BearMascotMessage(
              message:
                  'A Journey is a series of connected challenges built around a theme. Think of it as a longer adventure where you complete multiple Challenges to unlock the full story.',
              showBear: true,
              bearAsset: 'popup',
              bearLeftPercent: -0.095,
              bearBottomPercent: 0.08,
              messageLeftPercent: 0.56,
              messageBottomPercent: 0.31,
              onTap: () {
                print("Step 3: Journeys explanation dismissed");
                onboarding.completeStep3();
              },
            ),
          ),
      ],
    );
  }
}
