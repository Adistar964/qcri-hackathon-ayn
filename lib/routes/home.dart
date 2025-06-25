import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' show join;
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

final List<String> allModes = [
  "picture describe",
  "document reader",
  "video",
  "barcode",
  "medication identifier",
  "currency",
  // "Light intensity detector",
  "outfit identifier",
];

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

final String apikey = "fmFrMl3wHnB9SFnb8bzxNFpGCVE18Wcz";

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  Future<void>? _initializeControllerFuture;
  bool _isFlashOn = false;
  List<CameraDescription> _cameras = [];
  late TabController? _tabController;
  String currentMode = "picture describe"; // Default mode
  bool _isRecording = false;
  String? _videoPath;
  final FlutterTts flutterTts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _voiceInput = '';

  List<Map<String, dynamic>> _sessionContext = [];

  int?
  _lastAnnouncedIndex; // For making sure the tab change doesnt repeatedly call announceScreenReader

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController!.addListener(_handleTabSelection);
    _setupCameras();
    _updateCurrentModeForTab(_tabController!.index);
    _sessionContext = [];
    _lastAnnouncedIndex = _tabController!.index; // Initialize with current tab
  }

  void _handleTabSelection() {
    // Update UI immediately when tab starts changing
    if (_tabController!.index != _tabController!.previousIndex) {
      setState(() => _updateCurrentModeForTab(_tabController!.index));
    }

    // Announce only when change is COMPLETE and tab is NEW
    if (!_tabController!.indexIsChanging &&
        _tabController!.index != _lastAnnouncedIndex) {
      final tabName = switch (_tabController!.index) {
        0 => "Picture Describe tab",
        1 => "Document Reader tab",
        _ => "Other Modes tab",
      };

      _announceToScreenReader("$tabName selected");
      _lastAnnouncedIndex = _tabController!.index; // Remember last announcement
    }
  }

  void _updateCurrentModeForTab(int tabIndex) {
    if (tabIndex == 0) {
      currentMode = "picture describe";
    } else if (tabIndex == 1) {
      currentMode = "document reader";
    } else {
      final otherModes = allModes
          .where(
            (mode) => mode != "picture describe" && mode != "document reader",
          )
          .toList();
      if (!otherModes.contains(currentMode)) {
        currentMode = otherModes.isNotEmpty ? otherModes.first : "";
      }
    }
  }

  Future<void> _setupCameras() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        await _initCamera(0);
      } else {
        _initializeControllerFuture = Future.error("No cameras found");
        _announceToScreenReader(
          "No cameras found or camera initialization failed.",
        );
      }
    } on CameraException catch (e) {
      _initializeControllerFuture = Future.error(e);
      _announceToScreenReader("Camera error: ${e.description}");
    }
  }

  Future<void> _initCamera(int cameraIndex) async {
    if (_cameraController != null) {
      await _cameraController!.dispose();
    }
    _cameraController = CameraController(
      _cameras[cameraIndex],
      ResolutionPreset.medium,
      enableAudio: false,
    );
    _initializeControllerFuture = _cameraController!
        .initialize()
        .then((_) {
          SemanticsBinding.instance.ensureSemantics();
        })
        .catchError((error) {
          if (error is CameraException) {
            switch (error.code) {
              case 'CameraAccessDenied':
                print(error);
                _announceToScreenReader(
                  "Camera access denied. Please grant permission in settings.",
                );
                break;
              default:
                print(error);
                _announceToScreenReader("Camera error occurred.");
                break;
            }
          }
        });
    if (mounted) setState(() {});
  }

  void _announceToScreenReader(String message) {
    // SemanticsBinding.instance.ensureSemantics();
    // SemanticsService.announce(message, TextDirection.ltr);
    flutterTts.stop();
    flutterTts.speak(message);
  }

  @override
  void dispose() {
    _tabController!.removeListener(_handleTabSelection);
    _tabController!.dispose();
    _cameraController?.dispose();
    flutterTts.stop();
    _sessionContext.clear(); // Clear context on app close
    super.dispose();
  }

  Future<void> _toggleFlash() async {
    try {
      if (_cameraController == null ||
          !_cameraController!.value.isInitialized) {
        throw Exception("Camera not initialized");
      }
      await _cameraController!.setFlashMode(
        _isFlashOn ? FlashMode.off : FlashMode.torch,
      );
      setState(() {
        _isFlashOn = !_isFlashOn;
      });
      _announceToScreenReader(
        _isFlashOn ? "Flashlight turned on" : "Flashlight turned off",
      );
    } catch (e) {
      print('Error toggling flash: $e');
      _announceToScreenReader("Failed to toggle flashlight");
    }
  }

  Future<void> callFanarAPI({
    required String query,
    File? image,
    File? videoFile,
  }) async {
    final uri = Uri.parse('https://api.fanar.qa/v1/chat/completions');
    final headers = {
      'Authorization': 'Bearer $apikey',
      'Content-Type': 'application/json',
    };
    List<dynamic>? currentContent;
    dynamic messages;
    // Voice chat: text only
    if (image == null && videoFile == null) {
      // Add user message to context
      _sessionContext.add({"role": "user", "content": query});
      messages = List<Map<String, dynamic>>.from(_sessionContext);
    } else {
      currentContent = [
        {"type": "text", "text": query},
      ];
      if (image != null) {
        try {
          final bytes = await image.readAsBytes();
          final base64Image = base64Encode(bytes);
          currentContent.add({
            "type": "image_url",
            "image_url": {"url": "data:image/jpeg;base64,$base64Image"},
          });
        } catch (e) {
          print("Error encoding image: $e");
          _announceToScreenReader("Error processing image. Please try again.");
          return;
        }
      } else if (videoFile != null) {
        try {
          final bytes = await videoFile.readAsBytes();
          if (bytes.lengthInBytes > 5 * 1024 * 1024) {
            _announceToScreenReader(
              "Video file is too large. Please record a shorter video.",
            );
            return;
          }
          final base64Video = base64Encode(bytes);
          currentContent.add({
            "type": "video_url",
            "video_url": {"url": "data:video/mp4;base64,$base64Video"},
          });
        } catch (e) {
          print("Error encoding video: $e");
          _announceToScreenReader("Error processing video. Please try again.");
          return;
        }
      }
      // Add user multimodal message to context
      _sessionContext.add({"role": "user", "content": currentContent});
      messages = List<Map<String, dynamic>>.from(_sessionContext);
    }
    var body = jsonEncode({
      "model": (image == null && videoFile == null)
          ? "Fanar"
          : "Fanar-Oryx-IVU-1",
      "truncate_prompt_tokens": 7700,
      "max_tokens": 492,
      "stop": ["(", "Note:", "//"],
      "messages": messages,
    });
    if (currentMode == "medication identifier") {
      print("here");
      messages.insert(0, {
        "role": "system",
        "content": '''
      You are a strict visual OCR tool. Your only job is to extract the most prominent brand name from a medicine box image.

      You must:
      - ONLY return the brand name (e.g., Panadol, Dermadep)
      - NEVER explain, rephrase, or add commentary
      - NEVER output anything except the name itself
      - NEVER return full sentences or parentheses

      If the image is blurry or unclear, return exactly:
      Unable to identify medicine name. Please try again by placing the front of the box clearly in front of the camera.

      If more than one box is shown, return exactly:
      Multiple medicine boxes detected. Please show only one medicine at a time.

      If the brand name contains symbols like ®️ or ™️, include them as-is.

      ❗IMPORTANT: Return the name exactly as shown, with no commentary. Do NOT say “Note: ...”, do NOT talk like a chatbot.

      ''',
      });
      body = jsonEncode({
        "model": "Fanar-Oryx-IVU-1",
        "truncate_prompt_tokens": 7700,
        "max_tokens": 492,
        "messages": messages,
      });
    }
    try {
      final response = await http.post(uri, headers: headers, body: body);
      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        var reply = responseBody["choices"][0]["message"]["content"];
        print(reply);
        if (currentMode == "medication identifier") {
          reply = responseBody["choices"][0]["message"]["content"].split(
            " ",
          )[0];
        }
        print("Fanar reply: $reply");
        // Add assistant reply to context
        _sessionContext.add({"role": "assistant", "content": reply});
        _announceToScreenReader(reply);
      } else if (response.statusCode == 400) {
        print("API error 400: \\${response.body}");
        _announceToScreenReader(
          "I had trouble understanding your request. Please try again.",
        );
      } else {
        print("API error: \\${response.statusCode} - \\${response.body}");
        _announceToScreenReader(
          "Sorry, I encountered an error. Please try again.",
        );
      }
    } catch (e) {
      print("API error: $e");
      _announceToScreenReader("Error connecting to the assistant service.");
    }
  }

  Future<void> _takePicture() async {
    try {
      if (_initializeControllerFuture == null || _cameraController == null) {
        throw Exception("Camera not initialized");
      }
      await _initializeControllerFuture!;
      final path = join(
        (await getTemporaryDirectory()).path,
        '${DateTime.now()}.png',
      );
      if (currentMode == "currency") {
        _toggleFlash();
      }
      final XFile image = await _cameraController!.takePicture();
      if (currentMode == "currency") {
        _toggleFlash();
      }
      await image.saveTo(path);
      print("Picture saved to: $path");
      _announceToScreenReader(
        "Picture taken successfully. Processing the image. Please wait.",
      );
      var prompt = "";
      if (currentMode == "picture describe") {
        prompt =
            "You are an assistive AI for blind users. Please describe the contents of this image in detail, including objects, people, text, and any relevant context. Be concise, clear, and helpful.";
        await callFanarAPI(query: prompt, image: File(path));
      } else if (currentMode == "document reader") {
        prompt =
            "Extract and return the exact text from this document without any modifications, summaries, or added commentary. Preserve original formatting (e.g., line breaks, lists) to ensure screen-reader compatibility. If the document includes images or tables, provide their alt text or describe their structure. Do not alter, abbreviate, or paraphrase any content.";
        await callFanarAPI(query: prompt, image: File(path));
      } else if (currentMode == "currency") {
        prompt = '''
          You are a currency bill detection expert. Analyze the input image and:
          1. **Identify the denomination** (e.g., 1, 5, 10, 20, 50, 100).
          2. **Detect the currency name** in full official English (e.g., "US Dollars", "Qatari Riyals", "Euros").
          3. **Output format**: Strictly use: `<denomination> <currency_name>`  
            Example: "10 US Dollars" or "50 Qatari Riyals"

          **Rules**:
          - If denomination/currency is ambiguous, return "Unknown".
          - Never use currency codes (e.g., USD, EUR) or symbols (\$, 8).
          - Prioritize visible text/design over background patterns.
          - Handle partial/obstructed bills by checking security features (holograms, watermarks).
        ''';
        await callFanarAPI(query: prompt, image: File(path));
      } else if (currentMode == "outfit identifier") {
        prompt =
            "Describe this outfit in terms of color, style, and use. Is it formal, casual, or something else? reply in only 1 sentence";
        await callFanarAPI(query: prompt, image: File(path));
      } else if (currentMode == "medication identifier") {
        // You are a vision-based assistant helping a blind person identify medicines.
        prompt = '''
        You are a strict visual OCR tool. Your only job is to extract the most prominent brand name from a medicine box image.

        You must:
        - ONLY return the brand name (e.g., Panadol, Dermadep)
        - NEVER explain, rephrase, or add commentary
        - NEVER output anything except the name itself
        - NEVER return full sentences or parentheses

        If the image is blurry or unclear, return exactly:
        Unable to identify medicine name. Please try again by placing the front of the box clearly in front of the camera.

        If more than one box is shown, return exactly:
        Multiple medicine boxes detected. Please show only one medicine at a time.

        If the brand name contains symbols like ®️ or ™️, include them as-is.

        ❗IMPORTANT: Return the name exactly as shown, with no commentary. Do NOT say “Note: ...”, do NOT talk like a chatbot.

        ''';
        prompt = "What is the brand name of this medicine?";
        await callFanarAPI(query: prompt, image: File(path));
      } else if (currentMode == "barcode") {
        await _handleBarcodeScan(path);
      }
    } catch (e) {
      print("error");
      print(e);
      _announceToScreenReader("Failed to take picture. Please try again.");
    }
  }

  Future<void> _startVideoRecording() async {
    if (_cameraController!.value.isRecordingVideo) return;
    try {
      await _cameraController!.prepareForVideoRecording();
      await _cameraController!.startVideoRecording();
      _isRecording = true;
      print("Started recording video.");
      _announceToScreenReader("Video recording started.");
    } catch (e) {
      print("Error starting video recording: $e");
      _announceToScreenReader("Error starting video recording.");
    }
  }

  Future<void> _stopVideoRecordingAndSend() async {
    if (!_isRecording || !_cameraController!.value.isRecordingVideo) return;
    try {
      final file = await _cameraController!.stopVideoRecording();
      _isRecording = false;
      _videoPath = file.path;
      print("Stopped recording: $_videoPath");
      _announceToScreenReader("Video recorded. Please ask your question.");
      final String videoPromptEnglish =
          "You are a voice assistant for the blind. Describe the video briefly and clearly in Arabic or English. Avoid phrases like 'in the video'. Focus on useful details only.";
      await callFanarAPI(
        query: videoPromptEnglish,
        videoFile: File(_videoPath!),
      );
    } catch (e) {
      print("Error stopping video: $e");
      _announceToScreenReader("Error recording video.");
    }
  }

  Future<void> _handleBarcodeScan(path) async {
    try {
      final barcode = await _detectBarcode(File(path));
      if (barcode == null) {
        _announceToScreenReader("No barcode detected.");
        return;
      }
      final url = Uri.parse(
        "https://world.openfoodfacts.org/api/v0/product/$barcode.json",
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final productName =
            result["product"]?["product_name"] ?? "Product name not available.";
        print(productName);
        _announceToScreenReader(productName);
      } else {
        print("product not found");
        _announceToScreenReader("Product not found.");
      }
    } catch (e) {
      print("Barcode scan error: $e");
      _announceToScreenReader("An error occurred while scanning the barcode.");
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

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      toolbarHeight: 70,
      actionsPadding: EdgeInsets.symmetric(horizontal: 30),
      leading: Semantics(
        button: true,
        label: 'Open settings',
        child: IconButton(
          padding: EdgeInsets.symmetric(horizontal: 30),
          iconSize: 40,
          icon: const Icon(Icons.settings),
          onPressed: () {
            _announceToScreenReader("Settings opened");
          },
        ),
      ),
      actions: [
        Semantics(
          button: true,
          label: 'Instructions',
          child: IconButton(
            iconSize: 40,
            icon: Icon(Icons.help_outline),
            onPressed: () {
              _announceToScreenReader(
                "Instructions opened. Please swipe right to hear available modes and controls.",
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCameraPreview() {
    if (_initializeControllerFuture == null) {
      return Semantics(
        label: 'Camera loading',
        child: Container(
          color: Colors.black,
          alignment: Alignment.center,
          child: const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    } else {
      return FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              _cameraController != null &&
              _cameraController!.value.isInitialized) {
            return Semantics(
              label: 'Live camera preview',
              child: CameraPreview(_cameraController!),
            );
          } else if (snapshot.connectionState == ConnectionState.waiting) {
            return Semantics(
              label: 'Camera loading',
              child: Container(
                color: Colors.black,
                alignment: Alignment.center,
                child: const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            );
          } else {
            return Semantics(
              label: 'Camera error',
              child: Container(
                color: Colors.black,
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 50,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      snapshot.hasError
                          ? 'Error: ${snapshot.error}'
                          : 'Camera not available',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 18,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _setupCameras,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }
        },
      );
    }
  }

  Widget _buildBottomControls() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Semantics(
        container: true,
        label: 'Camera controls',
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 36.0, horizontal: 10),
          child: SafeArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Semantics(
                  button: true,
                  label: 'Voice chat',
                  hint: 'Double tap to activate voice chat',
                  child: IconButton(
                    icon: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      color: Colors.white,
                      size: 40,
                    ),
                    onPressed: () {
                      _startVoiceChat();
                    },
                  ),
                ),
                Expanded(
                  child: Semantics(
                    button: true,
                    label: currentMode == "video"
                        ? (_isRecording
                              ? "Stop video recording"
                              : "Start video recording")
                        : 'Take picture',
                    hint: currentMode == "video"
                        ? (_isRecording
                              ? "Double tap to stop video recording"
                              : "Double tap to start video recording")
                        : 'Double tap to capture an image',
                    child: GestureDetector(
                      onTap: () async {
                        if (currentMode == "video") {
                          if (_isRecording) {
                            print("stopped video recording");
                            _stopVideoRecordingAndSend();
                          } else {
                            print("started video recording");
                            _startVideoRecording();
                          }
                        } else {
                          print('Take picture tapped');
                          await _takePicture();
                        }
                      },
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _cameraController?.value.isInitialized == true
                              ? Colors.white
                              : Colors.grey,
                          border: Border.all(
                            color:
                                _cameraController?.value.isInitialized == true
                                ? Colors.grey
                                : Colors.grey[700]!,
                            width: 4.0,
                          ),
                        ),
                        child: Center(
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color:
                                  _cameraController?.value.isInitialized == true
                                  ? Colors.white
                                  : Colors.grey[300]!,
                              border: Border.all(
                                color: Colors.black,
                                width: 2.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Semantics(
                  button: true,
                  label: 'Change camera',
                  hint: 'Double tap to switch between front and back camera',
                  child: IconButton(
                    icon: const Icon(
                      Icons.cameraswitch,
                      color: Colors.white,
                      size: 40,
                    ),
                    onPressed: () async {
                      final currentCameraIndex = _cameras.indexOf(
                        _cameraController!.description,
                      );
                      final nextCameraIndex = (currentCameraIndex + 1) % 2;
                      await _initCamera(nextCameraIndex);
                      _announceToScreenReader(
                        nextCameraIndex == 0
                            ? "Now facing the default rear camera"
                            : "Now facing the selfie camera",
                      );
                      // setState(() => _currentCameraIndex = nextCameraIndex); // Update tracked index
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> doModeTask(String mode) async {
    print("$mode mode selected");
    _announceToScreenReader("$mode mode activated");
  }

  IconData modeIcon(String mode) {
    switch (mode) {
      case "picture describe":
        return Icons.image;
      case "document reader":
        return Icons.article;
      case "video":
        return Icons.videocam;
      case "barcode":
        return Icons.qr_code;
      case "medication identifier":
        return Icons.medical_services;
      case "currency":
        return Icons.attach_money;
      case "Light intensity detector":
        return Icons.brightness_6;
      case "outfit identifier":
        return Icons.checkroom;
      default:
        return Icons.help_outline;
    }
  }

  Widget _buildModeButtons(List<String> modesToDisplay) {
    return Semantics(
      container: true,
      label: 'Mode selection controls',
      child: Container(
        color: Colors.black,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: modesToDisplay.map((mode) {
              final bool isSelected = mode == currentMode;
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 5,
                  vertical: 15,
                ),
                child: Semantics(
                  button: true,
                  label: '$mode mode',
                  hint: isSelected
                      ? 'Currently selected'
                      : 'Double tap to activate ${mode.toLowerCase()} mode',
                  child: ExcludeSemantics(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.cyan.withOpacity(0.2)
                            : Colors.transparent,
                        border: Border.all(
                          color: isSelected ? Colors.cyan : Colors.transparent,
                          width: isSelected ? 3 : 0,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: IconButton(
                        icon: Icon(
                          modeIcon(mode),
                          color: isSelected ? Colors.cyan : Colors.white,
                          size: 50,
                          semanticLabel: '',
                        ),
                        onPressed: () async {
                          setState(() {
                            currentMode = mode;
                          });
                          await doModeTask(mode);
                        },
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Future<void> _startVoiceChat() async {
    if (!_isListening) {
      // Ensure TTS finishes before listening
      await flutterTts.awaitSpeakCompletion(true);
      await flutterTts.speak("Voice chat started. Please speak your question.");
      await flutterTts.awaitSpeakCompletion(true);
      bool available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            setState(() => _isListening = false);
            _speech.stop();
            if (_voiceInput.trim().isNotEmpty) {
              _sendVoiceToFanar(_voiceInput.trim());
            } else {
              _announceToScreenReader(
                "No voice input detected. Please try again.",
              );
            }
          }
        },
        onError: (val) {
          setState(() => _isListening = false);
          _announceToScreenReader("Voice recognition error. Please try again.");
        },
      );
      if (available) {
        setState(() {
          _isListening = true;
          _voiceInput = '';
        });
        _speech.listen(
          onResult: (val) {
            print(val.recognizedWords);
            setState(() {
              _voiceInput = val.recognizedWords;
            });
          },
          localeId: 'en_US',
        );
      } else {
        _announceToScreenReader("Speech recognition not available.");
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  Future<void> _sendVoiceToFanar(String userQuery) async {
    final prompt =
        '''
  You are an assistive AI for blind users. Respond to the following question in a clear, concise, and helpful manner. Avoid visual references. If the question is ambiguous, ask for clarification. Speak as if you are guiding someone who cannot see the screen.

  User question: "$userQuery"
''';
    await callFanarAPI(query: prompt);
  }

  @override
  Widget build(BuildContext context) {
    final List<String> otherModes = allModes
        .where(
          (mode) => mode != "picture describe" && mode != "document reader",
        )
        .toList();
    return Semantics(
      container: true,
      label: 'Main screen with camera preview, controls, and mode selection',
      child: Scaffold(
        appBar: _buildAppBar(),
        body: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(child: _buildCameraPreview()),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildBottomControls(),
                        SizedBox(
                          height: 88,
                          child: Semantics(
                            label: 'Tab bar for mode categories',
                            child: Container(
                              color: Colors.black,
                              child: TabBar(
                                controller: _tabController,
                                indicatorColor: Colors.cyan,
                                labelColor: Colors.cyan,
                                labelStyle: TextStyle(fontSize: 20),
                                unselectedLabelColor: Colors.white,
                                tabs: const [
                                  Tab(text: "Describe"),
                                  Tab(text: "Read"),
                                  Tab(text: "More"),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 100,
                          child: _tabController!.index == 2
                              ? _buildModeButtons(otherModes)
                              : Container(color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
