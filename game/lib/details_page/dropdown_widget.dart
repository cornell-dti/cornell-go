import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math' as math;

import 'package:velocity_x/velocity_x.dart';

class DropdownWidget extends StatefulWidget {
  final String? value;
  final List<String>? menuOptions;

  final Function(String? val) notifyParent;

  const DropdownWidget(this.value, this.menuOptions,
      {Key? key, required this.notifyParent})
      : super(key: key);

  @override
  State<StatefulWidget> createState() =>
      _DropdownWidgetState(value, menuOptions);
}

class _DropdownWidgetState extends State<DropdownWidget> {
  String? value;
  List<String>? menuOptions;

  _DropdownWidgetState(this.value, this.menuOptions);

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton2<String>(
        isExpanded: true,
        dropdownStyleData: DropdownStyleData(
            maxHeight: 200,
            offset: Offset.fromDirection(math.pi / 2, -10),
            decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: List.empty(),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: Color.fromARGB(77, 0, 0, 0), width: 1.5))),
        iconStyleData: IconStyleData(
            icon: Padding(
          padding: const EdgeInsets.only(right: 20.0),
          child: SvgPicture.asset("assets/icons/dropdown.svg"),
        )),
        buttonStyleData: ButtonStyleData(
          decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                  width: 2.0, color: Color.fromARGB(255, 217, 217, 217)),
              borderRadius: BorderRadius.circular(10.0)),
        ),
        style: TextStyle(
            color: Color.fromARGB(77, 0, 0, 0), fontWeight: FontWeight.w400),
        value: value,
        onChanged: (newValue) {
          setState(() {
            value = newValue.toString();
          });
          widget.notifyParent(newValue);
        },
        hint: Text(
          "Select one",
          style: TextStyle(
              color: Color.fromARGB(77, 0, 0, 0),
              fontWeight: FontWeight.w400,
              fontFamily: 'Poppins',
              fontSize: 16),
        ),
        items: menuOptions == null
            ? null
            : menuOptions!.mapIndexed((item, idx) {
                return DropdownMenuItem(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(item,
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            color: Color.fromARGB(255, 0, 0, 0),
                            fontSize: 16,
                            fontWeight: FontWeight.w400)),
                  ),
                  value: item,
                );
              }).toList(),
      ),
    );
  }
}
