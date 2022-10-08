import 'package:flutter/material.dart';

final defaultStyle =
    TextStyle(fontWeight: FontWeight.normal, color: Colors.white);
Widget leaderBoardUserCell(
    context, String name, int position, int total_positions, int points) {
  Color Carnelian = Color(0xFFB31B1B);
  var posStyle =
      defaultStyle.copyWith(fontWeight: FontWeight.bold, color: Colors.white);
  var totalPosStyle = posStyle.copyWith(fontSize: 20);
  var pointStyle =
      defaultStyle.copyWith(fontSize: 18, fontStyle: FontStyle.italic);
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Container(
      clipBehavior: Clip.none,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Carnelian,
          border: Border.all(color: Colors.grey)),
      width: MediaQuery.of(context).size.width,
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: Row(
          children: [
            Row(
              children: [
                Container(
                  child: Row(
                    children: [
                      Text(position.toString(), style: posStyle),
                      Text(
                        "/" + total_positions.toString(),
                        style: totalPosStyle,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            CircleAvatar(
                child: ClipOval(
              child: Image.network(
                'https://www.w3schools.com/howto/img_avatar.png',
                fit: BoxFit.cover,
                width: 90,
                height: 90,
              ),
            )),
            Text(
              points.toString(),
              style: pointStyle,
            ),
          ],
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
        ),
      ),
    ),
  );
}
