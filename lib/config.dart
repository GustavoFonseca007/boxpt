import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get_storage/get_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:country_icons/country_icons.dart';
import 'package:eco/main.dart';
import 'package:eco/login.dart';
import 'package:get/get.dart';

class Config extends StatefulWidget {
  const Config({Key? key}) : super(key: key);

  @override
  _ConfigState createState() => _ConfigState();
}

class _ConfigState extends State<Config> {
  bool _darkModeEnabled = false;
  bool _notificationsEnabled = false;

  GetStorage box = GetStorage();
  final List locale = [
    {'name': 'PORTUGUESE', 'locale': Locale('pt', 'BR')},
    {'name': 'ITALIAN', 'locale': Locale('it', 'IT')},
    {'name': 'SPANISH', 'locale': Locale('es', 'ES')},
  ];
  updatelanguage(Locale locale) {
    Get.updateLocale(locale);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _darkModeEnabled = Get.isDarkMode;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Definições'.tr,
          style: theme.textTheme.headline6?.copyWith(
            color: Get.isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        centerTitle: true,
        backgroundColor: Get.isDarkMode ? Colors.black : Colors.white,
        foregroundColor: Get.isDarkMode ? Colors.white : Colors.black,
        iconTheme: theme.iconTheme.copyWith(
          color: Get.isDarkMode ? Colors.white : Colors.black,
        ),
      ),
      body: Container(
        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 15),
        child: ListView(
          children: [
            ExpansionTile(
              title: Text('Linguagem'.tr),
              leading: Icon(Icons.language),
              children: [
                ListTile(
                  title: Text('Português'.tr),
                  leading: Image.asset(
                    'icons/flags/png/pt.png',
                    package: 'country_icons',
                    height: 24,
                    width: 24,
                  ),
                  onTap: () {
                    setState(() {
                      var locale = Locale('pt', 'BR');
                      Get.updateLocale(locale);
                      updatelanguage(locale);
                    });
                  },
                ),
                ListTile(
                  title: Text('Espanhol'.tr),
                  leading: Image.asset(
                    'icons/flags/png/es.png',
                    package: 'country_icons',
                    height: 24,
                    width: 24,
                  ),
                  onTap: () {
                    setState(() {
                      var locale = Locale('es', 'ES');
                      Get.updateLocale(locale);
                      updatelanguage(locale);
                    });
                  },
                ),
                ListTile(
                  title: Text('Italiano'.tr),
                  leading: Image.asset(
                    'icons/flags/png/it.png',
                    package: 'country_icons',
                    height: 24,
                    width: 24,
                  ),
                  onTap: () {
                    setState(() {
                      var locale = Locale('it', 'IT');
                      Get.updateLocale(locale);
                      updatelanguage(locale);
                    });
                  },
                ),
              ],
            ),
            SwitchListTile(
              title: Text("Notificações".tr),
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _notificationsEnabled = value;
                  
                });
              },
              secondary: Icon(Icons.notifications),
            ),
            ListTile(
              title: Text("Modo Escuro".tr),
              leading: _darkModeEnabled
                  ? Icon(Icons.dark_mode)
                  : Icon(Icons.wb_sunny),
              trailing: Switch(
                value: _darkModeEnabled,
                activeColor: Colors.black,
                onChanged: (value) {
                  setState(() {
                    _darkModeEnabled = value;
                    Get.changeThemeMode(
                        _darkModeEnabled ? ThemeMode.dark : ThemeMode.light);
                  });
                },
              ),
            ),
            ListTile(
              title: Text('Política de Privacidade'.tr),
              leading: Icon(Icons.privacy_tip),
              trailing: Icon(Icons.arrow_forward_ios),
              onTap: () {},
            ),
            ListTile(
              title: Text('Sair'.tr, style: TextStyle(color: Colors.red)),
              leading: Icon(Icons.logout, color: Colors.red),
              onTap: () async {
                // Implementar a lógica de logout
                await FirebaseAuth.instance.signOut();
                Get.offAll(() => Login());
              },
            ),
          ],
        ),
      ),
    );
  }
}
