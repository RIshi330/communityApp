import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> requestPermissions() async {

  await [
    Permission.camera,
    Permission.microphone,
    Permission.location,
  ].request();

}

Future<void> checkFirstLogin() async {

  final prefs = await SharedPreferences.getInstance();

  bool isFirstLogin = prefs.getBool('isFirstLogin') ?? true;

  if (isFirstLogin) {

    await requestPermissions();

    await prefs.setBool('isFirstLogin', false);
  }
}