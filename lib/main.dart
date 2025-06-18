import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tasbeehlite/screens/home_screen.dart';
import 'package:tasbeehlite/screens/settings_screen.dart';
import 'package:tasbeehlite/screens/about_screen.dart';
import 'package:tasbeehlite/localization/app_localizations.dart';
import 'package:tasbeehlite/utils/language_manager.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

// by Soiad Mahedi

late SharedPreferences prefs;

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.transparent,
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark, // For light theme
  ));

  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  prefs = await SharedPreferences.getInstance(); // Initialize SharedPreferences
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Future<String> _localeFuture; // Renamed for clarity

  @override
  void initState() {
    super.initState();
    _localeFuture = LanguageManager.getSavedLanguage();
  }

  void _changeLanguage(String localeCode) {
    setState(() {
      LanguageManager.saveLanguage(localeCode);
      _localeFuture = LanguageManager.getSavedLanguage();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _localeFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Splash screen is preserved by FlutterNativeSplash.preserve
          // So, returning a minimal widget or an empty Container is fine.
          return Container(color: Colors.white); // Or your splash screen background color
        } else if (snapshot.hasError) {
          FlutterNativeSplash.remove();
          return MaterialApp(
              debugShowCheckedModeBanner: false,
              home: Scaffold(body: Center(child: Text('Error loading language: ${snapshot.error}'))));
        } else if (snapshot.hasData) {
          final currentLocaleCode = snapshot.data!;
          FlutterNativeSplash.remove(); // Remove splash screen

          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Tasbeeh Lite', // This can be localized using AppLocalizations after it's loaded
            theme: ThemeData(
              fontFamily: 'LiAdorFont',
              primarySwatch: Colors.green,
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                ),
              ),
              // Define other theme properties if needed
            ),
              locale: Locale(currentLocaleCode),
            supportedLocales: const [
              Locale('en', ''),
              Locale('bn', ''),
              Locale('sw', ''),
              Locale('ko', ''),
              Locale('ar', ''),

              // এখানে লক্ষণীয় বিষয় হলো : syl মূলত সিলেটি ভাষার জন্য ব্যবহারিত কোড।
              // কিন্তু syl এইটা Dart সাপোর্ট করে না এই কারণে sw ব্যবহার করা হচ্ছে।

            ],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
             localeResolutionCallback: (locale, supportedLocales) {
               // This callback is useful if you want custom logic for choosing a locale.
               // For most cases, Flutter's default resolution is fine.
               for (var supportedLocale in supportedLocales) {
                 if (supportedLocale.languageCode == locale?.languageCode) {
                   return supportedLocale;
                 }
               }
               return supportedLocales.firstWhere((loc) => loc.languageCode == 'bn'); // Fallback to Bengali
             },
            home: HomeScreen(locale: currentLocaleCode, onLanguageChanged: _changeLanguage),
            routes: {
              '/settings': (context) => SettingsScreen(
                currentLocale: currentLocaleCode, // Pass currentLocaleCode
                onLanguageChanged: _changeLanguage,
              ),
              '/about': (context) => AboutScreen(
                locale: currentLocaleCode, // Pass currentLocaleCode
                // localizations instance will be fetched using AppLocalizations.of(context)
              ),
            },
          );
        } else {
          FlutterNativeSplash.remove();
          // Fallback if no data (e.g., LanguageManager returns null unexpectedly)
          // This case should ideally be handled by LanguageManager providing a default.
          return const MaterialApp(
              debugShowCheckedModeBanner: false,
              home: Scaffold(body: Center(child: Text('No language data. Defaulting...'))));
        }
      },
    );
  }
}