import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: DownloadScreen()));

class DownloadScreen extends StatefulWidget {
  const DownloadScreen({super.key});
  @override
  State<DownloadScreen> createState() => _DownloadScreenState();
}

class _DownloadScreenState extends State<DownloadScreen> {
  final _urlController = TextEditingController();
  String _msg = 'तैयार है!';

  Future<void> _download(String fmt) async {
    setState(() => _msg = 'डाउनलोड हो रहा है...');
    await Permission.manageExternalStorage.request();
    String url = _urlController.text.trim();
    String id = url.contains('v=') ? url.split('v=')[1].split('&')[0] : url.split('/').last.split('?')[0];

    try {
      final res = await http.get(
        Uri.parse('https://youtube-mp4-mp3-downloader.p.rapidapi.com/api/v1/download?format=$fmt&id=$id'),
        headers: {'x-rapidapi-key': '2a2d800e5cmsh0798dd20ef51d17p1d9715jsn2c69b2d0f7d3', 'x-rapidapi-host': 'youtube-mp4-mp3-downloader.p.rapidapi.com'},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['downloadUrl'] != null || data['url'] != null) {
          setState(() => _msg = 'सफलता! डाउनलोड शुरू हुआ.');
        } else {
          setState(() => _msg = 'एरर: लिंक नहीं मिला.');
        }
      } else {
        setState(() => _msg = 'सर्वर एरर: ${res.statusCode}');
      }
    } catch (e) { setState(() => _msg = 'एरर: $e'); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('KC-ARADHANA')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          TextField(controller: _urlController, decoration: const InputDecoration(hintText: 'यूट्यूब लिंक यहाँ डालें')),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: () => _download('mp3'), child: const Text('MP3 डाउनलोड करें')),
          ElevatedButton(onPressed: () => _download('720'), child: const Text('विडियो डाउनलोड करें')),
          const SizedBox(height: 20),
          Text(_msg, style: const TextStyle(color: Colors.pink, fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }
}
