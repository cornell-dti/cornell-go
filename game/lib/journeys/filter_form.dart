import 'package:flutter/material.dart';
import 'package:game/api/game_client_dto.dart';
import 'package:game/utils/utility_functions.dart';
import 'package:sticky_headers/sticky_headers.dart';

class FilterForm extends StatefulWidget {
  final void Function(List<String>, List<String>, String) onSubmit;
  String? myDifficulty;
  List<String>? myLocations;
  List<String>? myCategories;
  FilterForm(
      {Key? key,
      required this.onSubmit,
      String? difficulty,
      List<String>? locations,
      List<String>? categories})
      : super(key: key) {
    myDifficulty = difficulty;
    myLocations = locations;
    myCategories = categories;
  }

  @override
  // State<FilterForm> createState() => _FilterFormState(status);
  State<FilterForm> createState() {
    return _FilterFormState(myDifficulty, myLocations, myCategories);
  }
}

class _FilterFormState extends State<FilterForm> {
  // Define variables for tracking the selected values
  List<String> selectedCategories = [];
  List<String> selectedLocations = [];
  late String selectedDifficulty;
  int filterCount = 0;

  _FilterFormState(
      String? difficulty, List<String>? locations, List<String>? categories) {
    selectedDifficulty = difficulty ?? '';
    selectedLocations = locations ?? [];
    selectedCategories = categories ?? [];
    filterCount = selectedCategories.length +
        selectedLocations.length +
        (selectedDifficulty.isNotEmpty ? 1 : 0);
  }

  List<EventCategoryDto> categories = EventCategoryDto.values;

  List<ChallengeLocationDto> locations = ChallengeLocationDto.values;

  List<EventDifficultyDto> difficulties = EventDifficultyDto.values;

  // Define methods for updating the selected values
  void filterChallenges() {
    // setState(() {
    //   selectedCategories;
    //   selectedLocations;
    //   selectedStatus;
    // });
    widget.onSubmit(selectedCategories, selectedLocations, selectedDifficulty);

    Navigator.pop(context);
  }

  void toggleCategory(String category) {
    setState(() {
      if (selectedCategories.contains(category)) {
        selectedCategories.remove(category);
      } else {
        selectedCategories.add(category);
      }
      updateFilterState();
    });
  }

  void toggleLocation(String location) {
    setState(() {
      if (selectedLocations.contains(location)) {
        selectedLocations.remove(location);
      } else {
        selectedLocations.add(location);
      }
      updateFilterState();
    });
  }

  void setDifficulty(String diff) {
    setState(() {
      selectedDifficulty = diff;
      updateFilterState();
    });
  }

  void updateFilterState() {
    setState(() {
      filterCount = selectedCategories.length +
          selectedLocations.length +
          (selectedDifficulty.isNotEmpty ? 1 : 0);

      widget.onSubmit(
        selectedCategories,
        selectedLocations,
        selectedDifficulty,
      );
    });
  }

  void clearFilters() {
    setState(() {
      selectedCategories.clear();
      selectedLocations.clear();
      selectedDifficulty = '';
      filterCount = 0;
    });
    widget.onSubmit([], [], '');
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.symmetric(vertical: 12.0),
            color: Color.fromARGB(255, 237, 86, 86),
            child: Stack(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Filters',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
                Positioned(
                  top: -4.0,
                  right: 5.0,
                  child: Container(
                    width: 40.0,
                    height: 40.0,
                    child: CloseButton(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          // SizedBox(height: 20.0),
          Expanded(
              child: ListView(
                  padding: EdgeInsets.symmetric(horizontal: 20.0),
                  children: [
                ListTile(
                  title: Text(
                    'Category',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: categories.map((category) {
                    return ElevatedButton(
                      onPressed: () {
                        setState(() {
                          toggleCategory(category.name);
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            selectedCategories.contains(category.name)
                                ? Color.fromARGB(255, 249, 237, 218)
                                : Color.fromARGB(100, 210, 210, 210),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        elevation: 0,
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          friendlyCategory[category] ?? '',
                          style: TextStyle(
                            fontSize: 16.0,
                            color: Colors.black.withOpacity(0.6),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 10.0),
                ListTile(
                  title: Text(
                    'Location',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: locations.map((location) {
                    return ElevatedButton(
                      onPressed: () {
                        setState(() {
                          toggleLocation(location.name);
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            selectedLocations.contains(location.name)
                                ? Color.fromARGB(255, 249, 237, 218)
                                : Color.fromARGB(100, 210, 210, 210),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        elevation: 0,
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          friendlyLocation[location] ?? '',
                          style: TextStyle(
                            fontSize: 16.0,
                            color: Colors.black.withOpacity(0.6),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 10.0),
                ListTile(
                  title: Text(
                    'Difficulty Levels',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: difficulties.map((diff) {
                    return ElevatedButton(
                      onPressed: () {
                        setState(() {
                          setDifficulty(diff.name);
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedDifficulty.contains(diff.name)
                            ? Color.fromARGB(255, 249, 237, 218)
                            : Color.fromARGB(100, 210, 210, 210),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        elevation: 0,
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 1.0),
                        child: Text(
                          friendlyDifficulty[diff] ?? '',
                          style: TextStyle(
                            fontSize: 16.0,
                            color: Colors.black.withOpacity(0.6),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ])),
          SizedBox(height: 20.0),
          Container(
            width: 600,
            decoration: ShapeDecoration(
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  width: 1,
                  strokeAlign: BorderSide.strokeAlignCenter,
                  color: Color(0xFFE5E5E5),
                ),
              ),
            ),
          ),
          SizedBox(height: 10.0),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      selectedCategories = [];
                      selectedLocations = [];
                      selectedDifficulty = '';
                      clearFilters();
                    });
                  },
                  child: Text('Clear'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 255, 255, 255),
                    foregroundColor: Color.fromARGB(255, 0, 0, 0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                ),
                Stack(
                  children: [
                    TextButton(
                      onPressed: filterCount > 0 ? filterChallenges : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: filterCount > 0
                            ? const Color(0xFFEC5555) // Active color
                            : Colors.grey, // Disabled color
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      child: Text(
                        filterCount == 0
                            ? 'See 0 result'
                            : filterCount == 1
                                ? 'See $filterCount result'
                                : 'See $filterCount results',
                      ),
                    ),
                  ],
                ),
                // TextButton(
                //   onPressed: filterChallenges,
                //   child: Text('See results'),
                //   style: ElevatedButton.styleFrom(
                //     foregroundColor: Color.fromARGB(255, 255, 255, 255),
                //     backgroundColor: Color(0xFFEC5555),
                //     shape: RoundedRectangleBorder(
                //       borderRadius: BorderRadius.circular(10.0),
                //     ),
                //   ),
                // )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
