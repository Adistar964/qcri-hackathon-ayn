import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class LanguageSelectionPage extends StatefulWidget {
  const LanguageSelectionPage({super.key});

  @override
  State<LanguageSelectionPage> createState() => _LanguageSelectionPageState();
}

class _LanguageSelectionPageState extends State<LanguageSelectionPage> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts flutterTts = FlutterTts();
  Timer? _inactivityTimer;

  final String _welcomeMessageEn =
      "Welcome to AYN. Please select a language from the buttons given.";
  final String _welcomeMessageAr =
      "مرحبًا بكم في عين. يرجى اختيار لغة من الأزرار المعروضة.";

  @override
  void initState() {
    super.initState();
    flutterTts.awaitSpeakCompletion(true);
    speakInstructions();
    startInactivityTimer();
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    super.dispose();
  }

  void startInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer.periodic(const Duration(seconds: 45), (_) {
      speakInstructions();
    });
  }

  Future<void> speakInstructions() async {
    _inactivityTimer?.cancel();
    await _announceToScreenReader(_welcomeMessageAr, direction: TextDirection.rtl);
    await Future.delayed(const Duration(milliseconds: 800));
    await _announceToScreenReader(_welcomeMessageEn, direction: TextDirection.ltr);
    await Future.delayed(const Duration(milliseconds: 2500));
  }

  Future<void> _announceToScreenReader(String message, {TextDirection? direction}) async {
    SemanticsBinding.instance.ensureSemantics();
    final isArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(message);
    SemanticsService.announce(
      message,
      direction ?? (isArabic ? TextDirection.rtl : TextDirection.ltr),
    );
    await flutterTts.stop();
    await flutterTts.setLanguage(isArabic ? "ar" : "en");
    await flutterTts.speak(message);
  }

  Future<void> setLanguage(String langCode) async {
    _inactivityTimer?.cancel();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString("language", langCode);
    await prefs.setBool("first_time", false);

    // await _announceToScreenReader(
    //   langCode == 'EN' ? "English selected" : "تم اختيار اللغة العربية",
    //   direction: langCode == 'EN' ? TextDirection.ltr : TextDirection.rtl,
    // );

    context.go("/");
  }

  Widget languageButton({
    required String label,
    required String langCode,
    required String semanticsLabel,
  }) {
    return Semantics(
      label: semanticsLabel,
      button: true,
      child: GestureDetector(
        onTap: () => setLanguage(langCode),
        child: Container(
          height: 60,
          margin: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: Colors.lightBlueAccent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
                child: Text(
                  label,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Opacity(
            opacity: 0.9,
            child: Image.asset(
              'assets/bg2.jpg', // <- replace with your background image
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Semantics(
                  header: true,
                  child: Column(
                    children: const [
                      Text(
                        "WELCOME",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Let's Get Started",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 60),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    // color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "Select Language",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 10),
                      languageButton(
                        label: "ENGLISH",
                        langCode: "EN",
                        semanticsLabel: "Select English Button",
                      ),
                      languageButton(
                        label: "العربي",
                        langCode: "AR",
                        semanticsLabel: "حدد الزر العربي",
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}