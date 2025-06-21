import 'package:ayn/components/mic_status.dart';
import 'package:ayn/components/mode_controls.dart';
import 'package:ayn/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class AssistHomePage extends StatefulWidget {
  @override
  State<AssistHomePage> createState() => _AssistHomePageState();
}

class _AssistHomePageState extends State<AssistHomePage> {
  late CameraController _cameraController;
  final String apikey = "fmFrMl3wHnB9SFnb8bzxNFpGCVE18Wcz";
  final FlutterTts _flutterTts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();

  List modes = ["picture", "barcode", "document reader", "video"];
  String currentMode = "picture";
  bool _isRecording = false;
  String? _videoPath;

  Timer? _tapTimer;
  int _tapCount = 0;

  final Map<String, dynamic> _sessionContext = {};

  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Configure TTS to wait for completion
      await _flutterTts.awaitSpeakCompletion(true);
      
      final prefs = await SharedPreferences.getInstance();
      final lang = prefs.getString("language") ?? "EN";

      if (lang == "AR") {
        await _flutterTts.setLanguage("ar-SA");
        await _flutterTts.speak("أنت الآن في الشاشة الرئيسية للمساعد.");
      } else {
        await _flutterTts.setLanguage("en-US");
        await _flutterTts.speak("You are now on the assist home screen.");
      }
    });
  }


  Future<void> _initializeCamera() async {
    print("Initializing camera...");
    _cameraController = CameraController(cameras.first, ResolutionPreset.medium);
    await _cameraController.initialize();
    setState(() {});
  }

  Future<bool> _ensureMicPermission() async {
    final micStatus = await Permission.microphone.request();
    return micStatus.isGranted;
  }

  void _handleTap() {
    _tapCount++;
    if (_tapCount == 1) {
      _tapTimer = Timer(const Duration(milliseconds: 300), () {
        if (_tapCount == 1) {
          _handleSingleTap();
        } else if (_tapCount == 2) {
          _handleDoubleTap();
        } else if (_tapCount == 3){
          _handleTripleTap();
        }
        _tapCount = 0;
      });
    } else if (_tapCount == 3) {
      _tapTimer?.cancel();
      _handleTripleTap();
      _tapCount = 0;
    }
  }

  Future<void> _handleSingleTap() async {
    // if (currentMode == "picture") {
      await _startSpeechListeningOnly();
    // }
  }

  Future<void> _handleTripleTap() async {
    await _flutterTts.speak("Triple tap detected. Switching camera.");
    final currentCameraIndex = cameras.indexOf(_cameraController.description);
    final nextCameraIndex = (currentCameraIndex + 1) % cameras.length;
    await _initCamera(nextCameraIndex);
  }

  Future<void> _initCamera(int cameraIndex) async {
    if (_cameraController != null) {
      await _cameraController.dispose();
    }
    _cameraController = CameraController(
      cameras[cameraIndex],
      ResolutionPreset.medium,
    );
    await _cameraController.initialize();
    if (mounted) setState(() {});
  }

  Future<void> _handleDoubleTap() async {
    if (currentMode == "picture") {
      await _handlePictureMode();
    } else if (currentMode == "video") {
      if (!_isRecording) {
        await _startVideoRecording();
        await _flutterTts.speak("Video started");
      } else {
        await _stopVideoRecordingAndSend();
      }
    } else if (currentMode == "barcode") {
      await _handleBarcodeScan();
    } else if (currentMode == "document reader") {
      await _handleDocumentRead();
    }
  }

  // New: Listen via mic only, no picture capture
  Future<void> _startSpeechListeningOnly() async {
    if (await _ensureMicPermission()) {
      final systemLocale = await _speech.systemLocale();
      final localeId = systemLocale?.localeId ?? 'en_US';

      final available = await _speech.initialize(
        onStatus: (status) async {
          print("STT status: $status");
          if (status == "notListening" || status == "done") {
            _isListening = false;
            setState(() {});
          }
        },
        onError: (error) {
          print("STT error: $error");
          _isListening = false;
          setState(() {});
        },
      );

      if (!available) {
        await _flutterTts.speak("Speech recognition is not available.");
        return;
      }

      _isListening = true;
      setState(() {});

      // Wait for TTS to finish before starting listening
      await _flutterTts.speak("Please speak your question.");

      await _speech.listen(
        localeId: localeId,
        listenFor: Duration(seconds: 20),
        pauseFor: Duration(seconds: 3),
        listenOptions: stt.SpeechListenOptions(
          partialResults: false,
          cancelOnError: true,
          listenMode: stt.ListenMode.dictation,
        ),
        onResult: (result) async {
          final query = result.recognizedWords;
          print("Recognized query (no pic): $query");
          if (query.isNotEmpty) {
            await _speech.stop();
            _isListening = false;
            setState(() {});
            _sessionContext['last_question'] = query;
            await _callFanarApi(query: query);
          }
        },
      );

      // Safety fallback timeout
      Future.delayed(Duration(seconds: 16), () async {
        if (_speech.isListening) {
          await _speech.stop();
          _isListening = false;
          setState(() {});
          final lastWords = _speech.lastRecognizedWords;
          if (lastWords.isNotEmpty) {
            _sessionContext['last_question'] = lastWords;
            await _callFanarApi(query: lastWords);
          } else {
            await _flutterTts.speak("I couldn't hear your question. Please try again.");
          }
        }
      });
    }
  }

  // Keep existing picture mode double tap handler
  Future<void> _handlePictureMode() async {
    final picture = await _cameraController.takePicture();
    print("Picture taken: ${picture.path}");

    // Wait for TTS to finish before starting listening
    await _flutterTts.speak("Picture taken. Please ask your question.");

    if (await _ensureMicPermission()) {
      final systemLocale = await _speech.systemLocale();
      final localeId = systemLocale?.localeId ?? 'en_US';

      final available = await _speech.initialize(
        onStatus: (status) {
          print("STT status: $status");
          if (status == "notListening" || status == "done") {
            _isListening = false;
            setState(() {});
          }
        },
        onError: (error) {
          print("STT error: $error");
          _isListening = false;
          setState(() {});
        },
      );

      if (!available) {
        await _flutterTts.speak("Speech recognition is not available.");
        return;
      }

      _isListening = true;
      setState(() {});

      await _speech.listen(
        localeId: localeId,
        listenFor: Duration(seconds: 20),
        pauseFor: Duration(seconds: 3),
        listenOptions: stt.SpeechListenOptions(
          partialResults: false,
          cancelOnError: true,
        ),
        onResult: (result) async {
          final query = result.recognizedWords;
          print("Recognized: $query");
          if (query.isNotEmpty) {
            await _speech.stop();
            _isListening = false;
            setState(() {});
            _sessionContext['last_question'] = query;
            await _callFanarApi(query: query, image: File(picture.path));
          }
        },
      );

      Future.delayed(Duration(seconds: 16), () async {
        if (_speech.isListening) {
          await _speech.stop();
          _isListening = false;
          setState(() {});
          final lastWords = _speech.lastRecognizedWords;
          if (lastWords.isNotEmpty) {
            _sessionContext['last_question'] = lastWords;
            await _callFanarApi(query: lastWords, image: File(picture.path));
          } else {
            await _flutterTts.speak("I couldn't hear your question. Please try again.");
          }
        }
      });
    }
  }

  // Barcode and other handlers unchanged
  Future<void> _handleBarcodeScan() async {
    try {
      final picture = await _cameraController.takePicture();
      final barcode = await _detectBarcode(File(picture.path));

      if (barcode == null) {
        await _flutterTts.speak("No barcode detected.");
        return;
      }

      final url = Uri.parse("https://world.openfoodfacts.org/api/v0/product/$barcode.json");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final productName = result["product"]?["product_name"] ?? "Product name not available.";
        await _flutterTts.speak(productName);
      } else {
        await _flutterTts.speak("Product not found.");
      }
    } catch (e) {
      print("Barcode scan error: $e");
      await _flutterTts.speak("An error occurred while scanning the barcode.");
    }
  }

  Future<String?> _detectBarcode(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final barcodeScanner = BarcodeScanner(formats: [BarcodeFormat.all]);

    final barcodes = await barcodeScanner.processImage(inputImage);

    await barcodeScanner.close();

    if (barcodes.isEmpty) return null;
    return barcodes.first.rawValue;
  }

  Future<void> _handleDocumentRead() async {
    try {
      final picture = await _cameraController.takePicture();
      final imageFile = File(picture.path);

      await _flutterTts.speak("Reading the document. Please wait.");
      await _callFanarApi(
        query: "Extract and return the exact text from this document without any modifications, summaries, or added commentary. Preserve original formatting (e.g., line breaks, lists) to ensure screen-reader compatibility. If the document includes images or tables, provide their alt text or describe their structure. Do not alter, abbreviate, or paraphrase any content.",
        image: imageFile,
      );
    } catch (e) {
      print("❌ Document reading error: $e");
      await _flutterTts.speak("There was an error reading the document.");
    }
  }

  Future<void> _startVideoRecording() async {
    if (_cameraController.value.isRecordingVideo) return;
    try {
      await _cameraController.prepareForVideoRecording();
      await _cameraController.startVideoRecording();
      _isRecording = true;
      print("Started recording video.");
    } catch (e) {
      print("Error starting video recording: $e");
    }
  }

  Future<void> _stopVideoRecordingAndSend() async {
    if (!_isRecording || !_cameraController.value.isRecordingVideo) return;

    try {
      final file = await _cameraController.stopVideoRecording();
      _isRecording = false;
      _videoPath = file.path;
      print("Stopped recording: $_videoPath");

      await _flutterTts.speak("Video recorded. Please ask your question.");
      final String videoPromptEnglish = "You are a voice assistant for the blind. Describe the video briefly and clearly in Arabic or English. Avoid phrases like 'in the video'. Focus on useful details only.";
      await _callFanarApi(query: videoPromptEnglish, videoFile: File(_videoPath!));
    } catch (e) {
      print("Error stopping video: $e");
      await _flutterTts.speak("Error recording video.");
    }
  }

  void _switchMode(double velocity) async {
    int currentIndex = modes.indexOf(currentMode);
    if (velocity > 0) {
      currentIndex = (currentIndex - 1 + modes.length) % modes.length;
    } else {
      currentIndex = (currentIndex + 1) % modes.length;
    }

    // Stop any speech recognition before switching
    await _speech.stop();
    _isListening = false;
    setState(() {});

    currentMode = modes[currentIndex];
    setState(() {});

    await _flutterTts.stop();
    await _flutterTts.speak("Mode changed to $currentMode");

    // Removed wake word listening start
  }

  Future<void> _callFanarApi({required String query, File? image, File? videoFile}) async {
    final uri = Uri.parse('https://api.fanar.qa/v1/chat/completions');
    final headers = {
      'Authorization': 'Bearer $apikey',
      'Content-Type': 'application/json',
    };

    List content = [];

    if (_sessionContext.isNotEmpty) {
      content.add({
        "type": "text",
        "text": "Previous context: ${_sessionContext.entries.map((e) => '${e.key}: ${e.value}').join(', ')}",
      });
    }

    content.add({
      "type": "text",
      "text": query,
    });

    if (image != null) {
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);
      content.add({
        "type": "image_url",
        "image_url": {
          "url": "data:image/jpeg;base64,$base64Image",
        },
      });
    } else if (videoFile != null) {
      final bytes = await videoFile.readAsBytes();
      final base64Video = base64Encode(bytes);
      content.add({
        "type": "video_url",
        "video_url": {
          "url": "data:video/mp4;base64,$base64Video",
        },
      });
    }

    final body = jsonEncode({
      "model": "Fanar-Oryx-IVU-1",
      "messages": [
        {
          "role": "user",
          "content": content,
        },
      ],
    });

    try {
      _sessionContext['last_mode'] = currentMode;
      _sessionContext['last_time'] = DateTime.now().toIso8601String();
      final response = await http.post(uri, headers: headers, body: body);
      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        final reply = responseBody["choices"][0]["message"]["content"];
        print("Fanar reply: $reply");
        await _flutterTts.speak(reply);
        print("✅ Session context: $_sessionContext");
      } else {
        print("API error: ${response.statusCode}");
        await _flutterTts.speak("Error: ${response.statusCode}");
      }
    } catch (e) {
      print("API error: $e");
      await _flutterTts.speak("Error connecting to Fanar API.");
    }
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _flutterTts.stop();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_cameraController.value.isInitialized) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return GestureDetector(

      onTap: _handleTap,
      onHorizontalDragEnd: (details) { // on swipe
        _switchMode(details.primaryVelocity ?? 0);
      },

      child: Stack(
        children: [

          Center(child: CameraPreview(_cameraController)),

          ModeControls(modes: modes, currentMode: currentMode),
      
          if (currentMode == "picture" && _isListening) MicStatus(),

        ],
      ),
    );
  }
}
