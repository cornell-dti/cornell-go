import 'package:flutter/material.dart';
import 'package:game/constants/constants.dart';

Widget navTab(context, icon, label, next) {
  const listTextStyle = TextStyle(
    color: Colors.grey,
    fontWeight: FontWeight.bold,
  );
  return ListTile(
    leading: Icon(icon, color: AppColors.carnelian),
    title: Text(label, style: listTextStyle),
    onTap: () => {
      Navigator.pop(context),
      Navigator.push(context, MaterialPageRoute(builder: (context) => next)),
    },
  );
}
