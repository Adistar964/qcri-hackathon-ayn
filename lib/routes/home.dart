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

final List<String> allModes = [
  "picture describe",
  "document reader",
  "video",
  "barcode",
  "medication identifier",
  "currency",
  // "Light intensity detector",
  "outfit identifier"
];

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

final String apikey = "fmFrMl3wHnB9SFnb8bzxNFpGCVE18Wcz";

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  Future<void>? _initializeControllerFuture;
  bool _isFlashOn = false;
  List<CameraDescription> _cameras = [];
  late TabController? _tabController;
  String currentMode = "picture describe"; // Default mode
  bool _isRecording = false;
  String? _videoPath;
  final FlutterTts flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController!.addListener(_handleTabSelection);
    _setupCameras();
    _updateCurrentModeForTab(_tabController!.index);
  }

  void _handleTabSelection() {
    if (_tabController!.indexIsChanging || _tabController!.index != _tabController!.previousIndex) {
      setState(() {
        _updateCurrentModeForTab(_tabController!.index);
      });
      String tabName;
      if (_tabController!.index == 0) {
        tabName = "Picture Describe tab";
      } else if (_tabController!.index == 1) {
        tabName = "Document Reader tab";
      } else {
        tabName = "Other Modes tab";
      }
      _announceToScreenReader("$tabName selected");
    }
  }

  void _updateCurrentModeForTab(int tabIndex) {
    if (tabIndex == 0) {
      currentMode = "picture describe";
    } else if (tabIndex == 1) {
      currentMode = "document reader";
    } else {
      final otherModes = allModes.where((mode) => mode != "picture describe" && mode != "document reader").toList();
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
        _announceToScreenReader("No cameras found or camera initialization failed.");
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
    _initializeControllerFuture = _cameraController!.initialize().then((_) {
      SemanticsBinding.instance.ensureSemantics();
    }).catchError((error) {
      if (error is CameraException) {
        switch (error.code) {
          case 'CameraAccessDenied':
            print(error);
            _announceToScreenReader("Camera access denied. Please grant permission in settings.");
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
    SemanticsBinding.instance.ensureSemantics();
    SemanticsService.announce(message, TextDirection.ltr);
    flutterTts.stop();
    flutterTts.speak(message);
  }

  @override
  void dispose() {
    _tabController!.removeListener(_handleTabSelection);
    _tabController!.dispose();
    _cameraController?.dispose();
    flutterTts.stop();
    super.dispose();
  }

  Future<void> _toggleFlash() async {
    try {
      if (_cameraController == null || !_cameraController!.value.isInitialized) {
        throw Exception("Camera not initialized");
      }
      await _cameraController!.setFlashMode(
        _isFlashOn ? FlashMode.off : FlashMode.torch,
      );
      setState(() {
        _isFlashOn = !_isFlashOn;
      });
      _announceToScreenReader(_isFlashOn ? "Flashlight turned on" : "Flashlight turned off");
    } catch (e) {
      print('Error toggling flash: $e');
      _announceToScreenReader("Failed to toggle flashlight");
    }
  }

  Future<void> callFanarAPI({required String query, File? image, File? videoFile}) async {
    final uri = Uri.parse('https://api.fanar.qa/v1/chat/completions');
    final headers = {
      'Authorization': 'Bearer $apikey',
      'Content-Type': 'application/json',
    };
    List<dynamic> currentContent = [
      {"type": "text", "text": query}
    ];
    if (image != null) {
      try {
        final bytes = await image.readAsBytes();
        final base64Image = base64Encode(bytes);
        currentContent.add({
          "type": "image_url",
          "image_url": {"url": "data:image/jpeg;base64,$base64Image"}
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
          _announceToScreenReader("Video file is too large. Please record a shorter video.");
          return;
        }
        final base64Video = base64Encode(bytes);
        currentContent.add({
          "type": "video_url",
          "video_url": {"url": "data:video/mp4;base64,$base64Video"}
        });
      } catch (e) {
        print("Error encoding video: $e");
        _announceToScreenReader("Error processing video. Please try again.");
        return;
      }
    }
    final messages = [
      {"role": "user", "content": currentContent}
    ];
    var body = jsonEncode({
      "model": "Fanar-Oryx-IVU-1",
      "stop": ["(", "Note:", "//"],
      "messages": messages,
    });
    if(currentMode == "medication identifier"){
      body = jsonEncode({
      "model": "Fanar-Oryx-IVU-1",
      "temperature": 0.0,
      "top_p": 0.1,
      "max_tokens": 20,
      "stop": ["\n", "(", "Note:", "//", "I/flutter"],
      "repetition_penalty": 2.0,
      "frequency_penalty": 2.0,
      "presence_penalty": 2.0,
      "skip_special_tokens": true,
      "min_tokens": 1,
      "messages": messages,
      });
    }
    try {
      final response = await http.post(uri, headers: headers, body: body);
      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        var reply = responseBody["choices"][0]["message"]["content"];
        print("Fanar reply: $reply");
        _announceToScreenReader(reply);
      } else if (response.statusCode == 400) {
        print("API error 400: ${response.body}");
        _announceToScreenReader("I had trouble understanding your request. Please try again.");
      } else {
        print("API error: ${response.statusCode} - ${response.body}");
        _announceToScreenReader("Sorry, I encountered an error. Please try again.");
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
      if(currentMode == "currency"){
        _toggleFlash();
      }
      final XFile image = await _cameraController!.takePicture();
      if(currentMode == "currency"){
        _toggleFlash();
      }
      await image.saveTo(path);
      print("Picture saved to: $path");
      _announceToScreenReader("Picture taken successfully. Processing the image. Please wait.");
      var prompt = "";
      if(currentMode == "picture describe"){
        prompt = "You are an assistive AI for blind users. Please describe the contents of this image in detail, including objects, people, text, and any relevant context. Be concise, clear, and helpful.";
        await callFanarAPI(query: prompt, image: File(path));
      }else if(currentMode == "document reader"){
        prompt = "Extract and return the exact text from this document without any modifications, summaries, or added commentary. Preserve original formatting (e.g., line breaks, lists) to ensure screen-reader compatibility. If the document includes images or tables, provide their alt text or describe their structure. Do not alter, abbreviate, or paraphrase any content.";
        await callFanarAPI(query: prompt, image: File(path));
      }else if(currentMode == "currency"){
        prompt ='''
          You are a currency bill detection expert. Analyze the input image and:
          1. **Identify the denomination** (e.g., 1, 5, 10, 20, 50, 100).
          2. **Detect the currency name** in full official English (e.g., "US Dollars", "Qatari Riyals", "Euros").
          3. **Output format**: Strictly use: `<denomination> <currency_name>`  
            Example: "10 US Dollars" or "50 Qatari Riyals"

          **Rules**:
          - If denomination/currency is ambiguous, return "Unknown".
          - Never use currency codes (e.g., USD, EUR) or symbols (\$, 8).
          - Prioritize visible text/design over background patterns.
          - Handle partial/obstructed bills by checking security features (holograms, watermarks).
        ''';
        await callFanarAPI(query: prompt, image: File(path));
      }else if(currentMode == "outfit identifier"){
        prompt = "Describe this outfit in terms of color, style, and use. Is it formal, casual, or something else? reply in only 1 sentence";
        await callFanarAPI(query: prompt, image: File(path));
      }else if(currentMode == "medication identifier"){
        prompt ='''
You are a text-extraction tool for medicine identification. Your ONLY function is to output the dominant text on the box front EXACTLY as visually presented.

**Failure Prevention Protocol (MUST OBSERVE):**
1. ⛔ **NEVER** add notes, parentheses, or explanations
2. ⛔ **NEVER** interpret, correct, or rephrase text 
3. ⛔ **NEVER** translate or contextualize words
4. ⛔ **NEVER** assume meaning or intent
5. ✅ **ALWAYS** preserve: spelling, casing, spacing, punctuation

**Execution Rules:**
1. Extract ONLY the largest/most central text on the box front
2. If text contains non-English characters: PRESERVE them
3. If text is stylized (e.g., "SkinCare"): PRESERVE formatting
4. Output format: Raw text string ONLY

**Error Handling (EXACT PHRASES ONLY):**
- Unreadable/blurry: "Unable to identify medicine name. Please try again by placing the front of the box clearly in front of the camera."
- Multiple boxes: "Multiple medicine boxes detected. Please show only one medicine at a time."

**Conditioning Examples:**
INPUT: "Dermadep" 9 OUTPUT: `Dermadep`  
INPUT: "SkinDep" 9 OUTPUT: `SkinDep`  
INPUT: "Panadol Extra" 9 OUTPUT: `Panadol Extra`  
INPUT: "Vitamina C+" 9 OUTPUT: `Vitamina C+`

**PROHIBITED OUTPUT EXAMPLES (NEVER GENERATE):**
- "Skin Care (rephrased from Dermadep)"
- "Dermadep [possibly meaning skin care]"
- "SkinDep - likely a skincare product"
- "Vitamina C+ (Spanish for Vitamin C)"

**Final Enforcement:**
YOUR OUTPUT MUST BE A SINGLE STRING WITH 0 ADDITIONAL CHARACTERS. ANY DEVIATION RISKS MEDICATION SAFETY.
        ''';
        await callFanarAPI(query: prompt, image: File(path));
      }else if(currentMode == "barcode"){
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
      final String videoPromptEnglish = "You are a voice assistant for the blind. Describe the video briefly and clearly in Arabic or English. Avoid phrases like 'in the video'. Focus on useful details only.";
      await callFanarAPI(query: videoPromptEnglish, videoFile: File(_videoPath!));
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
      final url = Uri.parse("https://world.openfoodfacts.org/api/v0/product/$barcode.json");
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final productName = result["product"]?["product_name"] ?? "Product name not available.";
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
              _announceToScreenReader("Instructions opened. Please swipe right to hear available modes and controls.");
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
                    const Icon(Icons.error_outline, color: Colors.red, size: 50),
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
                    icon: const Icon(Icons.mic, color: Colors.white, size: 40),
                    onPressed: () {
                      _announceToScreenReader("Voice chat not implemented yet.");
                    },
                  ),
                ),
                Expanded(
                  child: Semantics(
                    button: true,
                    label: currentMode=="video" ? (_isRecording ? "Stop video recording" : "Start video recording") : 'Take picture',
                    hint: currentMode=="video" ? (_isRecording ? "Double tap to stop video recording" : "Double tap to start video recording") : 'Double tap to capture an image',
                    child: GestureDetector(
                      onTap: () async {
                        if(currentMode == "video"){
                          if(_isRecording){
                            print("stopped video recording");
                            _stopVideoRecordingAndSend();
                          }else{
                            print("started video recording");
                            _startVideoRecording();
                          }
                        }else{
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
                            color: _cameraController?.value.isInitialized == true
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
                              color: _cameraController?.value.isInitialized == true
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
                    icon: const Icon(Icons.cameraswitch, color: Colors.white, size: 40),
                    onPressed: () async {
                      final currentCameraIndex = _cameras.indexOf(_cameraController!.description);
                      final nextCameraIndex = (currentCameraIndex + 1) % 2;
                      await _initCamera(nextCameraIndex);
                      _announceToScreenReader(nextCameraIndex==0 ? "Now facing the default rear camera" : "Now facing the selfie camera");
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
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 15),
                child: Semantics(
                  button: true,
                  label: '$mode mode',
                  hint: isSelected ? 'Currently selected' : 'Double tap to activate ${mode.toLowerCase()} mode',
                  child: ExcludeSemantics(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.cyan.withOpacity(0.2) : Colors.transparent,
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

  @override
  Widget build(BuildContext context) {
    final List<String> otherModes = allModes
        .where((mode) => mode != "picture describe" && mode != "document reader")
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
                  Positioned.fill(
                    child: _buildCameraPreview(),
                  ),
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
                              : Container(color:Colors.black),
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