import 'dart:html';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:game/api/game_api.dart';
import 'package:game/api/game_client_dto.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io' show Platform; //at the top

Future<void> showAlert(String message, context) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false, // user must tap button!
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Alert'),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text(message),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

TextEditingController _textFieldController = TextEditingController();

Future<void> _displayTextInputDialog(BuildContext context, FunctionStringCallback onOk) async {
  _textFieldController.clear();

  return showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('TextField in Dialog'),
        content: TextField(
          controller: _textFieldController,
          decoration: InputDecoration(hintText: "Text Field in Dialog"),
        ),
        actions: <Widget>[
          TextButton(
            child: Text('CANCEL'),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          TextButton(
            child: Text('OK'),
            onPressed: () {
              onOk(_textFieldController.text)
              Navigator.pop(context);
            },
          ),
        ],
      );
    },
  );
}

Future<String?> getId() async {
  var deviceInfo = DeviceInfoPlugin();
  if (Platform.isIOS) {
    // import 'dart:io'
    var iosDeviceInfo = await deviceInfo.iosInfo;
    return iosDeviceInfo.identifierForVendor; // unique ID on iOS
  } else if (Platform.isAndroid) {
    var androidDeviceInfo = await deviceInfo.androidInfo;
    return androidDeviceInfo.id; // unique ID on Android
  }
  return null;
}

Future<void> showLeaveConfirmationAlert(
    String message, context, ApiClient client) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false, // user must tap button!
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Leave Group'),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text(message),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('YES'),
            onPressed: () {
              client.serverApi?.leaveGroup(LeaveGroupDto());
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: const Text('NO'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

int numDigs(int num) {
  return num.toString().length;
}

Color constructColorFromUserName(String userName) {
  var hashCode = userName.hashCode;
  while (numDigs(hashCode) != 9) {
    if (numDigs(hashCode) < 9) {
      hashCode *= 10;
    } else {
      hashCode = hashCode ~/ 10;
    }
  }
  List<int> vals = [];
  for (var i = 0; i < 3; i++) {
    vals.add(((hashCode % 1000) / 1000 * 255).round());
    hashCode = hashCode ~/ 1000;
  }
  return Color.fromRGBO(vals[2], vals[1], vals[0], 1.0);
}

enum Status { error, success, info }

void displayToast(message, Status status) {
  Fluttertoast.showToast(
    msg: message,
    toastLength: Toast.LENGTH_SHORT,
    gravity: ToastGravity.BOTTOM,
    timeInSecForIosWeb: 1,
    backgroundColor: status == Status.error
        ? (Colors.red)
        : (status == Status.success ? (Colors.green) : Colors.yellow),
    textColor: Colors.white,
    fontSize: 16.0,
  );
}

Color RGBComplement(Color col) {
  return Color.fromRGBO(255 - col.red, 255 - col.green, 255 - col.blue, 1);
}

Text LatoText(String text, double fs, Color color, FontWeight fw) {
  return Text(text,
      style: GoogleFonts.lato(
          textStyle: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: fs)));
}

final Map<EventDifficultyDto, String> friendlyDifficulty = {
  EventDifficultyDto.Easy: "Easy",
  EventDifficultyDto.Normal: "Normal",
  EventDifficultyDto.Hard: "Hard",
};

final Map<ChallengeLocationDto, String> friendlyLocation = {
  ChallengeLocationDto.ENG_QUAD: "Engineering Quad",
  ChallengeLocationDto.ARTS_QUAD: "Arts Quad",
  ChallengeLocationDto.AG_QUAD: "Ag Quad",
  ChallengeLocationDto.NORTH_CAMPUS: "North Campus",
  ChallengeLocationDto.WEST_CAMPUS: "West Campus",
  ChallengeLocationDto.COLLEGETOWN: "Collegetown",
  ChallengeLocationDto.ITHACA_COMMONS: "Ithaca Commons",
  ChallengeLocationDto.ANY: "Cornell",
};

final Map<EventCategoryDto, String> friendlyCategory = {
  EventCategoryDto.CAFE: "Cafe",
  EventCategoryDto.DININGHALL: "Dining Hall",
  EventCategoryDto.DORM: "Dorm",
  EventCategoryDto.FOOD: "Food",
  EventCategoryDto.HISTORICAL: "Historical",
  EventCategoryDto.NATURE: "Nature",
};
