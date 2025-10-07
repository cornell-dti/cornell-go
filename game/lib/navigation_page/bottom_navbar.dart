import 'package:flutter/material.dart';
import 'package:game/api/game_api.dart';
import 'package:game/global_leaderboard/global_leaderboard_widget.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:game/profile/profile_page.dart';
import 'package:game/splash_page/splash_page.dart';
import 'package:game/utils/utility_functions.dart';
import 'package:provider/provider.dart';
import 'home_navbar.dart';
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
    SearchFilterBar(),           // Index 0: Home
    Container(),                 // Index 1: Create (empty for now)
    GlobalLeaderboardWidget(),   // Index 2: Leaderboard
    ProfilePage(),              // Index 3: Profile
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final client = Provider.of<ApiClient>(context);

    return Scaffold(
      body: Center(
        child: StreamBuilder(
            stream: client.clientApi.disconnectedStream,
            builder: (context, snapshot) {
              // Redirect to login if server api is null
              if (client.serverApi == null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  // Clear entire navigation stack and push to login screen
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => SplashPageWidget()),
                    (route) => false,
                  );
                  displayToast("Signed out", Status.success);
                });
              }
              // Returning the main content page abvoe the navbar [Home, Leaderboard, Profile]
              return _widgetOptions.elementAt(_selectedIndex);
            }),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: SvgPicture.asset("assets/icons/home.svg",
                colorFilter: ColorFilter.mode(Colors.grey, BlendMode.srcIn)),
            activeIcon: SvgPicture.asset("assets/icons/home.svg",
                colorFilter: ColorFilter.mode(Colors.black, BlendMode.srcIn)),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset("assets/icons/create.svg",
                colorFilter: ColorFilter.mode(Colors.grey, BlendMode.srcIn)),
            activeIcon: SvgPicture.asset("assets/icons/create.svg",
                colorFilter: ColorFilter.mode(Colors.black, BlendMode.srcIn)),
            label: 'Create',
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset("assets/icons/leaderboard.svg",
                colorFilter: ColorFilter.mode(Colors.grey, BlendMode.srcIn)),
            activeIcon: SvgPicture.asset("assets/icons/leaderboard.svg",
                colorFilter: ColorFilter.mode(Colors.black, BlendMode.srcIn)),
            label: 'Leaderboard',
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset("assets/icons/profilehead.svg",
                colorFilter: ColorFilter.mode(Colors.grey, BlendMode.srcIn)),
            activeIcon: SvgPicture.asset("assets/icons/profilehead.svg",
                colorFilter: ColorFilter.mode(Colors.black, BlendMode.srcIn)),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.black,
        onTap: _onItemTapped,
      ),
    );
  }
}
