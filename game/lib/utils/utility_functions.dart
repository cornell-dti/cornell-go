import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:game/api/game_api.dart';
import 'package:game/api/game_client_dto.dart';
import 'package:game/splash_page/splash_page.dart';
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

Future<void> displayTextInputDialog(
    BuildContext context, String text, String hintText, dynamic onOk) async {
  _textFieldController.clear();

  return showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(text),
        content: TextField(
          controller: _textFieldController,
          decoration: InputDecoration(hintText: hintText),
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
              onOk(_textFieldController.text);
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

Future<void> showDeletionConfirmationAlert(context, ApiClient client) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false, // user must tap button!
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
            'Are you sure you want to delete your account? This action cannot be undone.'),
        actions: <Widget>[
          TextButton(
            child: const Text('YES'),
            onPressed: () async {
              await client.serverApi?.closeAccount(CloseAccountDto());
              // Clear user Local State
              await client.disconnect();
              Navigator.of(context).pop();
              // Navigate to splash page and clear navigation stack
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => SplashPageWidget()),
                (route) => false,
              );
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
    timeInSecForIosWeb: 3,
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
  ChallengeLocationDto.CENTRAL_CAMPUS: "Central Campus",
  ChallengeLocationDto.NORTH_CAMPUS: "North Campus",
  ChallengeLocationDto.WEST_CAMPUS: "West Campus",
  ChallengeLocationDto.CORNELL_ATHLETICS: "Cornell Athletics",
  ChallengeLocationDto.VET_SCHOOL: "Vet School",
  ChallengeLocationDto.COLLEGETOWN: "Collegetown",
  ChallengeLocationDto.ITHACA_COMMONS: "Ithaca Commons",
  ChallengeLocationDto.ANY: "Cornell",
};

final Map<ChallengeLocationDto, String> abbrevLocation = {
  ChallengeLocationDto.ENG_QUAD: "Eng Quad",
  ChallengeLocationDto.ARTS_QUAD: "Arts Quad",
  ChallengeLocationDto.AG_QUAD: "Ag Quad",
  ChallengeLocationDto.CENTRAL_CAMPUS: "Central Campus",
  ChallengeLocationDto.NORTH_CAMPUS: "North Campus",
  ChallengeLocationDto.WEST_CAMPUS: "West Campus",
  ChallengeLocationDto.CORNELL_ATHLETICS: "Athletics",
  ChallengeLocationDto.VET_SCHOOL: "Vet School",
  ChallengeLocationDto.COLLEGETOWN: "Collegetown",
  ChallengeLocationDto.ITHACA_COMMONS: "Commons",
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

/**
 * Calculate hint-adjusted points using the "Half-after-3" system
 * 0 hints = full points; 3 hints = exactly half points; 1-2 hints linearly reduce
 *
 * @param basePoints - Original challenge points
 * @param hintsUsed - Number of hints used (0-3)
 * @returns Points awarded after hint penalty
 */
int calculateHintAdjustedPoints(int basePoints, int hintsUsed) {
  if (hintsUsed == 0) return basePoints;

  // Formula: P * (1 - h/6) where h is hints used
  double raw = basePoints * (1 - hintsUsed / 6.0);

  // Round to nearest 5
  int rounded = (raw / 5).round() * 5;

  // Ensure minimum of half points, maximum of full points
  int minAllowed = (basePoints / 2).floor();
  return [
    minAllowed,
    [rounded, basePoints].reduce((a, b) => a < b ? a : b)
  ].reduce((a, b) => a > b ? a : b);
}

/**
 * Calculate extension-adjusted points (25% deduction per extension)
 * Each extension costs 25% of the original challenge points
 * 
 * @param originalPoints - Original challenge points
 * @param extensionsUsed - Number of timer extensions used
 * @returns Points awarded after timer extensions
 */
int calculateExtensionAdjustedPoints(int originalPoints, int extensionsUsed) {
  if (extensionsUsed == 0) return originalPoints;
  const double EXTENSION_COST = 0.25; // 25% per extension
  final deduction = (originalPoints * EXTENSION_COST * extensionsUsed).floor();
  return (originalPoints - deduction).clamp(0, originalPoints);
}
/// Matches an event based on difficulty, location, category, and search text
bool eventMatchesFilters({
  required EventDto event,
  required String? difficulty,
  required List<String>? locations,
  required List<String>? categories,
  required String? searchText,
  required String challengeLocation,
  String? challengeName,
}) {
  // Check difficulty
  final matchesDifficulty =
      (difficulty?.length ?? 0) == 0 || difficulty == event.difficulty?.name;

  // Check locations
  final matchesLocation = locations == null ||
      locations.isEmpty ||
      locations.contains(challengeLocation);

  // Check categories
  final matchesCategory = categories == null ||
      categories.isEmpty ||
      categories.contains(event.category?.name);

  // Check search text
  final searchTerm = searchText?.toLowerCase() ?? '';
  final matchesSearch = searchTerm.isEmpty ||
      challengeLocation.toLowerCase().contains(searchTerm) ||
      (event.name ?? "").toLowerCase().contains(searchTerm) ||
      (challengeName ?? "").toLowerCase().contains(searchTerm);

  return matchesDifficulty &&
      matchesLocation &&
      matchesCategory &&
      matchesSearch;
}

/// Returns a valid image URL or a default placeholder if the input is null or empty
String getValidImageUrl(String? imageUrl) {
  return (imageUrl == null || imageUrl.isEmpty)
      ? "https://upload.wikimedia.org/wikipedia/commons/b/b1/Missing-image-232x150.png"
      : imageUrl;
}
