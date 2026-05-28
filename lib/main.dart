import 'package:flutter/material.dart';
import 'package:web/web.dart' as web; // Husk at importere web-pakken til URL-tjekket

import 'leaderboard_page.dart';
import 'profile_page.dart';
import 'info_page.dart';
import 'shop_page.dart';
import 'music_page.dart';
import 'gambling_page.dart';

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
  // 1. Holder styr på hvilket index der er valgt. Starter som standard på 0 (Shop)
  int _selectedIndex = 0;

  static const List<Widget> _pages = <Widget>[
    ShopPage(),    
    MusicPage(), 
    LeaderboardPage(),
    ProfilePage(),     
    InfoPage(),
    CoinFlipPage(),
  ];

  @override
  void initState() {
    super.initState();
    _tjekForNfcScan(); // Tjekker URL'en så snart appen åbner
  }

  // Ny funktion der tjekker for ?uid= i URL'en
  void _tjekForNfcScan() {
    final String nuvaerendeUrl = web.window.location.href;
    final uri = Uri.parse(nuvaerendeUrl);

    // Hvis appen blev åbnet via et NFC-tag...
    if (uri.queryParameters.containsKey('uid')) {
      setState(() {
        // ... så skifter vi automatisk fanen til ProfilePage (index 3)
        _selectedIndex = 3;
      });
    }
  }

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
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.info),
            label: 'Info',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.casino),
            label: 'Gambling',
          )
        ],
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepPurple,
        onTap: _onItemTapped, // Kalder funktionen når man trykker
      ),
    );
  }
}