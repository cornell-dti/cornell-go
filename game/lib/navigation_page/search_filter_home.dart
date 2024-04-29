import 'package:flutter/material.dart';
import 'package:game/journeys/journeys_page.dart';
import 'package:game/challenges/challenges_page.dart';
import 'package:game/journeys/filter_form.dart';
import 'package:game/navigation_page/home_navbar.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SearchFilterBar extends StatefulWidget {
  String? myDifficulty;
  List<String>? myLocations;
  List<String>? myCategories;
  String? mySearchText;

  // SearchFilterBar({Key? key}):{super(key:key};
  SearchFilterBar({Key? key}) : super(key: key);

  @override
  State<SearchFilterBar> createState() => _SearchFilterBarState();
}

/// AnimationControllers can be created with `vsync: this` because of TickerProviderStateMixin.
class _SearchFilterBarState extends State<SearchFilterBar>
    with TickerProviderStateMixin {
  List<String> selectedCategories = [];
  List<String> selectedLocations = [];
  String selectedDifficulty = '';
  String searchText = '';

  // Callback function to receive updated state values from the child
  void handleFilterSubmit(List<String>? a, List<String>? b, String c) {
    setState(() {
      selectedCategories = a ?? [];
      selectedLocations = b ?? [];
      selectedDifficulty = c;
    });
    // HomeNavBar.setState()
  }

  void onSearchTextChanged(String? c) {
    setState(() {
      searchText = c ?? "";
    });
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Color(0xFFED5656),
        width: double.infinity,
        height: double.infinity,
        child: Padding(
          padding: EdgeInsets.fromLTRB(0, 50, 0, 0),
          child: Column(
            children: [
              Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Color.fromARGB(255, 255, 248, 241),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: SizedBox(
                      width: 345,
                      height: 45,
                      child: TextField(
                        onSubmitted: onSearchTextChanged,
                        decoration: InputDecoration(
                          prefixIcon: Icon(
                            Icons.search,
                            color: Color.fromARGB(76, 0, 0, 0),
                            size: 20,
                          ),
                          labelText: "Search a name, location, etc...",
                          labelStyle: TextStyle(
                            color: Color(0xFFB9B9B9),
                            fontSize: 12,
                            fontFamily: 'Poppins',
                            backgroundColor: Color.fromARGB(255, 255, 248, 241),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 50,
                      height: 36,
                      child: IconButton(
                        icon: SvgPicture.asset(
                          'assets/icons/Group 578.svg',
                        ),
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            builder: (context) => FilterForm(
                              onSubmit: handleFilterSubmit,
                              difficulty: selectedDifficulty,
                              locations: selectedLocations,
                              categories: selectedCategories,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  Container(
                    height: 628,
                    child: HomeNavBar(
                      difficulty: selectedDifficulty,
                      locations: selectedLocations,
                      categories: selectedCategories,
                      searchText: searchText,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
