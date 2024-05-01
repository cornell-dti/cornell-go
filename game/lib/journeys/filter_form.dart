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

  _FilterFormState(
      String? difficulty, List<String>? locations, List<String>? categories) {
    selectedDifficulty = difficulty ?? '';
    selectedLocations = locations ?? [];
    selectedCategories = categories ?? [];
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
    if (selectedCategories.contains(category)) {
      selectedCategories.remove(category);
    } else {
      selectedCategories.add(category);
    }
  }

  void toggleLocation(String location) {
    if (selectedLocations.contains(location)) {
      selectedLocations.remove(location);
    } else {
      selectedLocations.add(location);
    }
  }

  void setDifficulty(String diff) {
    setState(() {
      selectedDifficulty = diff;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.9,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            color: Color.fromARGB(255, 237, 86, 86),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: Text(
                    'Filters',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: CloseButton(color: Colors.white),
                ),
              ],
            ),
          ),
          SizedBox(height: 20.0),
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
                TextButton(
                  onPressed: filterChallenges,
                  child: Text('See results'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Color.fromARGB(255, 255, 255, 255),
                    backgroundColor: Color(0xFFEC5555),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
