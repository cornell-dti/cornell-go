import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:game/constants/constants.dart';

final defaultStyle = TextStyle(
  fontWeight: FontWeight.normal,
  color: Colors.white,
);
Widget leaderBoardUserCell(
  context,
  String name,
  int position,
  int total_positions,
  int points,
) {
  var posStyle = defaultStyle.copyWith(
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );
  var totalPosStyle = posStyle.copyWith(fontSize: 20);
  var pointStyle = defaultStyle.copyWith(
    fontSize: 18,
    fontStyle: FontStyle.italic,
  );
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Container(
      clipBehavior: Clip.none,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: AppColors.carnelian,
        border: Border.all(color: Colors.grey),
      ),
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
                child: CachedNetworkImage(
                  key: ValueKey('leaderboard-$position-$name'), // need a key that's unique per item (imageUrl is the same for everyone)
                  imageUrl: 'https://www.w3schools.com/howto/img_avatar.png',
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      width: 90,
                      height: 90,
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4.6),
                    ),
                    child: Icon(Icons.error),
                  ),
                  fit: BoxFit.cover,
                  width: 90,
                  height: 90,
                ),
              ),
            ),
            Text(points.toString(), style: pointStyle),
          ],
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
        ),
      ),
    ),
  );
}
