import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:flutter/material.dart';
import 'package:game/gameplay/gameplay_page.dart';
import 'package:game/journeys/journeys_page.dart';
import 'package:game/challenges/challenges_page.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeNavBar extends StatefulWidget {
  const HomeNavBar({super.key});

  @override
  State<HomeNavBar> createState() => _HomeNavbarState();
}

/// AnimationControllers can be created with `vsync: this` because of TickerProviderStateMixin.
class _HomeNavbarState extends State<HomeNavBar> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: new PreferredSize(
        preferredSize: const Size.fromHeight(50.0),
        child: AppBar(
          backgroundColor: Color(0xFFED5656),
          titleTextStyle: TextStyle(fontSize: 25, fontWeight: FontWeight.w500),
          bottom: TabBar(
            dividerColor: Color.fromARGB(255, 0, 0, 0),
            indicatorColor: Color(0xFFFFFFFF),
            controller: _tabController,
            tabs: const <Widget>[
              Tab(text: 'Challenges'),
              Tab(
                text: 'Journeys',
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const <Widget>[
          Center(
            child: ChallengesPage(),
          ),
          Center(
            child: JourneysPage(),
          ),
        ],
      ),
    );
  }
}
