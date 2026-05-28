import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:nfc_manager/nfc_manager.dart';

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

  // Henter id lokalt fra SharedPreferences
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      String? savedID = prefs.getString('user_id');
      _idController.text = savedID ?? '';
      _hasID = _idController.text.isNotEmpty;
      _isLoading = false;
    });
  }

  // Gemmer id lokalt
  Future<void> _saveID() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', _idController.text);
    setState(() {
      _hasID = _idController.text.isNotEmpty;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID gemt lokalt!')),
      );
    }
  }

  // Starter NFC scanning og henter ID fra serveren via UID
  Future<void> _startNFCScan() async {
    bool isAvailable = await NfcManager.instance.isAvailable();
    if (!isAvailable) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('NFC er ikke tilgængeligt på denne enhed.')),
        );
      }
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Klar... Hold dit tag op til bagsiden af telefonen.')),
      );
    }

    NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
      // Stop sessionen med det samme vi har fundet et tag
      NfcManager.instance.stopSession();

      final data = tag.data;
      List<int>? identifier;
      
      // Udtrækker UID afhængigt af tech-typen på chippen
      if (data.containsKey('nfca')) identifier = data['nfca']['identifier'];
      else if (data.containsKey('nfcb')) identifier = data['nfcb']['identifier'];
      else if (data.containsKey('nfcf')) identifier = data['nfcf']['identifier'];
      else if (data.containsKey('nfcv')) identifier = data['nfcv']['identifier'];
      else if (data.containsKey('mifare')) identifier = data['mifare']['identifier'];

      if (identifier == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kunne ikke læse NFC-taggets UID.')),
          );
        }
        return;
      }

      // Konverter byte-array til en Hex String (f.eks. [4, 161, 178, 195] -> "04a1b2c3")
      String uidHex = identifier.map((e) => e.toRadixString(16).padLeft(2, '0')).join('');

      try {
        final response = await http.get(
          Uri.parse('https://au795615.eu.pythonanywhere.com/get_ring_id/$uidHex'),
        );

        if (response.statusCode == 200) {
          // De-serialiserer JSON-respons til et Map (Dictionary)
          final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
          
          if (jsonResponse.containsKey('ID') && jsonResponse['ID'] != null) {
            final fetchedId = jsonResponse['ID'].toString();
            
            setState(() {
              _idController.text = fetchedId;
              _hasID = true;
            });
            
            // Gemmer det automatisk lokalt, så appen husker det næste gang
            await _saveID(); 

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('ID fundet og gemt: $fetchedId')),
              );
            }
          } else {
             if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Kunne ikke finde "ID" i serverens svar.')),
              );
            }
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Fejl fra server (${response.statusCode}): ${response.body}')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Netværksfejl: $e')),
          );
        }
      }
    });
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
          const Text("Trin 1: Indstil dit ID", 
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          TextField(
            controller: _idController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Indtast cardID præcis som det står på dit kort',
              prefixIcon: Icon(Icons.badge),
            ),
            onChanged: (val) => setState(() => _hasID = val.isNotEmpty),
          ),
          const SizedBox(height: 10),
          
          // Knapper til NFC-skan og manuel lagring sat pænt op i en Row
          Row(
            children: [
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _startNFCScan,
                  icon: const Icon(Icons.nfc),
                  label: const Text("Skan Tag"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade100,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 1,
                child: ElevatedButton(
                  onPressed: _saveID,
                  child: const Text("Gem"),
                ),
              ),
            ],
          ),
          
          const Divider(height: 40),

          const Text("Trin 2: Indtast navn", 
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          
          TextField(
            controller: _nameController,
            enabled: _hasID, 
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: _hasID ? 'Nyt navn' : 'Indtast ID først for at skifte navn',
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