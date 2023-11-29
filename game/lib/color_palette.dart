import 'package:flutter/material.dart';

class ColorPalette {
  static const MaterialColor BigRed = const MaterialColor(
    0xffed5656, // 0% comes in here, this will be color picked if no shade is selected when defining a Color property which doesn’t require a swatch.
    const <int, Color>{
      //temporarily have the same color for all gradients
      50: const Color(0xffed5656), //10%
      100: const Color(0xffed5656), //20%
      200: const Color(0xffed5656), //30%
      300: const Color(0xffed5656), //40%
      400: const Color(0xffed5656), //50%
      500: const Color(0xffed5656), //60%
      600: const Color(0xffed5656), //70%
      700: const Color(0xffed5656), //80%
      800: const Color(0xffed5656), //90%
      900: const Color(0xffed5656), //100%
    },
  );
} // you can define define int 500 as the default shade and add your lighter tints above and darker tints below.
