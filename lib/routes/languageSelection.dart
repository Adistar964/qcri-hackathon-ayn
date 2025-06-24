import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
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
  final String _welcomeMessageEn =
      "Welcome to AYN. Please select a language from the buttons given. Tap once to hear the language. Double tap to select.";
  final String _welcomeMessageAr =
      "أهلاً بك في عين. يُرجى اختيار لغة من الأزرار المُتاحة. انقر مرة واحدة لسماع اللغة. انقر مرتين للاختيار.";

  Timer? _inactivityTimer;

  @override
  void initState() {
    super.initState();
    speakInstructions();
    startInactivityTimer();
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    super.dispose();
  }

  void _announceToScreenReader(String message, {TextDirection? direction}) {
    SemanticsBinding.instance.ensureSemantics();
    // If Arabic detected, use RTL, else LTR
    final isArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(message);
    SemanticsService.announce(
      message,
      direction ?? (isArabic ? TextDirection.rtl : TextDirection.ltr),
    );
  }

  void startInactivityTimer() {
    _inactivityTimer?.cancel(); // clear old timer
    _inactivityTimer = Timer.periodic(const Duration(seconds: 45), (_) {
      speakInstructions();
    });
  }

  Future<void> speakInstructions() async {
    _inactivityTimer?.cancel(); // Stop existing timer while speaking

    _announceToScreenReader(_welcomeMessageAr, direction: TextDirection.rtl);
    await Future.delayed(const Duration(milliseconds: 1500));
    _announceToScreenReader(_welcomeMessageEn, direction: TextDirection.ltr);
    await Future.delayed(const Duration(milliseconds: 2500));

    // Now start the inactivity timer AFTER both instructions finish
    startInactivityTimer();
  }

  Future<void> setLanguage(String langCode) async {
    _inactivityTimer?.cancel();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString("language", langCode);

    if (langCode == 'EN') {
      _announceToScreenReader("English selected", direction: TextDirection.ltr);
    } else {
      _announceToScreenReader("تم اختيار اللغة العربية", direction: TextDirection.rtl);
    }

    await prefs.setBool("first_time", false);

    // Ask if user wants instructions
    await Future.delayed(const Duration(milliseconds: 800));
    _announceToScreenReader(
      langCode == 'EN'
        ? "Would you like to hear the instructions for using the app? Please say yes or no."
        : "هل ترغب في سماع التعليمات الخاصة باستخدام التطبيق؟ قل نعم أو لا.",
      direction: langCode == 'EN' ? TextDirection.ltr : TextDirection.rtl,
    );

    await Future.delayed(const Duration(milliseconds: 2000));

    final localeId = langCode == 'EN' ? 'en_US' : 'ar_SA';

    bool available = await _speech.initialize(
      onStatus: (status) => print("Speech status: $status"),
      onError: (error) => print("Speech error: $error"),
    );

    String resultText = "";
    if (available) {
      _speech.listen(
        localeId: localeId,
        listenFor: const Duration(seconds: 5),
        pauseFor: const Duration(seconds: 2),
        partialResults: false,
        onResult: (result) {
          resultText = result.recognizedWords.toLowerCase();
        },
      );

      await Future.delayed(const Duration(seconds: 6));
      await _speech.stop();
    }

    bool wantsInstructions = false;

    if (langCode == 'EN') {
      wantsInstructions = resultText.contains("yes");
    } else {
      wantsInstructions = resultText.contains("نعم");
    }

    if (wantsInstructions) {
      await Future.delayed(const Duration(milliseconds: 500));
      _announceToScreenReader(
        langCode == 'EN'
          ? "Instructions: Triple tap anywhere to switch the camera. Double tap to take a photo and ask your question. Long press to record a video. After image or video is captured, you can ask a question using your voice. The assistant will describe what it sees and answer."
          : "التعليمات: انقر ثلاث مرات في أي مكان للتبديل بين الكاميرات. انقر مرتين لالتقاط صورة واطرح سؤالك. اضغط مطولاً لتسجيل فيديو. بعد التقاط الصورة أو الفيديو، يمكنك طرح سؤال صوتي. المساعد سيصف ما يراه ويجيب.",
        direction: langCode == 'EN' ? TextDirection.ltr : TextDirection.rtl,
      );
      await Future.delayed(const Duration(milliseconds: 4000));
    } else {
      _announceToScreenReader(
        langCode == 'EN'
          ? "Skipping instructions."
          : "سيتم تخطي التعليمات.",
        direction: langCode == 'EN' ? TextDirection.ltr : TextDirection.rtl,
      );
      await Future.delayed(const Duration(milliseconds: 1000));
    }

    context.go("/");
  }

  Widget languageButton(String label, String langCode) {
    return Semantics(
      label: label == "EN"
          ? "Select English. Double tap to choose English language."
          : "اختر العربية. انقر مرتين لاختيار اللغة العربية.",
      button: true,
      child: GestureDetector(
        onTap: () async {
          // Haptic feedback on single tap
          Feedback.forTap(context);

          if (label == 'EN') {
            _announceToScreenReader("English", direction: TextDirection.ltr);
          } else {
            _announceToScreenReader("العربية", direction: TextDirection.rtl);
          }
        },
        onDoubleTap: () {
          // Stronger feedback on language selection
          Feedback.forLongPress(context);
          setLanguage(langCode);
        },
        child: Container(
          width: double.infinity,
          height: 90, // Increased from 70 to 90
          margin: const EdgeInsets.symmetric(vertical: 12), // slightly larger spacing
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 28, // larger font size
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FocusTraversalGroup(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Semantics(
                header: true,
                label: 'Language selection screen',
                child: const Text(
                  "Select Language",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 50),
              languageButton("EN", "EN"),
              const SizedBox(height: 30),
              languageButton("AR", "AR"),
            ],
          ),
        ),
      ),
    );
  }
}