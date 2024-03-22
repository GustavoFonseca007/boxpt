import 'package:eco/LocaleString.dart';
import 'package:eco/config.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:eco/splash.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';

final ThemeData darkTheme = ThemeData.dark();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyCFoUZCfrvFnjblU9GEFWhzpJHvXKkgM7Y",
      appId: "1:651323210384:android:08814d636397dc7bd53615",
      messagingSenderId: "651323210384",
      projectId: "boxpt-a1ee0",
    ),
  );

  await GetStorage.init();

  final box = GetStorage();

  bool? darkModeEnabled = box.read('darkModeEnabled');

  runApp(MyApp(
    darkModeEnabled: darkModeEnabled,
  ));
}

class MyApp extends StatelessWidget {
  final bool? darkModeEnabled;

  const MyApp({Key? key, this.darkModeEnabled}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      translations: LocalString(),
      locale: Locale('pt', 'BR'),
      title: 'My App',
      theme: ThemeData.light(),
      darkTheme: darkModeEnabled == true ? darkTheme : ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      home: Splash(),
    );
  }
}
