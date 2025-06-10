// lib/localization/app_localizations.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(String localeCode) : locale = Locale(localeCode); // Constructor takes string

  // Standard way to get instance
  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  // Delegate for MaterialApp
  static const LocalizationsDelegate<AppLocalizations> delegate =
  _AppLocalizationsDelegate();

  late Map<String, String> _localizedStrings;

  Future<bool> load() async {
    // Load the language JSON file from the "assets/i18n" folder
    String jsonString =
    await rootBundle.loadString('assets/i18n/${locale.languageCode}.json');
    Map<String, dynamic> jsonMap = json.decode(jsonString);

    _localizedStrings = jsonMap.map((key, value) {
      return MapEntry(key, value.toString());
    });
    return true;
  }

  // This method will be called from every widget which needs a localized text
  String translate(String key) {
    return _localizedStrings[key] ?? key; // Return the key if translation is not found
  }

  // Helper to get current language code, e.g., for number formatting
  String get currentLanguageCode => locale.languageCode;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    // Include all supported languages here
    return ['en', 'bn', 'sw', 'ko', 'ar'].contains(locale.languageCode);
    // এখানে লক্ষণীয় বিষয় হলো : syl মূলত সিলেটি ভাষার জন্য ব্যবহারিত কোড।
    // কিন্তু syl এইটা Dart সাপোর্ট করে না এই কারণে sw ব্যবহার করা হচ্ছে।
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    // AppLocalizations class is where the JSON loading actuallyRuns
    AppLocalizations localizations = AppLocalizations(locale.languageCode);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

// একটি সহজ উপায়ে অনুবাদ পাওয়ার জন্য একটি হেল্পার ফাংশন (ঐচ্ছিক)
String translate(BuildContext context, String key) {
  return AppLocalizations.of(context)!.translate(key);
}