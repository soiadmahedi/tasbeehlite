import 'dart:async';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:tasbeehlite/localization/app_localizations.dart';
import 'package:tasbeehlite/models/dua_model.dart';
import 'package:tasbeehlite/main.dart';

class HomeScreen extends StatefulWidget {
  final String locale; // Current locale code e.g. "bn"
  final Function(String) onLanguageChanged;

  const HomeScreen(
      {super.key, required this.locale, required this.onLanguageChanged});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  List<DuaModel> _duas = [];
  int _currentDuaIndex = 0;
  final AudioPlayer _audioPlayer = AudioPlayer(); // final for good practice

  bool _isVibrationEnabled = false;
  bool _isClickSoundEnabled = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSettingsAndDuas();
    _audioPlayer.setReleaseMode(ReleaseMode.stop);
  }

  Future<void> _loadSettingsAndDuas() async {
    await _loadSettings(); // Load vibration/sound settings
    _initializeDuas();    // Initialize or load duas
    _loadDuaProgress();   // Load progress for duas
    if (mounted) {
      setState(() {}); // Refresh UI after loading
    }
  }

  void _initializeDuas() {
    // For simplicity, we'll use a fixed list.
    // Dynamic user-added duas would require more complex storage and UI.
    _duas = [
      DuaModel(id: 'subhanallah', nameKey: 'subhanallah', arabicText: 'سُبْحَانَ اللَّهِ', targetCount: 33),
      DuaModel(id: 'alhamdulillah', nameKey: 'alhamdulillah', arabicText: 'الْحَمْدُ لِلَّهِ', targetCount: 33),
      DuaModel(id: 'allahu_akbar', nameKey: 'allahu_akbar', arabicText: 'اللَّهُ أَكْبَرُ', targetCount: 34),
    ];
  }

  Future<void> _loadSettings() async {
    _isVibrationEnabled = prefs.getBool('vibrationEnabled') ?? false;
    _isClickSoundEnabled = prefs.getBool('clickSoundEnabled') ?? true;
  }

  Future<void> _saveSettings() async {
    await prefs.setBool('vibrationEnabled', _isVibrationEnabled);
    await prefs.setBool('clickSoundEnabled', _isClickSoundEnabled);
  }

  Future<void> _saveDuaProgress() async {
    if (_duas.isEmpty) return;
    await prefs.setInt('currentDuaIndex_v2', _currentDuaIndex);
    for (var dua in _duas) {
      await prefs.setInt('dua_count_${dua.id}_v2', dua.currentCount);
    }
  }

  void _loadDuaProgress() {
    if (_duas.isEmpty) return;
    _currentDuaIndex = prefs.getInt('currentDuaIndex_v2') ?? 0;
    if (_currentDuaIndex >= _duas.length) _currentDuaIndex = 0;

    for (var dua in _duas) {
      dua.currentCount = prefs.getInt('dua_count_${dua.id}_v2') ?? 0;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _saveDuaProgress();
      _saveSettings();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _audioPlayer.dispose();
    _saveDuaProgress();
    _saveSettings();
    super.dispose();
  }

  void _incrementCounter() async {
    if (_duas.isEmpty) return;

    if (_isVibrationEnabled) {
      bool? hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator ?? false) Vibration.vibrate(duration: 50);
    }
    if (_isClickSoundEnabled) {
      try {
        await _audioPlayer.play(AssetSource('sounds/click_sound.mp3'));
      } catch (e) {
        debugPrint("Error playing sound: $e");
      }
    }

    setState(() {
      DuaModel currentDua = _duas[_currentDuaIndex];
      if (currentDua.currentCount < currentDua.targetCount) {
        currentDua.currentCount++;
      }

      if (currentDua.currentCount >= currentDua.targetCount) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.translate(currentDua.nameKey)} ${AppLocalizations.of(context)!.translate('completed')}!'),
            duration: const Duration(seconds: 1),
          ),
        );
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted) return;
          setState(() {
            currentDua.currentCount = 0; // Reset for next cycle
            _currentDuaIndex = (_currentDuaIndex + 1) % _duas.length;
            _saveDuaProgress();
          });
        });
      } else {
        _saveDuaProgress();
      }
    });
  }

  void _resetCurrentDuaCounter() {
    if (_duas.isEmpty) return;
    setState(() {
      _duas[_currentDuaIndex].currentCount = 0;
      _saveDuaProgress();
    });
  }

  void _resetAllCounters() {
    if (!mounted) return;
    setState(() {
      for (var dua in _duas) {
        dua.currentCount = 0;
      }
      _currentDuaIndex = 0;
      _saveDuaProgress();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.translate('all_records_reset'))),
    );
  }

  void _selectDua(int index) {
    if (index >= 0 && index < _duas.length) {
      setState(() {
        _currentDuaIndex = index;
        _saveDuaProgress(); // Save selected dua index
      });
    }
  }

  void _saveBookmark() {
    _saveDuaProgress(); // Progress is auto-saved
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.translate('progress_saved'))),
    );
  }

  void _shareApp() {
    Share.share('Check out this Tasbeeh Lite app: https://your-app-link.com');
  }

  String formatCounter(int counter, String localeCode) {
    // Using AppLocalizations's currentLanguageCode for consistency if needed,
    // but widget.locale is directly available and fine here.
    if (localeCode == 'bn' || localeCode == 'sw') {
      const bengaliDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
      return counter.toString().split('').map((d) => bengaliDigits[int.parse(d)]).join('');
    } else if (localeCode == 'ar') {
      const arabicIndicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
      return counter.toString().split('').map((d) => arabicIndicDigits[int.parse(d)]).join('');
    }
    return counter.toString();
  }

  @override
  Widget build(BuildContext context) {
    // AppLocalizations.of(context) can be null if not properly set up or called too early.
    // However, with FutureBuilder in main.dart, it should be available.
    final localizations = AppLocalizations.of(context);
    if (localizations == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator())); // Loading state
    }

    final currentDua = _duas.isNotEmpty ? _duas[_currentDuaIndex] : null;
    final progress = (currentDua != null && currentDua.targetCount > 0)
        ? currentDua.currentCount / currentDua.targetCount
        : 0.0;

    // Determine text direction for Arabic
    TextDirection currentTextDirection = TextDirection.ltr;
    if (widget.locale == 'ar') {
      currentTextDirection = TextDirection.rtl;
    }


    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('tasbeeh_counter')),
        actions: [
          IconButton(
              icon: const Icon(Icons.share),
              tooltip: localizations.translate('share_app'),
              onPressed: _shareApp),
          IconButton(
              icon: const Icon(Icons.info_outline),
              tooltip: localizations.translate('about'),
              onPressed: () => Navigator.pushNamed(context, '/about')),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: localizations.translate('settings'),
            onPressed: () async {
              // Settings screen might change language or other settings
              await Navigator.pushNamed(context, '/settings');
              // Reload settings from SharedPreferences as they might have changed
              if (mounted) {
                await _loadSettings(); // Reload vibration/sound
                setState(() {}); // Rebuild to reflect changes if any
              }
            },
          ),
        ],
      ),
      body: _duas.isEmpty
          ? Center(child: Text(localizations.translate('no_duas_configured')))
          : Directionality( // Ensures correct layout direction for RTL languages like Arabic
        textDirection: currentTextDirection,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    localizations.translate(currentDua!.nameKey),
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor),
                    textAlign: TextAlign.center,
                  ),
                  if (currentDua.arabicText.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        currentDua.arabicText,
                        style: TextStyle(
                          fontSize: 24, // Increased for Arabic readability
                          fontFamily: widget.locale == 'ar' ? 'NotoNaskhArabic' : null, // Specific font for Arabic
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 10),
                  Text(
                    '${localizations.translate('target')}: ${formatCounter(currentDua.targetCount, widget.locale)}',
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 220,
                      height: 220,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 12,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).primaryColor),
                      ),
                    ),
                    Text(
                      formatCounter(currentDua.currentCount, widget.locale),
                      style: const TextStyle(
                          fontSize: 90, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            if (_duas.length > 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                child: DropdownButtonFormField<int>(
                  decoration: InputDecoration(
                    labelText: localizations.translate('select_dua'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  value: _currentDuaIndex,
                  items: _duas.asMap().entries.map((entry) {
                    return DropdownMenuItem<int>(
                      value: entry.key,
                      child: Text(localizations.translate(entry.value.nameKey)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) _selectDua(value);
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                      icon: const Icon(Icons.bookmark_add_outlined),
                      iconSize: 30,
                      tooltip: localizations.translate('save_bookmark'),
                      onPressed: _saveBookmark),
                  InkWell(
                    onTap: _incrementCounter,
                    borderRadius: BorderRadius.circular(50),
                    child: Container(
                      width: 100, height: 100,
                      decoration: BoxDecoration(
                          color: Colors.greenAccent.shade400,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                spreadRadius: 1, blurRadius: 5, offset: const Offset(0, 3))
                          ]),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Image.asset("assets/images/tasbeeh.png",
                            fit: BoxFit.contain, color: Colors.white),
                      ),
                    ),
                  ),
                  IconButton(
                      icon: const Icon(Icons.refresh),
                      iconSize: 30,
                      tooltip: localizations.translate('reset_current_dua'),
                      onPressed: _resetCurrentDuaCounter),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 50.0),
              child: OutlinedButton.icon(
                icon: const Icon(Icons.delete_sweep_outlined),
                label: Text(localizations.translate('reset_all_counters')),
                onPressed: _resetAllCounters,
                style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}