import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(const MaterialApp(home: DownloadScreen()));

class DownloadScreen extends StatefulWidget {
  const DownloadScreen({super.key});
  @override
  State<DownloadScreen> createState() => _DownloadScreenState();
}

class _DownloadScreenState extends State<DownloadScreen> {
  final _urlController = TextEditingController();
  String _msg = '';
  
  Future<void> _download(String fmt) async {
    setState(() => _msg = 'Processing...');
    await Permission.manageExternalStorage.request();
    
    String url = _urlController.text.trim();
    // बिना छेड़छाड़ के लिंक निकालना (Simple extraction)
    String id = url.contains('v=') ? url.split('v=')[1].split('&')[0] : url.split('/').last.split('?')[0];

    try {
      final res = await http.get(
        Uri.parse('https://youtube-mp4-mp3-downloader.p.rapidapi.com/api/v1/download?format=$fmt&id=$id'),
        headers: {'x-rapidapi-key': '2a2d800e5cmsh0798dd20ef51d17p1d9715jsn2c69b2d0f7d3', 'x-rapidapi-host': 'youtube-mp4-mp3-downloader.p.rapidapi.com'},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        String? link = data['downloadUrl'] ?? data['url'] ?? data['link'] ?? data['result'];
        if (link != null) {
          setState(() => _msg = 'Success! Download starting...');
        } else {
          setState(() => _msg = 'API Error: ' + (data['message'] ?? 'No link found.'));
        }
      }
    } catch (e) { setState(() => _msg = 'Error: $e'); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('KC-ARADHANA')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          TextField(controller: _urlController, decoration: const InputDecoration(hintText: 'Paste YouTube Link')),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: () => _download('mp3'), child: const Text('Download MP3')),
          const SizedBox(height: 10),
          ElevatedButton(onPressed: () => _download('720'), child: const Text('Download Video')),
          const SizedBox(height: 20),
          Text(_msg, style: const TextStyle(color: Colors.red)),
        ]),
      ),
    );
  }
}
