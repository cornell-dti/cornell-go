import 'package:flutter/material.dart';
import 'package:game/journeys/journeys_page.dart';
import 'package:game/challenges/challenges_page.dart';

/**
 * `HomeNavBar` Widget - Tab navigation system for Challenges and Journeys.
 * 
 * @remarks
 * This widget implements a tab controller to switch between Challenges and
 * Journeys views. It receives filter states from SearchFilterBar and passes
 * them to the appropriate tab content.
 * 
 * @param props - Contains:
 *   - `myDifficulty`: Selected difficulty filter
 *   - `myLocations`: List of selected location filters
 *   - `myCategories`: List of selected category filters
 *   - `mySearchText`: Current search query text
 */
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
      backgroundColor: Color(0xFFED5656),
      resizeToAvoidBottomInset: false,
      appBar: PreferredSize(
        preferredSize:
            Size.fromHeight(MediaQuery.sizeOf(context).height * 0.08),
        child: AppBar(
          elevation: 0.0,
          backgroundColor: Color(0xFFED5656),
          titleTextStyle: TextStyle(
              fontSize: MediaQuery.sizeOf(context).height * 0.03,
              fontWeight: FontWeight.w500),
          bottom: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Color(0xFFFFAA5B),
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
            tabs: <Widget>[
              Tab(
                child: Padding(
                  padding: EdgeInsets.only(
                      bottom: MediaQuery.sizeOf(context).height * 0.02),
                  child: Text(
                    'Challenges',
                    style: TextStyle(
                        fontSize: MediaQuery.sizeOf(context).height * 0.022,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              Tab(
                child: Padding(
                  padding: EdgeInsets.only(
                      bottom: MediaQuery.sizeOf(context).height * 0.02),
                  child: Text(
                    'Journeys',
                    style: TextStyle(
                        fontSize: MediaQuery.sizeOf(context).height * 0.022,
                        fontWeight: FontWeight.w600),
                  ),
                ),
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
