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
            // decoration: BoxDecoration(
            //   // color: Color.fromARGB(255, 255, 248, 241),

            // ),
            child: Padding(
                padding: EdgeInsets.fromLTRB(0, 50, 0, 0),
                child: Column(children: [
                  Container(
                      height: 45,
                      color: Color.fromARGB(51, 217, 217, 217),
                      child: Row(children: [
                        Container(
                            decoration: BoxDecoration(
                              color: Color.fromARGB(
                                  255, 255, 248, 241), // Background color
                              borderRadius:
                                  BorderRadius.circular(30), // Rounded edges
                            ),

                            // color: Color.fromARGB(255, 255, 248, 241),
                            child: SizedBox(
                                width: 345,
                                height: 45,
                                child: TextField(
                                  onSubmitted: onSearchTextChanged,
                                  decoration: InputDecoration(
                                    prefixIcon: Icon(
                                      Icons.search,
                                      color: Color.fromARGB(76, 0, 0, 0),
                                      size: 12,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                          30), // Rounded edges
                                      borderSide: BorderSide(
                                          color: Colors
                                              .transparent), // Transparent border
                                    ),
                                    labelText:
                                        "Search a challenge name, location, etc...",
                                    labelStyle: TextStyle(
                                      color: Color.fromARGB(76, 0, 0, 0),
                                      fontSize: 12,
                                      fontFamily: 'Lato',
                                      backgroundColor:
                                          Color.fromARGB(255, 255, 248, 241),
                                    ),
                                  ),
                                ))),
                        Container(
                            width: 36,
                            height:
                                36, // Set the desired height for the IconButton
                            child: IconButton(
                                icon: SvgPicture.asset(
                                  'assets/icons/Group 578.svg', // Path to your local SVG file
                                ),
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    builder: (context) => FilterForm(
                                        onSubmit: handleFilterSubmit,
                                        difficulty: selectedDifficulty,
                                        locations: selectedLocations,
                                        categories: selectedCategories),
                                  );
                                }))
                      ])),
                  // Container(
                  //   width: 345,
                  //   height: 45,
                  //   padding: const EdgeInsets.only(
                  //     top: 12,
                  //     left: 16,
                  //     right: 41,
                  //     bottom: 12,
                  //   ),
                  //   clipBehavior: Clip.antiAlias,
                  //   decoration: ShapeDecoration(
                  //     color: Colors.white,
                  //     shape: RoundedRectangleBorder(
                  //       borderRadius: BorderRadius.circular(30),
                  //     ),
                  //   ),
                  //   child: Row(
                  //     mainAxisSize: MainAxisSize.min,
                  //     mainAxisAlignment: MainAxisAlignment.start,
                  //     crossAxisAlignment: CrossAxisAlignment.center,
                  //     children: [
                  //       Container(
                  //           width: 8.10,
                  //           height: 18.10,
                  //           decoration: BoxDecoration(
                  //             image: DecorationImage(
                  //               image: NetworkImage(
                  //                   "https://via.placeholder.com/18x18"),
                  //               fit: BoxFit.fill,
                  //             ),
                  //           )),
                  //       Container(
                  //         width: 36,
                  //         height:
                  //             36, // Set the desired height for the IconButton
                  //         child: IconButton(
                  //           icon: SvgPicture.asset(
                  //             'assets/icons/Group 578.svg', // Path to your local SVG file
                  //           ),
                  //           onPressed: () {
                  //             showModalBottomSheet(
                  //               context: context,
                  //               isScrollControlled: true,
                  //               builder: (context) => FilterForm(
                  //                   onSubmit: handleFilterSubmit,
                  //                   difficulty: selectedDifficulty,
                  //                   locations: selectedLocations,
                  //                   categories: selectedCategories),
                  //             );
                  //           }
                  //           // Action to perform when the icon is pressed
                  //           ,
                  //         ),
                  //       ),
                  //     ],
                  //   ),
                  // ),

                  Container(
                      height: 600,
                      child: HomeNavBar(
                          difficulty: selectedDifficulty,
                          locations: selectedLocations,
                          categories: selectedCategories,
                          searchText: searchText))
                ]))));
  }
}
