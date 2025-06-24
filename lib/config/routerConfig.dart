import 'package:ayn/routes/home.dart';
import 'package:ayn/routes/languageSelection.dart';
import 'package:ayn/routes/settings.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String homeRoute = '/';
const String languageSelectionRoute = '/language-selection';
const String settingsRoute = '/settings';

final GoRouter router = GoRouter(
  // initialLocation: "/",
  redirect: (context, state) async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstTime = prefs.getBool("first_time") ?? true;
    print(isFirstTime);
    if(isFirstTime){  
      return languageSelectionRoute;
    }
    return homeRoute;
  },
  routes: <RouteBase>[
    GoRoute(
      path: homeRoute,
      builder: (context, state) => HomePage(),
    ),
    GoRoute(
      path: languageSelectionRoute,
      builder: (context, state) => const LanguageSelectionPage(),
    ),
    GoRoute(
      path: settingsRoute,
      builder: (context, state) => const SettingsPage(),
    ),
  ],
);

