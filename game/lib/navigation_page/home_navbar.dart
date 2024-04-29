import 'package:flutter/material.dart';
import 'package:game/journeys/journeys_page.dart';
import 'package:game/challenges/challenges_page.dart';

class HomeNavBar extends StatefulWidget {
  String? myDifficulty;
  List<String>? myLocations;
  List<String>? myCategories;
  String? mySearchText;
  HomeNavBar({
    Key? key,
    String? difficulty,
    List<String>? locations,
    List<String>? categories,
    String? searchText,
  }) : super(key: key) {
    myDifficulty = difficulty;
    myLocations = locations;
    myCategories = categories;
    mySearchText = searchText;
  }

  @override
  State<HomeNavBar> createState() => _HomeNavbarState();
}

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
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(50.0),
        child: AppBar(
          backgroundColor: Color(0xFFED5656),
          titleTextStyle: TextStyle(fontSize: 25, fontWeight: FontWeight.w500),
          bottom: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.yellow,
                  width: 2.0,
                ),
              ),
            ),
            overlayColor: MaterialStateProperty.resolveWith<Color?>(
              //transparent when clicked -- double check with designers
              (Set<MaterialState> states) {
                if (states.contains(MaterialState.pressed)) {
                  return Colors.transparent;
                }
                return null;
              },
            ),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.black.withOpacity(0.5),
            tabs: const <Widget>[
              Tab(text: 'Challenges'),
              Tab(text: 'Journeys'),
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
              searchText: widget.mySearchText,
            ),
          ),
          Center(
            child: JourneysPage(
              difficulty: widget.myDifficulty,
              categories: widget.myCategories,
              locations: widget.myLocations,
              searchText: widget.mySearchText,
            ),
          ),
        ],
      ),
    );
  }
}
