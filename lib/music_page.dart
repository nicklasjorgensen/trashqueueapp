import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MusicPage extends StatefulWidget {
  const MusicPage({super.key});

  @override
  State<MusicPage> createState() => _MusicPageState();
}

class _MusicPageState extends State<MusicPage> {
  Map<String, dynamic>? _musicData;
  bool _isLoading = true;
  String _errorMessage = "";

  @override
  void initState() {
    super.initState();
    _fetchMusicData();
  }

  Future<void> _fetchMusicData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    try {
      final response = await http.get(
        Uri.parse('https://au795615.eu.pythonanywhere.com/get_queue'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _musicData = jsonDecode(response.body);
          _isLoading = false;
        });
      } else if (response.statusCode == 404) {
        setState(() {
          _errorMessage = "Ingen aktiv afspilning på Spotify";
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = "Server fejl: ${response.statusCode}";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Kunne ikke forbinde til serveren";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: _fetchMusicData, child: const Text("Prøv igen")),
          ],
        ),
      );
    }

    final currentlyPlaying = _musicData?['currently_playing'];
    final queue = _musicData?['queue'] as List<dynamic>? ?? [];

    return RefreshIndicator(
      onRefresh: _fetchMusicData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text("Nu afspilles", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          
          // --- NOW PLAYING CARD ---
          if (currentlyPlaying != null)
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    currentlyPlaying['album']['images'][0]['url'],
                    width: 60, height: 60, fit: BoxFit.cover,
                  ),
                ),
                title: Text(currentlyPlaying['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(currentlyPlaying['artists'][0]['name']),
                trailing: const Icon(Icons.equalizer, color: Colors.green),
              ),
            )
          else
            const Text("Intet spiller lige nu"),

          const SizedBox(height: 30),
          const Text("Næste i køen", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Divider(),

          // --- QUEUE LIST ---
          ...queue.map((track) {
  // Vi henter URL'en på samme måde som ved den aktive sang
  final images = track['album']?['images'] as List<dynamic>?;
  final thumbnailUrl = (images != null && images.isNotEmpty) 
      ? images.last['url'] // Vi bruger 'last' for at få det mindste billede (typisk 64x64) til køen
      : null;

  return ListTile(
    leading: ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: thumbnailUrl != null 
          ? Image.network(thumbnailUrl, width: 40, height: 40, fit: BoxFit.cover)
          : const Icon(Icons.music_note, size: 40),
    ),
    title: Text(
      track['name'], 
      maxLines: 1, 
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
    ),
    subtitle: Text(
      track['artists'][0]['name'],
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
  );
}),
        ],
      ),
    );
  }
}