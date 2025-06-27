import 'package:flutter/material.dart';

dynamic instructionsModal(BuildContext context, translate, isEnglish, Function onClose){
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return Semantics(
        label: translate('Instructions dialog', isEnglish: isEnglish ?? true),
        explicitChildNodes: true,
        child: AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Semantics(
            header: true,
            child: Text(
              translate('Welcome to AYN', isEnglish: isEnglish ?? true),
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ),
          content: Semantics(
            label: translate('Instructions content', isEnglish: isEnglish ?? true),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Paragraph 1
                  Semantics(
                    label: translate('App introduction', isEnglish: isEnglish ?? true),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        translate('''This app helps blind or visually impaired users understand their surroundings using the phone’s camera. It supports both English and Arabic. It can describe scenes, objects, people, read text, identify barcodes, medications, currency, and clothing, and responds to voice commands.''', isEnglish: isEnglish ?? true),
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),

                  // Paragraph 2
                  Semantics(
                    label: translate('Navigation overview', isEnglish: isEnglish ?? true),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        translate('''Navigating is simple. Top-left has Settings. Top-right has Help. Double-tap either to access them.''', isEnglish: isEnglish ?? true),
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),

                  // Paragraph 3
                  Semantics(
                    label: translate('Tab descriptions', isEnglish: isEnglish ?? true),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        translate('''At the bottom, swipe between three tabs: Describe (scene descriptions), Read (text reader), and More (special modes).''', isEnglish: isEnglish ?? true),
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),

                  // Paragraph 4
                  Semantics(
                    label: translate('Camera button usage', isEnglish: isEnglish ?? true),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        translate('''In Describe or Read mode, double-tap the center button to capture. In Video mode, it starts or stops recording.''', isEnglish: isEnglish ?? true),
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),

                  // Paragraph 5
                  Semantics(
                    label: translate('Microphone and camera switch', isEnglish: isEnglish ?? true),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        translate('''On the left is the Microphone button for voice commands. On the right is the Camera Switch to toggle front/rear camera.''', isEnglish: isEnglish ?? true),
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),

                  // Paragraph 6
                  Semantics(
                    label: translate('Modes list', isEnglish: isEnglish ?? true),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        translate('''Modes include: Picture Describe, Document Reader, Video Mode, Barcode Scanner, Medication ID, Currency ID, Outfit ID, and Voice Mode.''', isEnglish: isEnglish ?? true),
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),

                  // Paragraph 7
                  Semantics(
                    label: translate('Voice mode behavior', isEnglish: isEnglish ?? true),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        translate('''Voice mode answers only based on previous images. It does not access the live camera. Use Describe mode for real-time feedback.''', isEnglish: isEnglish ?? true),
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),

                  // Paragraph 8
                  Semantics(
                    label: translate('Voice examples', isEnglish: isEnglish ?? true),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        translate('''After capturing, ask: “What did you see earlier?”, “Read the text again”, or “What was the medication name?”''', isEnglish: isEnglish ?? true),
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),

                  // Paragraph 9
                  Semantics(
                    label: translate('Tips and reminders', isEnglish: isEnglish ?? true),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        translate('''Tips: The flash turns on for currency. Show medicine packaging clearly. Hold steady when reading.''', isEnglish: isEnglish ?? true),
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),

                  // Paragraph 10
                  Semantics(
                    label: translate('Error messages', isEnglish: isEnglish ?? true),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        translate('''Errors include: “Camera error”, “No barcode found”, or “Unable to identify”. Try again if that happens.''', isEnglish: isEnglish ?? true),
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),

                  // Paragraph 11
                  Semantics(
                    label: translate('Language support', isEnglish: isEnglish ?? true),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        translate('''AYN supports English and Arabic. Change the language in Settings.''', isEnglish: isEnglish ?? true),
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),

                  // Paragraph 12
                  Semantics(
                    label: translate('Help reminder', isEnglish: isEnglish ?? true),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        translate('''Need help? Double-tap Help or ask your question with voice.''', isEnglish: isEnglish ?? true),
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),

                  // Paragraph 13
                  Semantics(
                    label: translate('Encouragement', isEnglish: isEnglish ?? true),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        translate('''Enjoy using Visual Assistant AYN to explore the world more independently and confidently.''', isEnglish: isEnglish ?? true),
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            Semantics(
              button: true,
              label: translate('Close instructions', isEnglish: isEnglish ?? true),
              hint: translate('Double tap to close instructions dialog', isEnglish: isEnglish ?? true),
              child: TextButton(
                onPressed: () {onClose();},
                child: Text(
                  translate('Close', isEnglish: isEnglish ?? true),
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}