import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:web/web.dart' as web; 

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = true;
  bool _hasID = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Henter id lokalt, eller tjekker om appen blev åbnet via et NFC-link
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 1. Tjek først om der ligger et gemt ID i forvejen
    String? savedID = prefs.getString('user_id');

    // 2. Hent den aktuelle URL direkte fra browserens vindue via package:web
    final String nuvaerendeUrl = web.window.location.href;
    final uri = Uri.parse(nuvaerendeUrl);
    final String? uidFraNFC = uri.queryParameters['uid'];

    if (uidFraNFC != null && uidFraNFC.isNotEmpty) {
      // Hvis der kom et UID med fra NFC-linket (?uid=04a1b2c3), henter vi ID fra din server
      await _fetchIdFromServer(uidFraNFC);
    } else {
      // Hvis ikke der er scannet et tag, indlæser vi bare det gamle ID (hvis det findes)
      setState(() {
        _idController.text = savedID ?? '';
        _hasID = _idController.text.isNotEmpty;
        _isLoading = false;
      });
    }
  }

  // Funktion der kalder din PythonAnywhere server og finder ID ud fra tagget
  Future<void> _fetchIdFromServer(String uidHex) async {
    try {
      final response = await http.get(
        Uri.parse('https://au795615.eu.pythonanywhere.com/get_ring_id/$uidHex'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        
        if (jsonResponse.containsKey('ID') && jsonResponse['ID'] != null) {
          final fetchedId = jsonResponse['ID'].toString();
          
          // Opdater tekstfeltet i appen
          setState(() {
            _idController.text = fetchedId;
            _hasID = true;
          });
          
          // Gem det med det samme i SharedPreferences, så enheden husker det fremover
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_id', fetchedId);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('NFC Tag registreret! Dit ID er sat til: $fetchedId')),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Kunne ikke finde ID på serveren (${response.statusCode})')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Netværksfejl verifikation: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // POST for at ændre navn på backend
  Future<void> _changeNameOnServer() async {
    if (_nameController.text.isEmpty) return;

    try {
      final response = await http.post(
        Uri.parse('https://au795615.eu.pythonanywhere.com/change_name'),
        body: {
          'new_name': _nameController.text,
          'cardID': _idController.text,
        },
      );

      if (mounted) {
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Navn ændret på serveren!')),
          );
          _nameController.clear();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fejl: ${response.body}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kunne ikke forbinde til serveren: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Dit ID", 
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          
          TextField(
            controller: _idController,
            readOnly: true, // Gør at brugeren ikke kan ændre teksten
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: _hasID ? 'Dit tilknyttede ID' : 'Scan ring for at logge ind',
              prefixIcon: const Icon(Icons.badge),
              filled: true,
              fillColor: Colors.grey.shade200, // Giver det et låst udseende
            ),
          ),
          
          const Divider(height: 40),

          const Text("Indstil navn", 
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          
          TextField(
            controller: _nameController,
            enabled: _hasID, 
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: _hasID ? 'Nyt navn' : 'Scan ring først for at kunne skifte navn',
              prefixIcon: Icon(Icons.person, color: _hasID ? Colors.blue : Colors.grey),
              filled: !_hasID,
              fillColor: Colors.grey.shade200,
            ),
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _hasID ? _changeNameOnServer : null,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade100),
              child: const Text("Opdater navn på server"),
            ),
          ),
        ],
      ),
    );
  }
}