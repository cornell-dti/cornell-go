import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:game/gameplay/gameplay_page.dart';
import 'package:game/journeys/journeys_page.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BottomNavBar extends StatefulWidget {
  const BottomNavBar({Key? key}) : super(key: key);

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  int _selectedIndex = 0;
  static const TextStyle optionStyle =
      TextStyle(fontSize: 30, fontWeight: FontWeight.bold);
  static const List<Widget> _widgetOptions = <Widget>[
    GameplayPage(),
    JourneysPage(),
    Text(
      'Profile',
      style: optionStyle,
    ),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
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
