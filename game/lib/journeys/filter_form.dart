import 'package:flutter/material.dart';

class FilterForm extends StatefulWidget {
  const FilterForm({Key? key}) : super(key: key);

  @override
  State<FilterForm> createState() => _FilterFormState();
}

class _FilterFormState extends State<FilterForm> {
  // Define variables for tracking the selected values
  List<String> selectedCategories = [];
  List<String> selectedLocations = [];
  String selectedStatus = 'Not Started';

  List<String> categories = [
    'Food',
    'Nature',
    'Historical',
    'Cafe',
    'Nature',
    'Nature'
  ];
  List<String> locations = ['Location 1', 'Location 2', 'Location 3'];
  List<String> statuses = ['Not Started', 'Completed', 'Saved'];

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
      heightFactor: 0.75,
      child: Container(
        margin: EdgeInsets.all(32.0),
        child: ListView(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'FILTER BY',
                  style: TextStyle(
                    color: Color.fromARGB(127, 0, 0, 0),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Lato',
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.close, size: 20.0),
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(
                        Color.fromARGB(153, 217, 217, 217)),
                  ),
                ),
              ],
            ),
            ListTile(
              title: Text('Category',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Lato',
                  )),
              contentPadding: EdgeInsets.zero,
            ),
            GridView.count(
              crossAxisCount: 3,
              childAspectRatio: 3,
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              children: categories
                  .map((category) => CheckboxListTile(
                        title: Text(
                          category,
                          style: TextStyle(fontSize: 13.0),
                        ),
                        value: selectedCategories.contains(category),
                        onChanged: (changedValue) {
                          setState(() {
                            toggleCategory(category);
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        activeColor: Color.fromARGB(153, 217, 217, 217),
                      ))
                  .toList(),
            ),
            ListTile(
              title: Text('Location',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Lato',
                  )),
              contentPadding: EdgeInsets.zero,
            ),
            Column(
              children: locations
                  .map((location) => ListTileTheme(
                      contentPadding: EdgeInsets.all(0),
                      horizontalTitleGap: 0.0,
                      child: CheckboxListTile(
                        title: Text(
                          location,
                          style: TextStyle(fontSize: 13.0),
                        ),
                        value: selectedLocations.contains(location),
                        onChanged: (value) {
                          setState(() {
                            toggleLocation(location);
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                        // contentPadding: EdgeInsets.all(0),
                        activeColor: Color.fromARGB(153, 217, 217, 217),
                      )))
                  .toList(),
            ),
            ListTile(
              title: Text('Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Lato',
                  )),
              contentPadding: EdgeInsets.zero,
            ),
            Column(
              children: statuses
                  .map((status) => RadioListTile(
                        title: Text(status, style: TextStyle(fontSize: 13.0)),
                        value: status,
                        groupValue: selectedStatus,
                        onChanged: (changedValue) {
                          setState(() {
                            setStatus(status);
                          });
                        },
                        contentPadding: EdgeInsets.all(0),
                      ))
                  .toList(),
            ),
            Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                    onPressed: () {
                      setState(() {
                        selectedCategories = [];
                        selectedLocations = [];
                        selectedStatus = 'All';
                      });
                    },
                    child: Text('Reset'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromARGB(255, 255, 255, 255),
                      foregroundColor: Color.fromARGB(255, 0, 0, 0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(2.0),
                        side: BorderSide(color: Colors.black, width: 1.0),
                      ),
                    )),
                TextButton(
                  onPressed: () {
                    // TODO: Implement apply filters button
                  },
                  child: Text('Apply'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Color.fromARGB(255, 255, 255, 255),
                    backgroundColor: Color.fromARGB(255, 0, 0, 0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(2.0),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
