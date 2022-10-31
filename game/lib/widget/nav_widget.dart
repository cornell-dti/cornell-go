import 'package:flutter/material.dart';

Widget navTab(context, icon, label, next) {
  Color Carnelian = Color(0xFFB31B1B);
  const listTextStyle =
      TextStyle(color: Colors.grey, fontWeight: FontWeight.bold);
  return ListTile(
      leading: Icon(
        icon,
        color: Carnelian,
      ),
      title: Text(label, style: listTextStyle),
      onTap: () => {
            Navigator.pop(context),
            Navigator.push(
                context, MaterialPageRoute(builder: (context) => next))
          });
}
