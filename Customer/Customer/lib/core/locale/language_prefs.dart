import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_languages.dart';

class LanguagePrefs {
  LanguagePrefs._();

  static const _codeKey = 'app_language_code';
  static const _chosenKey = 'app_language_chosen';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static bool get hasChosen => _prefs?.getBool(_chosenKey) ?? false;

  static String? get code => _prefs?.getString(_codeKey);

  static Locale get locale {
    return AppLanguages.byCode(code)?.locale ?? const Locale('en');
  }

  static Future<void> setLanguage(String languageCode) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs = prefs;
    await prefs.setString(_codeKey, languageCode);
    await prefs.setBool(_chosenKey, true);
  }
}
