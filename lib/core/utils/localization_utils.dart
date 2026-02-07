import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

class LocalizationUtils {
  static Map<String, String>? _localizedStrings;

  static Future<void> load(Locale locale) async {
    String jsonString =
        await rootBundle.loadString('assets/lang/${locale.languageCode}.json');
    Map<String, dynamic> jsonMap = json.decode(jsonString);
    _localizedStrings =
        jsonMap.map((key, value) => MapEntry(key, value.toString()));
  }

  static String translate(String key) {
    return _localizedStrings?[key] ?? key;
  }
}

// Global helper function
String tr(String key) {
  return LocalizationUtils.translate(key);
}
