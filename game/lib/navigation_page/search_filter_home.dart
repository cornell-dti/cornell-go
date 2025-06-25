import 'dart:io';

import 'package:flutter/material.dart';
import 'package:game/journeys/journeys_page.dart';
import 'package:game/challenges/challenges_page.dart';
import 'package:game/journeys/filter_form.dart';
import 'package:game/navigation_page/home_navbar.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';

/**
 * `SearchFilterBar` Widget - Main container for home screen search and filtering.
 * 
 * @remarks
 * This stateful widget serves as the top-level component for the home screen,
 * managing search functionality and filter states. It contains the search bar
 * and filter button, passing filter states down to child components.
 * 
 * @param state - Contains:
 *   - `selectedCategories`: List of selected category filters
 *   - `selectedLocations`: List of selected location filters
 *   - `selectedDifficulty`: Selected difficulty level
 *   - `searchText`: Current search query
 */

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
    double deviceWidth = MediaQuery.sizeOf(context).width;
    double deviceHeight = MediaQuery.sizeOf(context).height;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        color: Color(0xFFED5656),
        child: SafeArea(
          child: Column(
            children: [
              // Search bar section
              Padding(
                padding: EdgeInsets.only(
                    top: Platform.isIOS
                        ? deviceHeight * 0.01
                        : MediaQuery.of(context).padding.top +
                            deviceHeight * 0.01, // Android padding
                    bottom: deviceHeight * 0.01),
                child: Stack(
                  children: [
                    SingleChildScrollView(
                      physics: NeverScrollableScrollPhysics(),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Color.fromARGB(255, 255, 248, 241),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: SizedBox(
                          width: deviceWidth * 0.9,
                          height: deviceHeight * 0.055,
                          child: TextField(
                            onSubmitted: onSearchTextChanged,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              prefixIcon: Icon(
                                Icons.search,
                                color: Color.fromARGB(76, 0, 0, 0),
                                size: 20,
                              ),
                              labelText: "Search a name, location, etc...",
                              labelStyle: TextStyle(
                                // color: Color(0xFFB9B9B9),
                                fontSize: 12,
                                fontFamily: 'Poppins',
                                // backgroundColor:
                                //     Color.fromARGB(255, 255, 248, 241),
                              ),
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
                        child: Stack(
                          children: [
                            IconButton(
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
                            if ((selectedCategories.length +
                                    selectedLocations.length +
                                    (selectedDifficulty.isNotEmpty ? 1 : 0)) >
                                0)
                              Positioned(
                                top: 4,
                                right: 4,
                                child: Container(
                                  padding: EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: BoxConstraints(
                                    minWidth: 20,
                                    minHeight: 20,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${selectedCategories.length + selectedLocations.length + (selectedDifficulty.isNotEmpty ? 1 : 0)}',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
              // HomeNavBar section - use Expanded instead of fixed height Container
              Expanded(
                child: HomeNavBar(
                  difficulty: selectedDifficulty,
                  locations: selectedLocations,
                  categories: selectedCategories,
                  searchText: searchText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
