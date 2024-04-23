import 'package:flutter/material.dart';
import 'package:game/journeys/journeys_page.dart';
import 'package:game/challenges/challenges_page.dart';
import 'package:game/journeys/filter_form.dart';
import 'package:game/navigation_page/home_navbar.dart';

class SearchFilterBar extends StatefulWidget {
  const SearchFilterBar({super.key});

  @override
  State<SearchFilterBar> createState() => _SearchFilterBarState();
}

/// AnimationControllers can be created with `vsync: this` because of TickerProviderStateMixin.
class _SearchFilterBarState extends State<SearchFilterBar>
    with TickerProviderStateMixin {
  List<String> selectedCategories = [];
  List<String> selectedLocations = [];
  String selectedDifficulty = '';

  // Callback function to receive updated state values from the child
  void handleFilterSubmit(List<String>? a, List<String>? b, String c) {
    setState(() {
      selectedCategories = a ?? [];
      selectedLocations = b ?? [];
      selectedDifficulty = c;
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
                  // Container(
                  //   height: 30,
                  //   color: Color.fromARGB(51, 217, 217, 217),
                  //   child: Container(
                  //       decoration: BoxDecoration(
                  //         color: Color.fromARGB(
                  //             255, 255, 248, 241), // Background color
                  //         borderRadius:
                  //             BorderRadius.circular(8), // Rounded edges
                  //       ),

                  //       // color: Color.fromARGB(255, 255, 248, 241),
                  //       child: SizedBox(
                  //           width: 275,
                  //           child: TextField(
                  //             decoration: InputDecoration(
                  //               prefixIcon: Icon(
                  //                 Icons.search,
                  //                 color: Color.fromARGB(204, 0, 0, 0),
                  //                 size: 12,
                  //               ),
                  //               border: OutlineInputBorder(
                  //                 borderRadius:
                  //                     BorderRadius.circular(8), // Rounded edges
                  //                 borderSide: BorderSide(
                  //                     color: Colors
                  //                         .transparent), // Transparent border
                  //               ),
                  //               labelText:
                  //                   "Search a challenge name, location, etc...",
                  //               labelStyle: TextStyle(
                  //                 color: Color.fromARGB(76, 0, 0, 0),
                  //                 fontSize: 12,
                  //                 fontFamily: 'Lato',
                  //                 backgroundColor:
                  //                     Color.fromARGB(255, 255, 248, 241),
                  //               ),
                  //             ),
                  //           ))),
                  // ),
                  Container(
                    width: 345,
                    height: 45,
                    padding: const EdgeInsets.only(
                      top: 12,
                      left: 16,
                      right: 41,
                      bottom: 12,
                    ),
                    clipBehavior: Clip.antiAlias,
                    decoration: ShapeDecoration(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 18.10,
                          height: 18.10,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: NetworkImage(
                                  "https://via.placeholder.com/18x18"),
                              fit: BoxFit.fill,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Search a name, location, etc...',
                          style: TextStyle(
                            color: Color(0xFFB9B9B9),
                            fontSize: 14,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w400,
                            height: 0,
                          ),
                        ),
    Container(
      height: 10, // Set the desired height for the IconButton
      child: IconButton(
        icon: Icon(Icons.arrow_forward), // Example icon image
        onPressed: (){
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                builder: (context) => FilterForm(
                                    onSubmit: handleFilterSubmit,
                                    difficulty: selectedDifficulty,
                                    locations: selectedLocations,
                                    categories: selectedCategories),
                              );
                            } 
          // Action to perform when the icon is pressed
        ,
      ),
    ),
                      ],
                    ),
                  ),

                  Container(height: 600, child: HomeNavBar())
                ]))));
  }
}
