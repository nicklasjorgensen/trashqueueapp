import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  // Funktion der henter data fra dit API
  Future<List<dynamic>> fetchLeaderboard() async {
    final response = await http.get(
      Uri.parse('https://au795615.eu.pythonanywhere.com/get_players'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['players']; // Returnerer listen [["Navn", rang, point], ...]
    } else {
      throw Exception('Kunne ikke hente leaderboard');
    }
  }

  @override
Widget build(BuildContext context) {
  // 1. Pak hele molevitten ind i en RefreshIndicator
  return RefreshIndicator(
    onRefresh: () async {
      // 2. Når man trækker ned, fortæller vi Flutter at den skal genindlæse
      setState(() {}); 
    },
    child: FutureBuilder<List<dynamic>>(
      future: fetchLeaderboard(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          // Tip: For at man kan trække ned ved en fejl, skal der være noget scrollbart
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
        
        return ListView.separated(
          // 3. VIGTIGT: Denne linje sikrer at man altid kan trække ned
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: players.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            final player = players[index];
            return ListTile(
              leading: CircleAvatar(child: Text("${player[1]}")),
              title: Text(player[0]),
              trailing: Text("${player[2]} pts"),
            );
          },
        );
      },
    ),
  );
}
}