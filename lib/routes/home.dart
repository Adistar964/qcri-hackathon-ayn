import 'package:ayn/components/instructionsModal.dart';
import 'package:ayn/config/api_config.dart';
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
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:ayn/config/language_config.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

final List<String> allModes = [
  "picture describe",
  "Read",
  "video",
  "barcode",
  "medication identifier",
  "currency",
  "outfit identifier",
];

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}


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

  SharedPreferences? prefs;
  bool? isEnglish;

  List<Map<String, dynamic>> _sessionContext = [];

  int?
  _lastAnnouncedIndex; // For making sure the tab change doesnt repeatedly call announceScreenReader

  bool _showInstructionsDialog = false; // Show on first launch

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController!.addListener(_handleTabSelection);
    _setupCameras();
    _updateCurrentModeForTab(_tabController!.index);
    _sessionContext = [];
    _lastAnnouncedIndex = _tabController!.index; // Initialize with current tab
    // detecting the current language:
    detectLanguage();
    // Show instructions dialog after first frame
  }
    
  Future<void> detectLanguage() async {
    prefs = await SharedPreferences.getInstance();
    isEnglish = await prefs!.getString("language") == "EN";
    // await prefs!.setBool("first_time", true);
    String msg = translate("Picture Describe tab", isEnglish: isEnglish ?? true);
    msg = "$msg ${translate(" selected", isEnglish: isEnglish ?? true)}";
    _announceToScreenReader(msg);
    if(mounted) setState(() {});
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
        0 => translate("Picture Describe tab", isEnglish: isEnglish ?? true),
        1 => translate("Read tab", isEnglish: isEnglish ?? true),
        _ => translate("Other Modes tab", isEnglish: isEnglish ?? true),
      };

      _announceToScreenReader("$tabName ${translate(" selected", isEnglish: isEnglish ?? true)}");
      _lastAnnouncedIndex = _tabController!.index; // Remember last announcement
    }
  }

  void _updateCurrentModeForTab(int tabIndex) {
    if (tabIndex == 0) {
      currentMode = "picture describe";
    } else if (tabIndex == 1) {
      currentMode = "Read";
    } else {
      final otherModes = allModes
          .where(
            (mode) => mode != "picture describe" && mode != "Read",
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
        .then((_) async {
          SemanticsBinding.instance.ensureSemantics();
          await _cameraController!.setFocusMode(FocusMode.auto);
        })
        .catchError((error) {
          if (error is CameraException) {
            switch (error.code) {
              case 'CameraAccessDenied':
                print(error);
                _announceToScreenReader(
                  translate("Camera access denied. Please grant permission in settings.", isEnglish: isEnglish ?? true),
                );
                break;
              default:
                print(error);
                _announceToScreenReader(translate("Camera error occurred.", isEnglish: isEnglish ?? true));
                break;
            }
          }
        });
    if (mounted) setState(() {});
  }

  Future<void> _announceToScreenReader(String message) async {
    SemanticsBinding.instance.ensureSemantics();
    await SemanticsService.announce(message, TextDirection.ltr);
    print("speaking");
    flutterTts.stop();
    if(isEnglish == true){
      flutterTts.setLanguage("en");
    }else{
      flutterTts.setLanguage("ar");
    }
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
        throw Exception(translate("Camera not available", isEnglish: isEnglish ?? true));
      }
      await _cameraController!.setFlashMode(
        _isFlashOn ? FlashMode.off : FlashMode.torch,
      );
      setState(() {
        _isFlashOn = !_isFlashOn;
      });
      // _announceToScreenReader(
      //   _isFlashOn ? translate("Flashlight turned on", isEnglish: isEnglish ?? true) : translate("Flashlight turned off", isEnglish: isEnglish ?? true),
      // );
    } catch (e) {
      print('Error toggling flash: $e');
      // _announceToScreenReader(translate("Failed to toggle flashlight", isEnglish: isEnglish ?? true));
    }
  }

  Future<dynamic> callFanarAPI({
    required String query,
    File? image,
    File? videoFile,
    bool speakReponse = true
  }) async {
    // var (apiKey, apiRoute, apiModel) = get_API_credentials(speakReponse ? true : false);
    var (apiKey, apiRoute, apiModel) = get_API_credentials(true);
    print("using $apiRoute with $apiKey for $apiModel");
    print("using $apiModel");
    final uri = Uri.parse(apiRoute);
    final headers = {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    };
    List<dynamic>? currentContent;
    dynamic messages;

    if(image == null && videoFile == null){
      apiModel = "Fanar"; // better with text handling
    }
    // Reset context if media is used
    if (image != null || videoFile != null) {
      _sessionContext = [];
    }

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
          if (!speakReponse) return "error";
          return;
        }
      } else if (videoFile != null) {
        try {
          final bytes = await videoFile.readAsBytes();
          if (bytes.lengthInBytes > 5 * 1024 * 1024) {
            _announceToScreenReader(
              "Video file is too large. Please record a shorter video.",
            );
            if (!speakReponse) return "error";
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
          if (!speakReponse) return "error";
          return;
        }
      }
      // Add user multimodal message to context
      _sessionContext.add({"role": "user", "content": currentContent});
      messages = List<Map<String, dynamic>>.from(_sessionContext);
    }
    var body = jsonEncode({
      "model": apiModel,
      "truncate_prompt_tokens": 4096,
      // "stop": ["(", "Note:", "//"],
      "messages": messages,
    });
    try {
      final response = await http.post(uri, headers: headers, body: body);
      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        var reply = responseBody["choices"][0]["message"]["content"];
        print("Fanar reply: $reply");
        // Add assistant reply to context
        _sessionContext.add({"role": "assistant", "content": reply});
        if(speakReponse){
          _announceToScreenReader(reply);
        }else{
          return reply; // if speakReponse is disabled, this function will only return the response
        }
      } else if (response.statusCode == 400) {
        print("API error 400 from fanar: \\${response.body}");
        _announceToScreenReader(
          translate("I had trouble understanding your request. Please try again.", isEnglish: isEnglish ?? true),
        );
        if (!speakReponse) return "error";
      } else {
        print("API error from fanar: \\${response.statusCode} - \\${response.body}");
        _announceToScreenReader(
          translate("Sorry, I encountered an error. Please try again.", isEnglish: isEnglish ?? true),
        );
        if (!speakReponse) return "error";
      }
    } catch (e) {
      print("API error from fanar: $e");
      _announceToScreenReader(translate("Error connecting to the assistant service.", isEnglish: isEnglish ?? true));
      if (!speakReponse) return "error";
    }
  }

  Future<void> _takePicture() async {
    try {
      if (_initializeControllerFuture == null || _cameraController == null) {
        throw Exception(translate("Camera not available", isEnglish: isEnglish ?? true));
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
        translate("Picture taken successfully. Processing the image. Please wait.", isEnglish: isEnglish ?? true),
      );
      var prompt = "";
      if (currentMode == "picture describe") {
        prompt =
            translate("You are an assistive AI for blind users. Please describe the contents of this image in detail, including objects, people, text, and any relevant context. Be concise, clear, and helpful.", isEnglish: isEnglish ?? true);
        await callFanarAPI(query: prompt, image: File(path));
      } else if (currentMode == "Read") {
        // if(isEnglish == true){
        //   final inputImage = InputImage.fromFilePath(path);
        //   final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
        //   final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
        //   textRecognizer.close();
        //   // adding into context
        //   _sessionContext.add({"role":"user","content":"Read this."});
        //   _sessionContext.add({"role":"assistant","content":recognizedText.text.split("\n").join(" ")});
        //   _announceToScreenReader(recognizedText.text.split("\n").join(" "));
        // }else{
          prompt = translate("Extract and return the exact text from this document without any modifications, summaries, or added commentary. Preserve original formatting (e.g., line breaks, lists) to ensure screen-reader compatibility. If the document includes images or tables, provide their alt text or describe their structure. Do not alter, abbreviate, or paraphrase any content.", isEnglish: isEnglish ?? true);
          await callFanarAPI(query: prompt, image: File(path));
        // }

      } else if (currentMode == "currency") {
        prompt = translate("You are a currency bill detection expert. Analyze the input image and:\n1. **Identify the denomination** (e.g., 1, 5, 10, 20, 50, 100).\n2. **Detect the currency name** in full official English (e.g., \"US Dollars\", \"Qatari Riyals\", \"Euros\").\n3. **Output format**: Strictly use: `<denomination> <currency_name>` \nExample: \"10 US Dollars\" or \"50 Qatari Riyals\"\n**Rules**:\n- If denomination/currency is ambiguous, return \"Unknown\".\n- Never use currency codes (e.g., USD, EUR) or symbols (\$, 8).\n- Prioritize visible text/design over background patterns.\n- Handle partial/obstructed bills by checking security features (holograms, watermarks).", isEnglish: isEnglish ?? true);
        await callFanarAPI(query: prompt, image: File(path));
      } else if (currentMode == "outfit identifier") {
        prompt = translate("Describe this outfit in terms of color, style, and use. Is it formal, casual, or something else? reply in only 1 sentence", isEnglish: isEnglish ?? true);
        await callFanarAPI(query: prompt, image: File(path));
      } else if (currentMode == "medication identifier") {
        prompt = "Extract the medicine name from this box.\nYou must: \nIf the image is blurry or unclear, return exactly:\nUnable to identify medicine name. Please try again by placing the front of the box clearly in front of the camera.\nIf more than one box is shown, return exactly:\nMultiple medicine boxes detected. Please show only one medicine at a time.”";
        String brandName = await callFanarAPI(query: prompt, image: File(path), speakReponse: false);
        if(brandName.toLowerCase().contains("identify") || brandName.toLowerCase().contains("unable") || brandName.toLowerCase().contains("box") || brandName.toLowerCase().contains("multiple")){
          await _announceToScreenReader(brandName);
        }else{
          prompt = "what is the name of the medicine. Give only one word.";
          brandName = await callFanarAPI(query: prompt, speakReponse: false);
          getMedicineInfo(brandName);
        }
        // await getMedicineInfo("calendula");
      } else if (currentMode == "barcode") {
        await _handleBarcodeScan(path);
      }
    } catch (e) {
      print("error");
      print(e);
      _announceToScreenReader(translate("Failed to take picture. Please try again.", isEnglish: isEnglish ?? true));
    }
  }

  Future<void> _startVideoRecording() async {
    if (_cameraController!.value.isRecordingVideo) return;
    try {
      await _cameraController!.prepareForVideoRecording();
      await _cameraController!.startVideoRecording();
      _isRecording = true;
      print("Started recording video.");
      _announceToScreenReader(translate("Video recording started.", isEnglish: isEnglish ?? true));
    } catch (e) {
      print("Error starting video recording: $e");
      _announceToScreenReader(translate("Error starting video recording.", isEnglish: isEnglish ?? true));
    }
  }

  Future<void> _stopVideoRecordingAndSend() async {
    if (!_isRecording || !_cameraController!.value.isRecordingVideo) return;
    try {
      final file = await _cameraController!.stopVideoRecording();
      _isRecording = false;
      _videoPath = file.path;
      print("Stopped recording: $_videoPath");
      _announceToScreenReader(translate("Video recorded. Please ask your question.", isEnglish: isEnglish ?? true));
      final String videoPromptEnglish =
          translate("You are a voice assistant for the blind. Describe the video briefly and clearly in Arabic or English. Avoid phrases like 'in the video'. Focus on useful details only.", isEnglish: isEnglish ?? true);
      await callFanarAPI(
        query: videoPromptEnglish,
        videoFile: File(_videoPath!),
      );
    } catch (e) {
      print("Error stopping video: $e");
      _announceToScreenReader(translate("Error recording video.", isEnglish: isEnglish ?? true));
    }
  }

  Future<void> _handleBarcodeScan(path) async {
    try {
      final barcode = await _detectBarcode(File(path));
      if (barcode == null) {
        _announceToScreenReader(translate("No barcode detected.", isEnglish: isEnglish ?? true));
        return;
      }
      final url = Uri.parse(
        "https://world.openfoodfacts.org/api/v0/product/$barcode.json",
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final productName =
            result["product"]?["product_name"] ?? translate("Product not found.", isEnglish: isEnglish ?? true);
        print(productName);
        _announceToScreenReader(productName);
      } else {
        print("product not found");
        _announceToScreenReader(translate("Product not found.", isEnglish: isEnglish ?? true));
      }
    } catch (e) {
      print("Barcode scan error: $e");
      _announceToScreenReader(translate("An error occurred while scanning the barcode.", isEnglish: isEnglish ?? true));
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

  Future<void> getMedicineInfo(String brandName) async {
    if (brandName == "error") return;
    else if (brandName.split(" ").length > 2){
    _announceToScreenReader(brandName);
    };
    print("passed those checks");
    try {
      // Use OpenFDA to get medicine info by brand name
      final uri = Uri.parse(
        'https://api.fda.gov/drug/label.json?search=openfda.brand_name:"$brandName"&limit=1',
      );

      final response = await http.get(uri);

      if (response.statusCode != 200) {
        print('Failed to find drug info for brand name: $brandName');
        _announceToScreenReader(translate("Failed to detect the medicine", isEnglish: isEnglish ?? true));
        return;
      }

      final data = json.decode(response.body);

      if (data == null || data['results'] == null || data['results'].isEmpty) {
        print('No drug info found for brand name: $brandName');
        _announceToScreenReader(translate("Failed to detect the medicine", isEnglish: isEnglish ?? true));
        return;
      }

      final drugInfo = data['results'][0]; // Take the first result
      Map<String, dynamic> simplified = {
        "brand_name": drugInfo["openfda"]?["brand_name"]?[0],
        "indications_and_usage": drugInfo["indications_and_usage"]?[0],
        "warnings": drugInfo["warnings"]?[0],
        "dosage_and_administration": drugInfo["dosage_and_administration"]?[0],
      };
      // print(drugInfo); // You can extract specific fields like description, usage, warnings, etc.
      String query = translate("Explain this medicine in clear, simple spoken language: what it's for, how to use it, and any important warnings. Avoid medical jargon. Do not include phrases like 'here’s a simple explanation' or references to the user being blind. JSON:", isEnglish: isEnglish ?? true);
      query = "$query  ${jsonEncode(simplified.toString())}";
      print(query);
      callFanarAPI(query: query);

    } catch (e) {
      print('Error fetching medicine info: $e');
      _announceToScreenReader(translate("Failed to detect the medicine", isEnglish: isEnglish ?? true));
    }
  }


  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color.fromARGB(0, 0, 0, 0),
      foregroundColor: Colors.red,
      toolbarHeight: 70,
      actionsPadding: EdgeInsets.symmetric(horizontal: 30),
      leading: Semantics(
        excludeSemantics: true,
        button: true,
        label: translate('Open settings', isEnglish: isEnglish ?? true),
        child: IconButton(
          padding: EdgeInsets.symmetric(horizontal: 30),
          iconSize: 40,
          icon: const Icon(Icons.settings),
          onPressed: () {
            _announceToScreenReader(translate("Settings opened", isEnglish: isEnglish ?? true));
          },
        ),
      ),
      actions: [
        Semantics(
          excludeSemantics: true,
          button: true,
          label: translate('Instructions', isEnglish: isEnglish ?? true),
          child: IconButton(
            iconSize: 40,
            icon: Icon(Icons.help_outline),
            // onPressed: (){},
            onPressed: () {
              print("opened instructions");
              _announceToScreenReader(
                translate("Instructions opened. Please scroll through every instructions given.", isEnglish: isEnglish ?? true),
              );
              setState(() {
                _showInstructionsDialog = true;
              });
              if(_showInstructionsDialog){
                instructionsModal(context, translate, isEnglish, () {
                  setState(() {
                    _showInstructionsDialog = false;
                  });
                  Navigator.of(context).pop();
                });
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCameraPreview() {
    if (_initializeControllerFuture == null) {
      return ExcludeSemantics(
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
              excludeSemantics: true,
              label: translate('Live camera preview', isEnglish: isEnglish ?? true),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _cameraController!.value.previewSize!.height,
                      height: _cameraController!.value.previewSize!.width,
                      child: CameraPreview(_cameraController!),
                    ),
                  ),
                ],
              ),
            );
          } else if (snapshot.connectionState == ConnectionState.waiting) {
            return Semantics(
              excludeSemantics: true,
              label: translate('Camera loading', isEnglish: isEnglish ?? true),
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
              label: translate('Camera error', isEnglish: isEnglish ?? true),
              child: Container(
                color: Colors.black,
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error, // Add a valid icon
                      color: Colors.red,
                      size: 50,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      translate('Camera error occurred.', isEnglish: isEnglish ?? true),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      child: Text(translate('Retry', isEnglish: isEnglish ?? true)),
                      onPressed: () {
                        _setupCameras();
                      },
                    ),
                  ],
                ),
              ));
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
        label: translate('Camera controls', isEnglish: isEnglish ?? true),
        child: Container(
          color: const Color.fromARGB(100, 0, 0, 0),
          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 10),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 0.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Semantics(
                    excludeSemantics: true,
                    button: true,
                    label: translate('Voice chat', isEnglish: isEnglish ?? true),
                    hint: translate('Double tap to activate voice chat', isEnglish: isEnglish ?? true),
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
                      excludeSemantics: true,
                      button: true,
                      label: currentMode == "video"
                          ? (_isRecording
                                ? translate("Stop video recording", isEnglish: isEnglish ?? true)
                                : translate("Start video recording", isEnglish: isEnglish ?? true))
                          : translate('Take picture', isEnglish: isEnglish ?? true),
                      hint: currentMode == "video"
                          ? (_isRecording
                                ? translate("Double tap to stop video recording", isEnglish: isEnglish ?? true)
                                : translate("Double tap to start video recording", isEnglish: isEnglish ?? true))
                          : translate('Double tap to capture an image', isEnglish: isEnglish ?? true),
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
                    excludeSemantics: true,
                    button: true,
                    label: translate('Change camera', isEnglish: isEnglish ?? true),
                    // hint: translate('Double tap to switch between front and back camera', isEnglish: isEnglish ?? true),
                    // onTap: () async {
                    //   final currentCameraIndex = _cameras.indexOf(
                    //     _cameraController!.description,
                    //   );
                    //   final nextCameraIndex = (currentCameraIndex + 1) % 2;
                    //   await _initCamera(nextCameraIndex);
                    //   _announceToScreenReader(
                    //     nextCameraIndex == 0
                    //       ? translate("Now facing the default rear camera", isEnglish: isEnglish ?? true)
                    //       : translate("Now facing the selfie camera", isEnglish: isEnglish ?? true),
                    //   );
                    //   // setState(() => _currentCameraIndex = nextCameraIndex); // Update tracked index
                    // },
                    child: IconButton(
                      icon: const Icon(
                        Icons.cameraswitch,
                        color: Colors.white,
                        size: 40,
                      ),
                      // onPressed: (){},
                      onPressed: () async {
                        final currentCameraIndex = _cameras.indexOf(
                          _cameraController!.description,
                        );
                        final nextCameraIndex = (currentCameraIndex + 1) % 2;
                        await _initCamera(nextCameraIndex);
                        _announceToScreenReader(
                          nextCameraIndex == 0
                            ? translate("Now facing the default rear camera", isEnglish: isEnglish ?? true)
                            : translate("Now facing the selfie camera", isEnglish: isEnglish ?? true),
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
      ),
    );
  }

  Future<void> AnnounceCurrentMode(String mode) async {
    setState(() {
      currentMode = mode;
    });
    print("$mode mode selected");
    _announceToScreenReader("${translate(mode, isEnglish: isEnglish ?? true)}${translate(" mode activated", isEnglish: isEnglish ?? true)}");
  }

  IconData modeIcon(String mode) {
    switch (mode) {
      case "picture describe":
        return Icons.image;
      case "Read":
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
      enabled: false,
      container: false,
      label: translate('Mode selection controls', isEnglish: isEnglish ?? true),
      child: Container(
        color: const Color.fromARGB(50, 0, 0, 0),
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
                  enabled: false,
                  button: true,
                  label: '${translate(mode, isEnglish: isEnglish ?? true)}${translate(" mode", isEnglish: isEnglish ?? true)}',
                  hint: isSelected
                      ? translate('Currently selected', isEnglish: isEnglish ?? true)
                      : '${translate("Double tap to activate ", isEnglish: isEnglish ?? true)}${translate(mode.toLowerCase(), isEnglish: isEnglish ?? true)}${translate(" mode", isEnglish: isEnglish ?? true)}',
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
                          await AnnounceCurrentMode(mode);
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

  bool _hasSent = false;

  Future<void> _startVoiceChat() async {
    if (!_isListening) {
      _hasSent = false; // Reset the flag before starting
      await flutterTts.awaitSpeakCompletion(true);
      await _announceToScreenReader(
        translate("Voice chat started. Please speak your question.", isEnglish: isEnglish ?? true),
      );
      await flutterTts.awaitSpeakCompletion(true);

      setState(() {
        _isListening = true;
        _voiceInput = '';
      });

      bool available = await _speech.initialize(
        onStatus: (val) async {
          if ((val == 'done' || val == 'notListening') && !_hasSent) {
            _hasSent = true; // Prevent future calls
            setState(() => _isListening = false);
            _speech.stop();

            if (_voiceInput.trim().isNotEmpty) {
              await _sendVoiceToFanar(_voiceInput.trim());
            } else {
              _announceToScreenReader(
                translate("No voice input detected. Please try again.", isEnglish: isEnglish ?? true),
              );
            }
          }
        },
        onError: (val) {
          setState(() => _isListening = false);
          _announceToScreenReader(
            translate("Voice recognition error. Please try again.", isEnglish: isEnglish ?? true),
          );
        },
      );

      if (available) {
        _speech.listen(
          onResult: (val) {
            print(val.recognizedWords);
            setState(() {
              _voiceInput = val.recognizedWords;
            });
          },
          localeId: isEnglish == true ? 'en_US' : 'ar_AR',
        );
      } else {
        _announceToScreenReader(
          translate("Speech recognition not available.", isEnglish: isEnglish ?? true),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }


  Future<void> _sendVoiceToFanar(String userQuery) async {
    String prompt = translate("You are an assistive AI designed to help blind users. Always answer clearly, concisely. When responding, act as a guide for someone who cannot see the screen. Use simple and accessible language. If any previous questions or context are available, use them to enhance the accuracy and relevance of your response.\nUser question: ", isEnglish: isEnglish ?? true);
    prompt = "$prompt $userQuery";
    await callFanarAPI(query: prompt);
  }

  @override
  Widget build(BuildContext context) {
    final List<String> otherModes = allModes
        .where(
          (mode) => mode != "picture describe" && mode != "Read",
        )
        .toList();
    return Semantics(
      enabled: false,
      container: false,
      label: translate('Main screen with camera preview, controls, and mode selection',isEnglish: isEnglish ?? true),
      child: Scaffold(
        // appBar: _buildAppBar(),
        body: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(child: _buildCameraPreview()),
                  // Inline AppBar at the top, above the bottom-aligned column
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        height: 70,
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(0, 0, 0, 0),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Semantics(
                              excludeSemantics: true,
                              button: true,
                              label: translate('Open settings', isEnglish: isEnglish ?? true),
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                iconSize: 40,
                                icon: const Icon(Icons.settings, color: Colors.white),
                                onPressed: () {
                                  _announceToScreenReader(translate("Settings opened", isEnglish: isEnglish ?? true));
                                },
                              ),
                            ),
                            Semantics(
                              excludeSemantics: true,
                              button: true,
                              label: translate('Instructions', isEnglish: isEnglish ?? true),
                              child: IconButton(
                                iconSize: 40,
                                icon: const Icon(Icons.help_outline, color: Colors.white),
                                onPressed: () {
                                  _announceToScreenReader(
                                    translate("Instructions opened. Please scroll through every instructions given.", isEnglish: isEnglish ?? true),
                                  );
                                  setState(() {
                                    _showInstructionsDialog = true;
                                  });
                                  if (_showInstructionsDialog) {
                                    instructionsModal(context, translate, isEnglish, () {
                                      setState(() {
                                        _showInstructionsDialog = false;
                                      });
                                      Navigator.of(context).pop();
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 213,
                    left: 0,
                    right: 0,
                    child: SizedBox(
                      height: 80,
                      child: Container(
                        color: const Color.fromARGB(100, 0, 0, 0),
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: allModes.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final mode = allModes[index];
                            final bool isSelected = mode == currentMode;
                            return Semantics(
                              button: true,
                              label: '${translate(mode, isEnglish: isEnglish ?? true)}${translate(" mode", isEnglish: isEnglish ?? true)}',
                              hint: isSelected
                                  ? translate('Currently selected', isEnglish: isEnglish ?? true)
                                  : '${translate("Double tap to activate ", isEnglish: isEnglish ?? true)}${translate(mode.toLowerCase(), isEnglish: isEnglish ?? true)}${translate(" mode", isEnglish: isEnglish ?? true)}',
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
                                      size: 30,
                                      semanticLabel: '',
                                    ),
                                    onPressed: () async {
                                      await AnnounceCurrentMode(mode);
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _buildBottomControls(),
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
