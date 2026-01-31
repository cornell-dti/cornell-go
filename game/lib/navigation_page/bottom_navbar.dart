import 'package:flutter/material.dart';
import 'package:game/api/game_api.dart';
import 'package:game/global_leaderboard/global_leaderboard_widget.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:game/profile/profile_page.dart';
import 'package:game/splash_page/splash_page.dart';
import 'package:provider/provider.dart';
import 'package:game/model/onboarding_model.dart';
import 'package:game/model/user_model.dart';
import 'package:game/model/event_model.dart';
import 'package:game/model/tracker_model.dart';
import 'package:game/model/challenge_model.dart';
import 'package:game/widgets/bear_mascot_message.dart';
import 'package:game/utils/utility_functions.dart';
import 'package:showcaseview/showcaseview.dart';
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
  bool _hasTriggeredStep11 = false; // Prevent multiple showcase triggers
  bool _hasTriggeredStep12 = false; // Prevent multiple showcase triggers
  OverlayEntry? _bearOverlayEntry;
  static const TextStyle optionStyle = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.bold,
  );
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
  }

  @override
  void dispose() {
    _removeBearOverlay();
    super.dispose();
  }

  // -- Bear Onboarding Overlays --

  void _showProfileBearOverlay() {
    _removeBearOverlay(); // Remove existing if any

    _bearOverlayEntry = OverlayEntry(
      builder: (context) => BearMascotMessage(
        message:
            'Welcome to your Profile where you can track your Challenges, Journeys, and Achievements as a record of your exploration across campus.',
        showBear: true,
        bearAsset: 'standing',
        bearLeftPercent: -0.02,
        bearBottomPercent: 0.12,
        messageLeftPercent: 0.6,
        messageBottomPercent: 0.35,
        onTap: () {
          print("Tapped anywhere on step 11");
          _removeBearOverlay();
          ShowcaseView.getNamed("bottom_navbar_profile").dismiss();
          Provider.of<OnboardingModel>(
            context,
            listen: false,
          ).completeStep11();
        },
      ),
    );

    Overlay.of(context).insert(_bearOverlayEntry!);
  }

  void _showLeaderboardBearOverlay() {
    _removeBearOverlay(); // Remove existing if any

    _bearOverlayEntry = OverlayEntry(
      builder: (context) => BearMascotMessage(
        message:
            'See how you stack up against other CornellGo players. The more Challenges and Journeys you complete, the higher your score!',
        showBear: true,
        bearAsset: 'popup',
        bearLeftPercent: -0.095,
        bearBottomPercent: 0.2,
        messageLeftPercent: 0.55,
        messageBottomPercent: 0.42,
        onTap: () {
          print("Tapped anywhere on step 12");
          _removeBearOverlay();
          ShowcaseView.getNamed("bottom_navbar_leaderboard").dismiss();
          Provider.of<OnboardingModel>(
            context,
            listen: false,
          ).completeStep12();
        },
      ),
    );

    Overlay.of(context).insert(_bearOverlayEntry!);
  }

  void _removeBearOverlay() {
    _bearOverlayEntry?.remove();
    _bearOverlayEntry = null;
  }

  // -- Tab with optional onboarding showcases --

  BottomNavigationBarItem _buildProfileTab(
    OnboardingModel onboarding,
    double screenWidth,
    double screenHeight,
  ) {
    // Step 11: Wrap icon + label with showcase if onboarding active
    // Note: Profile tab is always active during this showcase (we navigate to it)
    if (onboarding.step10HintButtonComplete &&
        !onboarding.step11ProfileTabComplete) {
      final showcasedWidget = Showcase(
        key: onboarding.step11ProfileTabKey,
        title: '',
        description: '',
        tooltipBackgroundColor: Colors.transparent,
        disableMovingAnimation: true,
        targetShapeBorder: CircleBorder(),
        targetPadding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.055, // ~30px on 393px screen
          vertical: screenHeight * 0.02, // ~30px on 852px screen
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              "assets/icons/profilehead.svg",
              colorFilter: ColorFilter.mode(Colors.black, BlendMode.srcIn),
            ), // Active
            SizedBox(height: 2),
            Text(
              'Profile',
              style: TextStyle(fontSize: 12, color: Colors.black),
            ), // Active
          ],
        ),
      );

      return BottomNavigationBarItem(
        icon: showcasedWidget,
        activeIcon: showcasedWidget, // Use same widget for active state!
        label: '', // Empty to avoid duplicate text
      );
    }

    // Normal tab when not in onboarding
    final profileIcon = SvgPicture.asset(
      "assets/icons/profilehead.svg",
      colorFilter: ColorFilter.mode(Colors.grey, BlendMode.srcIn),
    );

    return BottomNavigationBarItem(
      icon: profileIcon,
      activeIcon: SvgPicture.asset(
        "assets/icons/profilehead.svg",
        colorFilter: ColorFilter.mode(Colors.black, BlendMode.srcIn),
      ),
      label: 'Profile',
    );
  }

  BottomNavigationBarItem _buildLeaderboardTab(
    OnboardingModel onboarding,
    double screenWidth,
    double screenHeight,
  ) {
    // Step 12: Wrap icon + label with showcase if onboarding active
    // Note: Leaderboard tab is always active during this showcase (we navigate to it)
    if (onboarding.step11ProfileTabComplete &&
        !onboarding.step12LeaderboardTabComplete) {
      final showcasedWidget = Showcase(
        key: onboarding.step12LeaderboardTabKey,
        title: '',
        description: '',
        tooltipBackgroundColor: Colors.transparent,
        disableMovingAnimation: true,
        targetShapeBorder: CircleBorder(),
        targetPadding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.055, // Same as Profile
          vertical: screenHeight * 0.04, // Same as Profile
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              "assets/icons/leaderboard.svg",
              colorFilter: ColorFilter.mode(Colors.black, BlendMode.srcIn),
            ), // Active
            SizedBox(height: 2),
            Text(
              'Leaderboard',
              style: TextStyle(fontSize: 12, color: Colors.black),
            ), // Active
          ],
        ),
      );

      return BottomNavigationBarItem(
        icon: showcasedWidget,
        activeIcon: showcasedWidget, // Use same widget for active state!
        label: '', // Empty to avoid duplicate text
      );
    }

    // Normal tab when not in onboarding
    final leaderboardIcon = SvgPicture.asset(
      "assets/icons/leaderboard.svg",
      colorFilter: ColorFilter.mode(Colors.grey, BlendMode.srcIn),
    );

    return BottomNavigationBarItem(
      icon: leaderboardIcon,
      activeIcon: SvgPicture.asset(
        "assets/icons/leaderboard.svg",
        colorFilter: ColorFilter.mode(Colors.black, BlendMode.srcIn),
      ),
      label: 'Leaderboard',
    );
  }

  // -- Main BottomNavBar Widget --

  @override
  Widget build(BuildContext context) {
    final client = Provider.of<ApiClient>(context);
    final onboarding = Provider.of<OnboardingModel>(
      context,
    ); // listen: true (default) so we rebuild on step completion
    final userModel = Provider.of<UserModel>(context);
    final eventModel = Provider.of<EventModel>(context);
    final trackerModel = Provider.of<TrackerModel>(context);
    final challengeModel = Provider.of<ChallengeModel>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Step 11: Auto-select Profile tab and start showcase (trigger once)
    if (onboarding.step10HintButtonComplete &&
        !onboarding.step11ProfileTabComplete &&
        !_hasTriggeredStep11) {
      _hasTriggeredStep11 = true; // Prevent re-triggering on rebuild
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // Register showcase for step 11
          try {
            ShowcaseView.getNamed("bottom_navbar_profile").unregister();
          } catch (e) {}
          ShowcaseView.register(
            scope: "bottom_navbar_profile",
            onFinish: () {
              Provider.of<OnboardingModel>(
                context,
                listen: false,
              ).completeStep11();
            },
          );
          // Switch to Profile tab
          setState(() {
            _selectedIndex = 2;
          });
          // Start showcase to highlight Profile icon
          ShowcaseView.getNamed(
            "bottom_navbar_profile",
          ).startShowCase([onboarding.step11ProfileTabKey]);
          // Show bear overlay on top of showcase
          _showProfileBearOverlay();
        }
      });
    }

    // Step 12: Auto-select Leaderboard tab and start showcase (trigger once)
    if (onboarding.step11ProfileTabComplete &&
        !onboarding.step12LeaderboardTabComplete &&
        !_hasTriggeredStep12) {
      _hasTriggeredStep12 = true; // Prevent re-triggering on rebuild
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // Register showcase for step 12
          try {
            ShowcaseView.getNamed("bottom_navbar_leaderboard").unregister();
          } catch (e) {}
          ShowcaseView.register(
            scope: "bottom_navbar_leaderboard",
            onFinish: () {
              Provider.of<OnboardingModel>(
                context,
                listen: false,
              ).completeStep12();
            },
          );
          // Switch to Leaderboard tab
          setState(() {
            _selectedIndex = 1;
          });
          // Start showcase to highlight Leaderboard icon
          ShowcaseView.getNamed(
            "bottom_navbar_leaderboard",
          ).startShowCase([onboarding.step12LeaderboardTabKey]);
          // Show bear overlay on top of showcase
          _showLeaderboardBearOverlay();
        }
      });
    }

    // Step 13: Navigate back to Home for final overlay
    if (onboarding.step12LeaderboardTabComplete &&
        !onboarding.step13FinalComplete &&
        _selectedIndex != 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _selectedIndex = 0; // Navigate to Home
          });
        }
      });
    }

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
                        builder: (context) => SplashPageWidget(),
                      ),
                      (route) => false,
                    );
                    displayToast("Signed out", Status.success);
                  });
                }
                // Returning the main content page above the navbar [Home, Leaderboard, Profile]
                return _widgetOptions.elementAt(_selectedIndex);
              },
            ),
          ),
          bottomNavigationBar: BottomNavigationBar(
            items: [
              BottomNavigationBarItem(
                icon: SvgPicture.asset(
                  "assets/icons/home.svg",
                  colorFilter: ColorFilter.mode(Colors.grey, BlendMode.srcIn),
                ),
                activeIcon: SvgPicture.asset(
                  "assets/icons/home.svg",
                  colorFilter: ColorFilter.mode(Colors.black, BlendMode.srcIn),
                ),
                label: 'Home',
              ),
              _buildLeaderboardTab(onboarding, screenWidth, screenHeight),
              _buildProfileTab(onboarding, screenWidth, screenHeight),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: Colors.black,
            onTap: _onItemTapped,
          ),
        ),

        // LAYER 2: Step 0 - Welcome onboarding overlay (manual, no ShowcaseView)
        // Wait for backend response before showing onboarding
        if (!onboarding.isLoadingFromBackend &&
            !onboarding.step0WelcomeComplete &&
            onboarding.canStartOnboarding(
                userModel, eventModel, trackerModel, challengeModel))
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

        // LAYER 4: Step 13 - Final goodbye overlay (full-screen dimmed)
        if (onboarding.step12LeaderboardTabComplete &&
            !onboarding.step13FinalComplete)
          GestureDetector(
            onTap: () {
              print('🎉 Step 13: Onboarding complete!');
              onboarding.completeStep13();
            },
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black.withOpacity(0.75),
              child: BearMascotMessage(
                message:
                    'That\'s it! Start exploring, earn points, and see how many locations you can uncover.',
                showBear: true,
                bearAsset: 'standing',
                bearLeftPercent: 0.02,
                bearBottomPercent: 0.08,
                messageLeftPercent: 0.62,
                messageBottomPercent: 0.31,
              ),
            ),
          ),
      ],
    );
  }
}
