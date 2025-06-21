import 'package:ayn/config/routerConfig.dart';
import 'package:ayn/routes/home.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';


List<CameraDescription> cameras = [];
const String apiKey = 'fmFrMl3wHnB9SFnb8bzxNFpGCVE18Wcz';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Blind Assist',
      // theme: ThemeData.dark(),
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[850],
            textStyle: const TextStyle(fontSize: 18),
          ),
        ),
        textTheme: Theme.of(context).textTheme.apply(fontSizeFactor: MediaQuery.of(context).textScaleFactor),
      ),
      routerConfig: router,
      // home: AssistHomePage(),
    );
  }
}
