import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  String? _cardID;
  String _userName = "Henter...";
  int _points = 0;
  bool _isLoading = true;
  List _searchResults = [];
  bool _showSearch = false; // Styrer om søgefeltet vises (efter køb)
  Timer? _debounce;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAndFetchData();
  }

  // 1. Henter ID fra SharedPreferences, 2. Henter player-data fra serveren
  Future<void> _loadAndFetchData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedID = prefs.getString('user_id');

    if (savedID != null && savedID.isNotEmpty) {
      setState(() => _cardID = savedID);
      await _fetchUserData(savedID);
    } else {
      setState(() {
        _userName = "Intet ID fundet på Profil";
        _isLoading = false;
      });
    }
  }

  // Henter data via din /get_player/<cardID> route
  Future<void> _fetchUserData(String id) async {
    try {
      final response = await http.get(
        Uri.parse('https://au795615.eu.pythonanywhere.com/get_player/$id'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Da din Python returnerer jsonify(player=player), henter vi data her:
        final player = data['player'];

        setState(() {
          _userName = player['player'] ?? "Ukendt";
          _points = player['score'] ?? 0;
          _isLoading = false;
        });
      } else {
        setState(() {
          _userName = "Bruger ikke fundet";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _userName = "Forbindelsesfejl";
        _isLoading = false;
      });
    }
  }

  Future<void> _makePurchase(BuildContext context, String endpoint, String itemName) async {
    if (_cardID == null) return;

    final url = Uri.parse('https://au795615.eu.pythonanywhere.com/$endpoint');
    
    try {
      // Vi sender cardID som form-data (som din server forventer)
      final response = await http.post(
        url,
        body: {'cardID': _cardID}, 
      );
      if (context.mounted) {
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$itemName gennemført!'), backgroundColor: Colors.green),
          );
          // Opdater labelen øverst med det samme så man kan se de nye point
          _fetchUserData(_cardID!);
        if (endpoint == ('skip_purchase'))
        {
            http.post(Uri.parse('https://au795615.eu.pythonanywhere.com/spotify_skip'));
          }
        if (endpoint == ('song_purchase'))
        {
          setState(() => _showSearch = true);
        }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ikke nok point eller fejl på serveren'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kunne ikke forbinde til serveren')),
        );
      }
    }
  }

  void _confirmPurchase(BuildContext context, String title, int cost, String endpoint) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Bekræft køb'),
          content: Text('Vil du købe "$title" for $cost point?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), 
              child: const Text('Annuller'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _makePurchase(context, endpoint, title);
              },
              child: const Text('Køb nu'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // --- TOP LABEL: Navn, ID og Points ---
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.deepPurple.shade50,
            border: Border(bottom: BorderSide(color: Colors.deepPurple.shade100)),
          ),
          child: Column(
            children: [
              Text(
                _userName,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepPurple),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ID Chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.deepPurple.shade100),
                    ),
                    child: Text("ID: ${_cardID ?? '?'}", style: const TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(width: 15),
                  // Points Chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.stars, size: 16, color: Colors.orange),
                        const SizedBox(width: 5),
                        Text(
                          "$_points Point",
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // --- SHOP INDHOLD ---
        Expanded(
          child: _showSearch 
          ? _buildSearchUI()
          : _buildActionButtons()
        ),
      ],
    );
  }

  Future<void> _onSearchChanged(String query) async {
  if (_debounce?.isActive ?? false) _debounce!.cancel();
  _debounce = Timer(const Duration(milliseconds: 500), () async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    final url = Uri.parse('https://au795615.eu.pythonanywhere.com/spotify_search');
    final response = await http.post(url, body: {'search': query});

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _searchResults = data['tracks']['items'];
      });
    }
  });
}

Future<void> _queueSelectedSong(String uri) async {
  final url = Uri.parse('https://au795615.eu.pythonanywhere.com/spotify_playback');
  final response = await http.post(url, body: {
    'track-uri': uri,
    'cardID': _cardID,
  });

  if (response.statusCode == 200) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sang tilføjet til køen!'), backgroundColor: Colors.green)
    );
    setState(() {
      _showSearch = false; // Skjul søgning igen efter valg
      _searchController.clear();
      _searchResults = [];
    });
  }
}

Widget _buildSearchUI() {
  return Column(
    children: [
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            labelText: 'Søg efter sang...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() => _showSearch = false),
            ),
            border: const OutlineInputBorder(),
          ),
        ),
      ),
      Expanded(
        child: ListView.builder(
          itemCount: _searchResults.length,
          itemBuilder: (context, index) {
            final track = _searchResults[index];
            return ListTile(
              leading: Image.network(track['album']['images'].last['url']),
              title: Text(track['name']),
              subtitle: Text(track['artists'][0]['name']),
              trailing: const Icon(Icons.add_circle_outline),
              onTap: () => _queueSelectedSong(track['uri']),
            );
          },
        ),
      ),
    ],
  );
}

// Flyt dine gamle knapper ned i denne widget
Widget _buildActionButtons() {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.deepPurple),
        const SizedBox(height: 30),
        ElevatedButton.icon(
          icon: const Icon(Icons.queue_music),
          label: const Text('Queue en sang (1 point)'),
          onPressed: () => _confirmPurchase(context, 'Queue en sang', 1, 'song_purchase'),
          style: ElevatedButton.styleFrom(minimumSize: const Size(260, 55)),
        ),
        const SizedBox(height: 30),
        ElevatedButton.icon(
          icon: const Icon(Icons.skip_next),
          label: const Text('Skip sang (2 point)'),
          onPressed: () => _confirmPurchase(context, 'Skip sang', 2, 'skip_purchase'),
          style: ElevatedButton.styleFrom(minimumSize: const Size(260, 55))),
        
      ],
    ),
  );
}
}