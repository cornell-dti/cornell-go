                      }),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'e.g. JaneDoe123',
                      ),

                      // The validator receives the text that the user has entered.
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter some text';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LatoText("Graduation Year (optional)", 18, Colors.black,
                        FontWeight.w700),
                    SizedBox(height: 10),
                    DropdownButton(
                      value: _year,
                      onChanged: (newValue) {
                        print(newValue);
                        setState(() {
                          _year = newValue.toString();
                        });
                      },
                      items: _years.map((year) {
                        return DropdownMenuItem(
                          child: Container(
                              width: 255,
                              height: 53,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: LatoText(
                                    year, 16.0, Colors.black, FontWeight.w600),
                              )),
                          value: year,
                        );
                      }).toList(),
                    )
                  ],
                ),
                ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Processing Data')),
                        );
                      }
                    },
                    style: ButtonStyle(
                        backgroundColor:
                            MaterialStatePropertyAll<Color>(Colors.black)),
                    child: Container(
                        width: 255,
                        height: 53,
                        child: Align(
                          alignment: Alignment.center,
                          child: LatoText(
                              "Continue", 16.0, Colors.white, FontWeight.w600),
                        )),
                  ),
              ],
            ),
          )),
    );
  }
}
