import 'package:flutter/material.dart';
import 'package:game/journeys/journeys_page.dart';
import 'package:game/challenges/challenges_page.dart';

class HomeNavBar extends StatefulWidget {
  String? myDifficulty;
  List<String>? myLocations;
  List<String>? myCategories;
  String? mySearchText;
  HomeNavBar(
      {Key? key,
      String? difficulty,
      List<String>? locations,
      List<String>? categories,
      String? searchText})
      : super(key: key) {
    myDifficulty = difficulty;
    myLocations = locations;
    myCategories = categories;
    mySearchText = searchText;
  }

  @override
  State<HomeNavBar> createState() =>
      _HomeNavbarState(myDifficulty, myLocations, myCategories, mySearchText);
}

/// AnimationControllers can be created with `vsync: this` because of TickerProviderStateMixin.
class _HomeNavbarState extends State<HomeNavBar> with TickerProviderStateMixin {
  late TabController _tabController;
  List<String> selectedCategories = [];
  List<String> selectedLocations = [];
  String? selectedDifficulty = '';
  String? mySearchText;
  _HomeNavbarState(String? difficulty, List<String>? locations,
      List<String>? categories, String? searchText) {
    selectedDifficulty = difficulty ?? '';
    selectedLocations = locations ?? [];
    selectedCategories = categories ?? [];
    mySearchText = searchText ?? '';
  }

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
        children: <Widget>[
          Center(
              child: ChallengesPage(
                  difficulty: widget.myDifficulty,
                  categories: widget.myCategories,
                  locations: widget.myLocations,
                  searchText: widget.mySearchText)),
          Center(
            child: JourneysPage(),
          ),
        ],
      ),
    );
  }
}
