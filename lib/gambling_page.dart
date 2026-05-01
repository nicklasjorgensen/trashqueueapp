import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class CoinFlipPage extends StatefulWidget {
  const CoinFlipPage({super.key});

  @override
  State<CoinFlipPage> createState() => _CoinFlipPageState();
}

class _CoinFlipPageState extends State<CoinFlipPage> {
  bool _isUploading = false;

  // Funktionen der henter ID og sender POST request
  Future<void> _submitChoice(String side) async {
    setState(() => _isUploading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      String? savedID = prefs.getString('user_id');

      if (savedID == null || savedID.isEmpty) {
        _showSnackBar("Fejl: Intet ID fundet. Indstil det under Profil.");
        setState(() => _isUploading = false);
        return;
      }

      // 3. Send POST request
      var url = Uri.parse('https://au795615.eu.pythonanywhere.com/coinflip');
      var response = await http.post(
        url,
        body: {
          'side': side,
          'cardID': savedID,
        },
      );

      if (mounted) {
        if (response.statusCode == 200) {
          _showSnackBar("Result: ${response.body}");
        } else {
          _showSnackBar("Server fejl: ${response.body}");
        }
      }
    } catch (e) {
      if (mounted) _showSnackBar("Kunne ikke forbinde til serveren.");
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _isUploading 
          ? const CircularProgressIndicator() 
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Vælg en side for at spille",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildCoinButton("plat", Colors.amber),
                    _buildCoinButton("krone", Colors.blueGrey),
                  ],
                ),
              ],
            ),
      ),
    );
  }

  Widget _buildCoinButton(String side, Color color) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.all(40),
        shape: const CircleBorder(),
        elevation: 8,
      ),
      onPressed: () => _submitChoice(side),
      child: Text(side, style: const TextStyle(fontSize: 20)),
    );
  }
}