import 'package:flutter/material.dart';
import 'package:game/journeys/journeys_page.dart';

class FilterForm extends StatefulWidget {
  const FilterForm({Key? key}) : super(key: key);

  @override
  State<FilterForm> createState() => _FilterFormState();
}

class _FilterFormState extends State<FilterForm> {
  // Define variables for tracking the selected values
  List<String> selectedCategories = [];
  List<String> selectedLocations = [];
  String selectedStatus = 'Easy';

  List<String> categories = [
    'Food',
    'Nature',
    'Historical',
    'Cafe',
    'Dining Hall',
    'Dorm'
  ];
  List<String> locations = ['Location 1', 'Location 2', 'Location 3'];
  List<String> statuses = ['Easy', 'Medium', 'Hard'];

  // Define methods for updating the selected values
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

  void setStatus(String status) {
    setState(() {
      selectedStatus = status;
    });
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return FractionallySizedBox(
      heightFactor: 0.9,
      child: Container(
        child: ListView(
          children: [
            Container(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              color: Color.fromARGB(255, 237, 86, 86),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 161.0),
                        child: Container(
                          alignment: Alignment.center,
                          child: Text(
                            'Filters',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              // fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 110),
                        child: SizedBox(
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: CloseButton(color: Colors.white),
                          ),
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                            toggleCategory(category);
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selectedCategories.contains(category)
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
                            category,
                            style: TextStyle(
                              fontSize: 16.0,
                              color: Colors.black.withOpacity(0.6),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
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
                            toggleLocation(location);
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selectedLocations.contains(location)
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
                            location,
                            style: TextStyle(
                              fontSize: 16.0,
                              color: Colors.black.withOpacity(0.6),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
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
                    children: statuses.map((status) {
                      return ElevatedButton(
                        onPressed: () {
                          setState(() {
                            setStatus(status);
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selectedStatus.contains(status)
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
                            status,
                            style: TextStyle(
                              fontSize: 16.0,
                              color: Colors.black.withOpacity(0.6),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            Padding(padding: EdgeInsets.symmetric(vertical: 40.0)),
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
            Padding(padding: EdgeInsets.symmetric(vertical: 20.0)),
            Row(
              // padding: EdgeInsets.symmetric(vertical: 30),
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.0),
                  child: TextButton(
                      onPressed: () {
                        setState(() {
                          selectedCategories = [];
                          selectedLocations = [];
                          selectedStatus = 'All';
                        });
                      },
                      child: Text('Clear'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 255, 255, 255),
                        foregroundColor: Color.fromARGB(255, 0, 0, 0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          // side: BorderSide(color: Colors.black, width: 1.0),
                        ),
                      )),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.0),
                  child: TextButton(
                    onPressed: () {
                      // TODO: Implement apply filters button
                    },
                    child: Text('See results'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Color.fromARGB(255, 255, 255, 255),
                      backgroundColor: Color(0xFFEC5555),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
