import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

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

  // Henter id
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
          ElevatedButton(
            onPressed: _saveID,
            child: const Text("Gem ID"),
          ),
          
          const Divider(height: 40),

          const Text("Trin 2: Indtast navn", 
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          
          // Dette felt er låst (enabled: false) hvis der ikke er indtastet et ID
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