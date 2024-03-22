import 'package:flutter/material.dart';
import 'package:eco/home.dart';
import 'package:eco/perfil.dart';
import 'package:eco/main.dart';
import 'package:eco/treinos.dart';
import 'package:eco/amigospage.dart';
import 'package:eco/config.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Menu extends StatefulWidget {
  const Menu({Key? key}) : super(key: key);

  @override
  State<Menu> createState() => _MenuState();
}

class _MenuState extends State<Menu> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  int _selectedIndex = 0;
  Color _selectedIconColor = Colors.black;
  List<Color> _iconColors = [
    Colors.black,
    Colors.grey,
    Colors.grey,
    Colors.grey,
    Colors.grey,
  ];
  final List locale = [
    {'name': 'PORTUGUESE', 'locale': Locale('pt', 'BR')},
    {'name': 'ITALIAN', 'locale': Locale('it', 'IT')},
    {'name': 'SPANISH', 'locale': Locale('es', 'ES')},
  ];
  updatelanguage(Locale locale) {
    Get.updateLocale(locale);
  }

  static final List<Widget> _widgetOptions = [
    Home(),
    SearchPage(),
    Treino(),
    Perfil(),
    Config(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _iconColors = List.generate(
          _iconColors.length, (i) => i == index ? Colors.black : Colors.grey);
      _selectedIconColor = _iconColors[index];
      print('Tapped index is $_selectedIndex');
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Get.isDarkMode;
    return Scaffold(
      body: _widgetOptions[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: isDarkMode ? Colors.white : _selectedIconColor,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Início'.tr,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Amigos'.tr,
          ),
          BottomNavigationBarItem(
            icon: InkWell(
              onTap: () {
                setState(() {
                  _selectedIndex = 2;
                  _iconColors[2] = isDarkMode ? Colors.white : Colors.black;
                  _selectedIconColor = _iconColors[2];
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: Offset(0, 0),
                    ),
                  ],
                ),
                child: Transform.translate(
                  offset: Offset(0, -15),
                  child: CircleAvatar(
                    backgroundColor: _iconColors[2],
                    child: Icon(Icons.directions_bike,
                        color: isDarkMode ? Colors.black : Colors.white),
                    radius: 20,
                  ),
                ),
              ),
            ),
            label: 'Treino'.tr,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil'.tr,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Configurações'.tr,
          ),
        ],
      ),
    );
  }
}
