import 'package:flutter/material.dart';

class AppLanguage {
  const AppLanguage({
    required this.code,
    required this.nativeName,
    required this.englishName,
  });

  final String code;
  final String nativeName;
  final String englishName;

  Locale get locale => Locale(code);

  String get listLabel =>
      code == 'en' ? nativeName : '$nativeName ($englishName)';
}

class AppLanguages {
  AppLanguages._();

  static const List<AppLanguage> all = [
    AppLanguage(code: 'en', nativeName: 'English', englishName: 'English'),
    AppLanguage(code: 'ta', nativeName: 'தமிழ்', englishName: 'Tamil'),
    AppLanguage(code: 'hi', nativeName: 'हिन्दी', englishName: 'Hindi'),
    AppLanguage(code: 'te', nativeName: 'తెలుగు', englishName: 'Telugu'),
    AppLanguage(code: 'kn', nativeName: 'ಕನ್ನಡ', englishName: 'Kannada'),
    AppLanguage(code: 'ml', nativeName: 'മലയാളം', englishName: 'Malayalam'),
    AppLanguage(code: 'mr', nativeName: 'मराठी', englishName: 'Marathi'),
    AppLanguage(code: 'bn', nativeName: 'বাংলা', englishName: 'Bengali'),
    AppLanguage(code: 'gu', nativeName: 'ગુજરાતી', englishName: 'Gujarati'),
    AppLanguage(code: 'pa', nativeName: 'ਪੰਜਾਬੀ', englishName: 'Punjabi'),
  ];

  /// Temporary display-only allowlist for the language picker.
  /// Translation files and [all] stay intact. To show every locale again,
  /// add `ml`, `mr`, `bn`, `gu`, `pa` here (or point the screen at [all]).
  static const List<String> displayedCodes = ['en', 'ta', 'hi', 'te', 'kn'];

  static List<AppLanguage> get visible => [
        for (final language in all)
          if (displayedCodes.contains(language.code)) language,
      ];

  static const List<Locale> locales = [
    Locale('en'),
    Locale('ta'),
    Locale('hi'),
    Locale('te'),
    Locale('kn'),
    Locale('ml'),
    Locale('mr'),
    Locale('bn'),
    Locale('gu'),
    Locale('pa'),
  ];

  static AppLanguage? byCode(String? code) {
    if (code == null || code.isEmpty) return null;
    for (final language in all) {
      if (language.code == code) return language;
    }
    return null;
  }
}
