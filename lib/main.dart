import 'package:flutter/material.dart';

import 'leaderboard_page.dart';
import 'profile_page.dart';
import 'info_page.dart';
import 'shop_page.dart';
import 'music_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  // 1. Holder styr på hvilket index der er valgt
  int _selectedIndex = 0;

  // 2. Liste over de sider, menuen skal vise
  static const List<Widget> _pages = <Widget>[
    ShopPage(),
    MusicPage(),
    LeaderboardPage(),
    ProfilePage(),
    InfoPage(),
  ];

  // 3. Funktion der opdaterer index, når man trykker på menuen
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TrashQueue Player App'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      // Viser den side fra listen, der matcher det valgte index
      body: _pages[_selectedIndex], 
      
      // HER ER BUNDMENUEN
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.add_shopping_cart),
            label: 'My Shop',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.music_note),
            label: 'Music',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.addchart),
            label: 'Leaderboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.info),
            label: 'Info',
          ),
        ],
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepPurple,
        onTap: _onItemTapped, // Kalder funktionen når man trykker
      ),
    );
  }
}

