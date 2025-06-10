// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:tasbeehlite/localization/app_localizations.dart';
import 'package:tasbeehlite/main.dart';

class SettingsScreen extends StatefulWidget {
  final String currentLocale;
  final Function(String) onLanguageChanged;

  const SettingsScreen(
      {super.key,
        required this.currentLocale,
        required this.onLanguageChanged});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late String _selectedLocale;
  bool _isVibrationEnabled = false;
  bool _isClickSoundEnabled = true;

  @override
  void initState() {
    super.initState();
    _selectedLocale = widget.currentLocale;
    _loadSettings();
  }

  void _loadSettings() {
    _isVibrationEnabled = prefs.getBool('vibrationEnabled') ?? false;
    _isClickSoundEnabled = prefs.getBool('clickSoundEnabled') ?? true;
  }

  Future<void> _saveSettings() async {
    await prefs.setBool('vibrationEnabled', _isVibrationEnabled);
    await prefs.setBool('clickSoundEnabled', _isClickSoundEnabled);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    // Determine text direction for Arabic
    TextDirection currentTextDirection = TextDirection.ltr;
    if (widget.currentLocale == 'ar') { // or _selectedLocale
      currentTextDirection = TextDirection.rtl;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('settings')),
      ),
      body: Directionality(
        textDirection: currentTextDirection,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            ListTile(
              title: Text(localizations.translate('language')),
              trailing: DropdownButton<String>(
                value: _selectedLocale,
                items: const [
                  // Ensure display text is also localized or fixed per language
                  DropdownMenuItem(value: 'bn', child: Text('বাংলা (Bengali)')),
                  DropdownMenuItem(value: 'sw', child: Text('সিলেটি (Sylheti)')),
                  DropdownMenuItem(value: 'en', child: Text('English')),
                  DropdownMenuItem(value: 'ko', child: Text('한국어 (Korean)')),
                  DropdownMenuItem(value: 'ar', child: Text('العربية (Arabic)')),

                  // এখানে লক্ষণীয় বিষয় হলো : syl মূলত সিলেটি ভাষার জন্য ব্যবহারিত কোড।
                  // কিন্তু syl এইটা Dart সাপোর্ট করে না এই কারণে sw ব্যবহার করা হচ্ছে।

                ],
                onChanged: (value) {
                  if (value != null && value != _selectedLocale) {
                    setState(() {
                      _selectedLocale = value;
                    });
                    widget.onLanguageChanged(value);
                  }
                },
              ),
            ),
            const Divider(),
            SwitchListTile(
              title: Text(localizations.translate('vibration')),
              value: _isVibrationEnabled,
              onChanged: (bool value) {
                setState(() {
                  _isVibrationEnabled = value;
                });
                _saveSettings();
              },
              secondary: const Icon(Icons.vibration),
            ),
            const Divider(),
            SwitchListTile(
              title: Text(localizations.translate('click_sound')),
              value: _isClickSoundEnabled,
              onChanged: (bool value) {
                setState(() {
                  _isClickSoundEnabled = value;
                });
                _saveSettings();
              },
              secondary: const Icon(Icons.music_note_outlined),
            ),
          ],
        ),
      ),
    );
  }
}