import 'dart:async';
import 'package:flutter/material.dart';
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
    flutterTts.stop();
    super.dispose();
  }

  void startInactivityTimer() {
    _inactivityTimer?.cancel(); // clear old timer
    _inactivityTimer = Timer.periodic(const Duration(seconds: 45), (_) {
      speakInstructions();
    });
  }

  Future<void> speakInstructions() async {
    _inactivityTimer?.cancel(); // Stop existing timer while speaking

    await flutterTts.stop();
    await flutterTts.setSpeechRate(0.45);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);
    await flutterTts.awaitSpeakCompletion(true);

    await flutterTts.setLanguage("ar-SA");
    await flutterTts.speak(_welcomeMessageAr);
    // Wait until Arabic speaking is done
    await Future.delayed(const Duration(milliseconds: 500));

    await flutterTts.setLanguage("en-US");
    await flutterTts.speak(_welcomeMessageEn);
    // Wait for English to complete before starting timer
    await flutterTts.awaitSpeakCompletion(true);

    // Now start the inactivity timer AFTER both instructions finish
    startInactivityTimer();
  }


  Future<void> setLanguage(String langCode) async {
    _inactivityTimer?.cancel();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString("language", langCode);

    if (langCode == 'EN') {
      await flutterTts.setLanguage("en-US");
      await flutterTts.speak("English selected");
    } else {
      await flutterTts.setLanguage("ar-SA");
      await flutterTts.speak("تم اختيار اللغة العربية");
    }

    await prefs.setBool("first_time", false);

    // Ask if user wants instructions
    await flutterTts.setLanguage(langCode == 'EN' ? "en-US" : "ar-SA");
    await flutterTts.awaitSpeakCompletion(true);
    await flutterTts.speak(langCode == 'EN'
        ? "Would you like to hear the instructions for using the app? Please say yes or no."
        : "هل ترغب في سماع التعليمات الخاصة باستخدام التطبيق؟ قل نعم أو لا.");

    await flutterTts.awaitSpeakCompletion(true);

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
      await flutterTts.awaitSpeakCompletion(true);
      await flutterTts.speak(langCode == 'EN'
        ? '''
        Instructions: 
        Triple tap anywhere to switch the camera. 
        Double tap to take a photo and ask your question.
        Long press to record a video.
        After image or video is captured, you can ask a question using your voice.
        The assistant will describe what it sees and answer.
        '''
                : '''
        التعليمات:
        انقر ثلاث مرات في أي مكان للتبديل بين الكاميرات.
        انقر مرتين لالتقاط صورة واطرح سؤالك.
        اضغط مطولاً لتسجيل فيديو.
        بعد التقاط الصورة أو الفيديو، يمكنك طرح سؤال صوتي.
        المساعد سيصف ما يراه ويجيب.
        ''');
      await flutterTts.awaitSpeakCompletion(true);
    } else {
      await flutterTts.speak(langCode == 'EN'
          ? "Skipping instructions."
          : "سيتم تخطي التعليمات.");
      await flutterTts.awaitSpeakCompletion(true);
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

          await flutterTts.stop();
          await flutterTts.awaitSpeakCompletion(true); // <-- must be before speaking
          if (label == 'EN') {
            await flutterTts.setLanguage("en-US");
            await flutterTts.speak("English");
          } else {
            await flutterTts.setLanguage("ar-SA");
            await flutterTts.speak("العربية");
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
