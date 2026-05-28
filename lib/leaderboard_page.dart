import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'player_stats_page.dart';


class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  // Funktion der henter data fra dit API
  Future<List<dynamic>> fetchLeaderboard() async {
    final response = await http.get(
      Uri.parse('https://au795615.eu.pythonanywhere.com/get_deposit_stats'),
    );
    

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['stats']; // Returnerer listen [["Navn", point, cardID], ...]
    } else {
      throw Exception('Kunne ikke hente leaderboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {}); 
      },
      child: FutureBuilder<List<dynamic>>(
        future: fetchLeaderboard(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.4,
                  child: Center(child: Text("Fejl: ${snapshot.error}")),
                ),
              ],
            );
          }

          final players = snapshot.data!;
          
          // Sorterer listen efter point (hvis point står på index 1)
          players.sort((a, b) => b[1].compareTo(a[1]));
          
          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: players.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final player = players[index]; 
              
              final String playerName = player[0].toString();
              final String points = player[1].toString();
              final int cardId = int.parse(player[2].toString());

              return ListTile(
                leading: Text("${index + 1}."),
                title: Text(playerName),
                trailing: Text("$points deposits"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PlayerStatsPage(cardId: cardId),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}