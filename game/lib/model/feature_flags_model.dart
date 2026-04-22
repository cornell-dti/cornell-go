import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class FeatureFlagsModel extends ChangeNotifier {
  bool enableBuildABear = false;

  Future<void> load(String apiUrl) async {
    try {
      final response = await http.get(Uri.parse('$apiUrl/feature-flags'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        enableBuildABear = data['enableBuildABear'] ?? false;
        notifyListeners();
      }
    } catch (_) {
      // Default to false — feature stays hidden
    }
  }
}
