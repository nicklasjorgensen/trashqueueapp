import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PlayerStatsPage extends StatefulWidget {
  final int cardId;

  const PlayerStatsPage({super.key, required this.cardId});

  @override
  State<PlayerStatsPage> createState() => _PlayerStatsPageState();
}

class _PlayerStatsPageState extends State<PlayerStatsPage> {
  
  Future<Map<String, dynamic>> fetchAllPlayerData() async {
    final statsResponse = await http.get(
      Uri.parse('https://au795615.eu.pythonanywhere.com/get_player_stats/${widget.cardId}'),
    );

    final drinksResponse = await http.get(
      Uri.parse('https://au795615.eu.pythonanywhere.com/get_player_drinks/${widget.cardId}'),
    );

    if (statsResponse.statusCode == 200 && drinksResponse.statusCode == 200) {
      final statsData = jsonDecode(statsResponse.body);
      final drinksData = jsonDecode(drinksResponse.body);

      
      List<dynamic> drinksList = [];
      if (drinksData is List) {
        drinksList = drinksData;
      } else if (drinksData is Map) {
        drinksList = drinksData['drinks'] ?? drinksData['stats'] ?? [];
      }

      return {
        'stats': statsData['stats'], 
        'drinks': drinksList,        
      };
    }
    else if (statsResponse.statusCode == 200 && drinksResponse.statusCode == 404) {
      final statsData = jsonDecode(statsResponse.body);
      return {
        'stats': statsData['stats'], 
        'drinks': [], // Hvis der ikke er drink-data, returnerer vi en tom liste
      };
    }
    else {
      throw Exception('Kunne ikke hente spiller- eller drinkdata');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spiller Statistik'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchAllPlayerData(), 
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(child: Text("Fejl: ${snapshot.error}"));
          }

          if (!snapshot.hasData) {
            return const Center(child: Text("Ingen data fundet"));
          }

          final statsList = snapshot.data!['stats'] as List<dynamic>;
          final drinksList = snapshot.data!['drinks'] as List<dynamic>;

          if (statsList.isEmpty) {
            return const Center(child: Text("Ingen statistikker fundet"));
          }

          // Udpakning af de generelle stats (ligesom før)
          final String playerName = statsList[0].toString();
          final String deposits = statsList[1].toString();
          final String songsQueued = statsList[2].toString();
          final String songsSkipped = statsList[3].toString();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    playerName,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                
                _buildStatRow("Deposits", deposits),
                const Divider(),
                _buildStatRow("Songs Queued", songsQueued),
                const Divider(),
                _buildStatRow("Songs Skipped", songsSkipped),
                
                const SizedBox(height: 40),
                
                // NYT: Overskrift til drink-tabel
                const Text(
                  "Drink statistics",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                
                // NYT: Drink-tabel (DataTable)
                drinksList.isEmpty
                    ? const Text("Ingen drinks registreret endnu.", style: TextStyle(color: Colors.grey))
                    : SizedBox(
                        width: double.infinity, // Sørger for at tabellen strækker sig helt ud
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(Colors.grey[200]), // Grå baggrund til headeren
                          columns: const [
                            DataColumn(label: Text('Drink', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Antal', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: drinksList.map((drinkItem) {
                            // Da hver drink er en tuple/liste med 2 værdier:
                            final String drinkName = drinkItem[0].toString();
                            final String drinkCount = drinkItem[1].toString();
                            
                            return DataRow(cells: [
                              DataCell(Text(drinkName)),
                              DataCell(Text(drinkCount)),
                            ]);
                          }).toList(),
                        ),
                      ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}