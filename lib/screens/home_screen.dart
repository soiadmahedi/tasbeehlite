// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:share_plus/share_plus.dart'; // শেয়ার করার জন্য ইম্পোর্ট করুন

// আপনার প্রজেক্টের সঠিক পাথ ব্যবহার করুন
import 'package:tasbeehlite/models/dua_model.dart';
import 'package:tasbeehlite/localization/app_localizations.dart';

// main.dart থেকে prefs ইম্পোর্ট করার আর প্রয়োজন নেই
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
  late SharedPreferences _prefs; // লোকাল ভেরিয়েবল ব্যবহার করা হচ্ছে
  final AudioPlayer _audioPlayer = AudioPlayer();
  late PageController _pageController;

  final List<DuaModel> _duas = [
    DuaModel(id: 'subhanallah', nameKey: 'subhanallah', arabicText: 'سُبْحَانَ اللَّهِ', targetCount: 33),
    DuaModel(id: 'alhamdulillah', nameKey: 'alhamdulillah', arabicText: 'الْحَمْدُ لِلَّهِ', targetCount: 33),
    DuaModel(id: 'allahu_akbar', nameKey: 'allahu_akbar', arabicText: 'اللَّهُ أَكْبَرُ', targetCount: 34),
  ];

  int _currentDuaIndex = 0;
  bool _isVibrationEnabled = true;
  bool _isClickSoundEnabled = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // index ০ দিয়ে শুরু হবে, পরে loadAllData থেকে আপডেট হবে
    _pageController = PageController(initialPage: _currentDuaIndex);
    _loadAllData();
    _audioPlayer.setReleaseMode(ReleaseMode.stop);
  }

  Future<void> _loadAllData() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _loadSettings();
      _loadDuaProgress();
      if (_pageController.hasClients) {
        _pageController.jumpToPage(_currentDuaIndex);
      }
    });
  }

  void _loadSettings() {
    _isVibrationEnabled = _prefs.getBool('vibrationEnabled') ?? true;
    _isClickSoundEnabled = _prefs.getBool('clickSoundEnabled') ?? true;
  }

  void _loadDuaProgress() {
    _currentDuaIndex = _prefs.getInt('currentDuaIndex') ?? 0;
    for (var dua in _duas) {
      // গ্লোবাল prefs এর পরিবর্তে লোকাল _prefs ব্যবহার করা হচ্ছে
      dua.currentCount = prefs.getInt('dua_count${dua.id}') ?? 0;
    }
  }

  Future<void> _saveDuaProgress() async {
    await _prefs.setInt('currentDuaIndex', _currentDuaIndex);
    for (var dua in _duas) {
      // গ্লোবাল prefs এর পরিবর্তে লোকাল _prefs ব্যবহার করা হচ্ছে
      await prefs.setInt('dua_count${dua.id}', dua.currentCount);
    }
  }

  String _toBengaliNumerals(int number) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const bengali = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    String text = number.toString();
    for (int i = 0; i < english.length; i++) {
      text = text.replaceAll(english[i], bengali[i]);
    }
    return text;
  }

  void _incrementCounter() async {
    if (_duas.isEmpty) return;

    if (_isVibrationEnabled) Vibration.vibrate(duration: 20);
    if (_isClickSoundEnabled) {
      try {
        await _audioPlayer.play(AssetSource('sounds/click_sound.mp3'));
      } catch (e) {
        debugPrint("Error playing sound: $e");
      }
    }

    setState(() {
      if (_duas[_currentDuaIndex].currentCount < _duas[_currentDuaIndex].targetCount) {
        _duas[_currentDuaIndex].currentCount++;
      }
    });

    if (_duas[_currentDuaIndex].currentCount >= _duas[_currentDuaIndex].targetCount) {
      final duaName = AppLocalizations.of(context)!.translate(_duas[_currentDuaIndex].nameKey);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$duaName সম্পন্ন হয়েছে!'),
          duration: const Duration(seconds: 2),
        ),
      );
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;

        // রিসেট এবং পরবর্তী তাসবিহ-তে যাওয়ার লজিক
        setState(() {
          _duas[_currentDuaIndex].currentCount = 0;
          _currentDuaIndex = (_currentDuaIndex + 1) % _duas.length;
          _pageController.animateToPage(
            _currentDuaIndex,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
        });
        _saveDuaProgress();
      });
    } else {
      _saveDuaProgress();
    }
  }

  void _resetCurrentCounter() {
    setState(() {
      _duas[_currentDuaIndex].currentCount = 0;
    });
    _saveDuaProgress();
  }

  void _resetAllCounters() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.translate('confirm')),
        content: Text(AppLocalizations.of(context)!.translate('reset_all_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.translate('no')),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                for (var dua in _duas) {
                  dua.currentCount = 0;
                }
                _currentDuaIndex = 0;
                _pageController.jumpToPage(0);
              });
              _saveDuaProgress();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppLocalizations.of(context)!.translate('all_records_reset'))),
              );
            },
            child: Text(AppLocalizations.of(context)!.translate('yes_delete')),
          ),
        ],
      ),
    );
  }

  void _shareApp() {
    // এখানে আপনার অ্যাপের লিংক দিন
    final String appLink = "https://play.google.com/store/apps/details?id=com.soiadmahedi.tasbeehlite";
    final String shareMessage = "${AppLocalizations.of(context)!.translate('share_app_message')} $appLink";
    Share.share(shareMessage);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _saveDuaProgress();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _audioPlayer.dispose();
    _pageController.dispose();
    _saveDuaProgress();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    if (_duas.isEmpty) {
      return Scaffold(body: Center(child: Text(localizations.translate('no_duas_configured'))));
    }

    final DuaModel currentDua = _duas[_currentDuaIndex];
    final double progress = currentDua.targetCount > 0
        ? currentDua.currentCount / currentDua.targetCount
        : 0.0;

    return Scaffold(
      // একটি AppBar যুক্ত করা হয়েছে যেখানে সব বাটন থাকবে
      appBar: AppBar(
        title: Text(localizations.translate('tasbeeh_counter')),
        backgroundColor: Color(0xFFBDFFCF),
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: localizations.translate('share_app'),
            onPressed: _shareApp,
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: localizations.translate('about'),
            onPressed: () => Navigator.pushNamed(context, '/about'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: localizations.translate('settings'),
            // এখন সেটিংসে ক্লিক করলে কাজ করবে
            onPressed: () async {
              await Navigator.pushNamed(context, '/settings');
              // সেটিংস থেকে ফিরে আসার পর ডেটা রিলোড করা
              _loadAllData();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Dua Selector Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
            child: _buildDuaSelector(localizations),
          ),
          const Spacer(),
          // Main Counter
          _buildCounter(currentDua, localizations, progress),
          const Spacer(),
          // Bottom Action Buttons
          _buildActionButtons(localizations),

          // "সব রিসেট" বাটনটি নিচে আনা হয়েছে
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: TextButton.icon(
              onPressed: _resetAllCounters,
              icon: const Icon(Icons.delete_sweep_outlined),
              label: Text(localizations.translate('reset_all_counters')),
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            ),
          ),

          // Padding for the system navigation bar (Edge-to-Edge)
          SizedBox(height: bottomPadding > 0 ? bottomPadding : 16),
        ],
      ),
    );
  }

  Widget _buildDuaSelector(AppLocalizations localizations) {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: Color(0xFFE9EEFF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black, width: 0.5),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () => _pageController.previousPage(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _duas.length,
              onPageChanged: (index) {
                setState(() {
                  _currentDuaIndex = index;
                });
                _saveDuaProgress();
              },
              itemBuilder: (context, index) {
                final dua = _duas[index];
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
                      // এখানে localization ব্যবহার করে নাম দেখানো হচ্ছে
                      child: Text(
                        localizations.translate(dua.nameKey),
                        key: ValueKey<String>(dua.id),
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dua.arabicText,
                      style: const TextStyle(fontSize: 18, fontFamily: 'NotoNaskhArabic'),
                    ),
                  ],
                );
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios),
            onPressed: () => _pageController.nextPage(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCounter(DuaModel currentDua, AppLocalizations localizations, double progress) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 250,
          height: 250,
          child: CircularProgressIndicator(
            value: progress,
            strokeWidth: 15,
            backgroundColor: Colors.grey.shade300,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.teal),
          ),
        ),
        Column(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: Text(
                _toBengaliNumerals(currentDua.currentCount),
                key: ValueKey<int>(currentDua.currentCount),
                style: const TextStyle(fontSize: 90, fontWeight: FontWeight.bold),
              ),
            ),
            Text(
              "${localizations.translate('target')}: ${_toBengaliNumerals(currentDua.targetCount)}",
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            )
          ],
        )
      ],
    );
  }

  Widget _buildActionButtons(AppLocalizations localizations) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.refresh),
            iconSize: 32,
            tooltip: localizations.translate('reset_current_dua'),
            onPressed: _resetCurrentCounter,
            color: Colors.grey.shade600,
          ),
          SizedBox(
            width: 90,
            height: 90,
            child: InkWell(
              onTap: _incrementCounter,
              borderRadius: BorderRadius.circular(45),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF26A69A), // Teal color
                  boxShadow: [
                    BoxShadow(
                      color: Colors.teal.withOpacity(0.4),
                      blurRadius: 15,
                      spreadRadius: 2,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Image.asset("assets/images/tasbeeh.png", color: Colors.white),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_border),
            iconSize: 32,
            tooltip: localizations.translate('save_bookmark'),
            onPressed: () {
              _saveDuaProgress();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(localizations.translate('progress_saved'))),
              );
            },
            color: Colors.grey.shade600,
          ),
        ],
      ),
    );
  }
}