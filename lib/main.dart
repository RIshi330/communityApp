import 'package:commity_app1/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'theme.dart';

void main() async {
  // ✅ Ensure Flutter bindings are initialized before using async
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Pre-initialize SharedPreferences for 30-day session management
  await SharedPreferences.getInstance();

  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', 'US')],
      home: const CommitySplashScreen(), //  Splash 
    );
  }
}