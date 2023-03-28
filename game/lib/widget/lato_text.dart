import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';

Widget LatoText(
  String text,
  double fs,
  Color color,
  FontWeight fw,
) {
  return Text(text,
      style: GoogleFonts.lato(
          textStyle: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: fs)));
}
