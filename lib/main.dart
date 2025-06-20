import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

List<CameraDescription> cameras = [];
const String apiKey = 'fmFrMl3wHnB9SFnb8bzxNFpGCVE18Wcz';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(BlindAssistApp());
}

class BlindAssistApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Blind Assist',
      home: AssistHomePage(),
    );
  }
}

class AssistHomePage extends StatefulWidget {
  @override
  _AssistHomePageState createState() => _AssistHomePageState();
}

class _AssistHomePageState extends State<AssistHomePage> {
  late CameraController _cameraController;
  final FlutterTts _flutterTts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();
  // for handling the video thing
  bool _isVideoMode = false;
  bool _isRecording = false;
  String? _videoPath;
  // for managing the taps
  Timer? _tapTimer;
  int _tapCount = 0;


  @override
  void initState() {
    super.initState();
    _initializeCamera();
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
    _tapTimer?.cancel();
    _tapTimer = Timer(const Duration(milliseconds: 400), () {
      if (_tapCount == 3) {
        _handleTripleTap();
      } else if (_tapCount == 2) {
        _handleDoubleTap();
      }
      _tapCount = 0;
    });
  }

  Future<void> _handleTripleTap() async {
    await _flutterTts.speak("Triple tap detected. Switching camera.");
    // Find the index of the current camera
    final currentCameraIndex = cameras.indexOf(_cameraController.description);
    // Switch to the next camera (wrapping around if at the end)
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
    final picture = await _cameraController.takePicture();
    print("Picture taken: ${picture.path}");
    // await _flutterTts.speak("Picture taken. Ask your question now."); // next code not waiting for the sentence to finish
    await _callFanarApi(query: "", image: File(picture.path)); // testing

    // if (await _ensureMicPermission()) {
    //   final systemLocale = await _speech.systemLocale();
    //   final localeId = systemLocale?.localeId ?? 'en_US';
    //   print("Using locale: $localeId");

    //   final available = await _speech.initialize(
    //     onStatus: (status) {
    //       print("STT status: $status");
    //       if (status == "notListening") {
    //         print("STT finished listening");
    //       }
    //     },
    //     onError: (error) {
    //       print("STT error: $error");
    //     },
    //   );

    //   print("STT available: $available");
    //   print("STT listening: ${_speech.isListening}");
    //   print("Supported locales: ${await _speech.locales()}");

    //   if (!available) {
    //     await _flutterTts.speak("Speech recognition is not available.");
    //     return;
    //   }

    //   _speech.listen(
    //     localeId: localeId,
    //     listenFor: Duration(seconds: 15),
    //     pauseFor: Duration(seconds: 3),
    //     partialResults: true,
    //     cancelOnError: true,
    //     onResult: (result) async {
    //       final query = result.recognizedWords;
    //       print("Recognized: $query");
    //       if (query.isNotEmpty) {
    //         await _speech.stop();
    //         await _callFanarApi(query: query, image: File(picture.path));
    //       }
    //     },
    //   );

    //   Future.delayed(Duration(seconds: 16), () async {
    //     if (_speech.isListening) {
    //       await _speech.stop();
    //       final lastWords = _speech.lastRecognizedWords;
    //       print("Fallback recognized: $lastWords");
    //       if (lastWords.isNotEmpty) {
    //         await _callFanarApi(query: lastWords, image: File(picture.path));
    //       } else {
    //         await _flutterTts.speak("I couldn't hear your question. Please try again.");
    //       }
    //     }
    //   });
    // }
  }

  // video recording functions:
  Future<void> _startVideoRecording() async {
    if (_cameraController.value.isRecordingVideo) return;
    try {
      await _cameraController.prepareForVideoRecording();
      await _cameraController.startVideoRecording();
      // _videoPath = file.path; 
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
      await _callFanarApi(query: "", videoFile: File(_videoPath!)); // for testing
      // uncomment afterwards:
      // if (await _ensureMicPermission()) {
      //   final locale = (await _speech.systemLocale())?.localeId ?? 'en_US';
      //   final initialized = await _speech.initialize();

      //   if (!initialized) {
      //     await _flutterTts.speak("Speech recognition is not available.");
      //     return;
      //   }

      //   _speech.listen(
      //     localeId: locale,
      //     listenFor: Duration(seconds: 15),
      //     onResult: (result) async {
      //       final query = result.recognizedWords;
      //       print("Recognized voice: $query");
      //       if (query.isNotEmpty) {
      //         await _speech.stop();
      //         await _callFanarApi(query: query, videoFile: File(_videoPath!));
      //       }
      //     },
      //   );

      //   Future.delayed(Duration(seconds: 16), () async {
      //     if (_speech.isListening) {
      //       await _speech.stop();
      //       final fallback = _speech.lastRecognizedWords;
      //       if (fallback.isNotEmpty) {
      //         await _callFanarApi(query: fallback, videoFile: File(_videoPath!));
      //       } else {
      //         await _flutterTts.speak("I didn't catch that. Try again.");
      //       }
      //     }
      //   });
      // }
    } catch (e) {
      print("Error stopping video: $e");
      await _flutterTts.speak("Error recording video.");
    }
  }


  // the actual API
  Future<void> _callFanarApi({required String query, File? image, File? videoFile}) async {
    final uri = Uri.parse('https://api.fanar.qa/v1/chat/completions');
    final headers = {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    };

    List content = [
      {
        "type": "text",
        // "text": "You are a voice assistant for the blind. Describe the video briefly and clearly in Arabic or English. Avoid phrases like 'in the video'. Focus on useful details only.",
        "text": image != null ? // different prompts for image and video
        '''
          You are a voice assistant for the blind. Describe ONLY essential objects and their immediate location in 1 sentence maximum. Use 3-5 words if possible.
          RULES:

          NO colors, textures, lighting, or decorative details

          NO speculation (e.g., "potentially", "appears to be")

          NO phrases like "in the image" or "we see"

          ONLY include objects critical for navigation/safety (e.g., doors, stairs, vehicles, people)

          Structure: [Object] [location/preposition] [surface/context]
          Example: 'Bottle on table'"
        ''' : 
        "You are a voice assistant for the blind. Describe the video briefly and clearly in Arabic or English. Avoid phrases like 'in the video'. Focus on useful details only."
      },
    ];

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
      final response = await http.post(uri, headers: headers, body: body);
      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        final reply = responseBody["choices"][0]["message"]["content"];
        print("Fanar reply: $reply");
        await _flutterTts.speak(reply);
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
      onDoubleTap: _handleDoubleTap,
      onLongPressStart: (_) => _startVideoRecording(),
      onLongPressEnd: (_) => _stopVideoRecordingAndSend(),
  


      // experimenting for one tap and then hold: video mode

      // onTap: () {
      //   _handleTap(); // still supports double/triple taps
      //   if (!_isVideoMode) {
      //     _isVideoMode = true;
      //     _flutterTts.speak("Video mode activated. Hold to record.");

      //     Future.delayed(Duration(seconds: 10), () {
      //       if (_isVideoMode && !_isRecording) {
      //         _isVideoMode = false;
      //         // _flutterTts.speak("Video mode cancelled due to inactivity.");
      //       }
      //     });
      //   }
      // },
      // // one tap and then hold: video mode
      // onTapDown: (_) {
      //   if (_isVideoMode && !_isRecording) {
      //     _startVideoRecording();
      //   }
      // },
      // onTapUp: (_) {
      //   if (_isVideoMode && _isRecording) {
      //     _stopVideoRecordingAndSend();
      //     _isVideoMode = false;
      //   }
      // },
      // onTapCancel: () {
      //   if (_isVideoMode && _isRecording) {
      //     _stopVideoRecordingAndSend();
      //     _isVideoMode = false;
      //   }
      // },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CameraPreview(_cameraController)),
      ),
    );
  }
}