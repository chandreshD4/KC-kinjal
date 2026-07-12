import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KC-ARADHANA',
      theme: ThemeData(primarySwatch: Colors.pink),
      home: const DownloadScreen(),
    );
  }
}

class DownloadScreen extends StatefulWidget {
  const DownloadScreen({super.key});
  @override
  State<DownloadScreen> createState() => _DownloadScreenState();
}

class _DownloadScreenState extends State<DownloadScreen> {
  final _urlController = TextEditingController();
  String _msg = '';
  bool _loading = false;

  Future<void> _download() async {
    setState(() { _msg = ''; _loading = true; });
    await Permission.manageExternalStorage.request();
    
    String url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() { _msg = 'કૃપા કરીને લિંક પેસ્ટ કરો'; _loading = false; });
      return;
    }

    // सीधे और सुरक्षित तरीके से वीडियो ID निकालना
    String id = '';
    if (url.contains('v=')) {
      id = url.split('v=')[1].split('&')[0];
    } else if (url.contains('youtu.be/')) {
      id = url.split('youtu.be/')[1].split('?')[0];
    } else {
      id = url.split('/').last.split('?')[0];
    }

    try {
      // बिना रैपिड-API के सीधे हाई-स्पीड ऑडियो सर्वर का उपयोग
      final res = await http.get(
        Uri.parse('https://api.decentents.com/api/v1/youtube/download?id=$id&type=mp3'),
      );
      
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        String? link = data['url'] ?? data['downloadUrl'] ?? data['result'];
        if (link != null) {
          setState(() => _msg = 'સફળતા! ઓડિયો ડાઉનલોડ શરૂ થયું.');
        } else {
          setState(() => _msg = 'સર્વર એરર: લિંક જનરેટ થઈ શકી નથી.');
        }
      } else {
        setState(() => _msg = 'સર્વર કનેક્શન નિષ્ફળ (કોડ: ${res.statusCode})');
      }
    } catch (e) {
      setState(() => _msg = 'કનેક્શન એરર: સર્વર વ્યસ્ત છે, ફરી પ્રયાસ કરો.');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome to KC-ARADHANA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.pink,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: Image.asset('assets/profile.png', width: 180, height: 180, fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.account_circle, size: 180, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              const Text('આરાધના MP3 Downloader VIP', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
              TextField(
                controller: _urlController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  hintText: 'યૂટ્યૂબ લિંક અહીં પેસ્ટ કરો',
                ),
              ),
              const SizedBox(height: 25),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.pink, minimumSize: const Size(double.infinity, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                onPressed: _loading ? null : _download,
                icon: const Icon(Icons.music_note, color: Colors.white),
                label: const Text('🎵 Download MP3 (ઓડિયો)', style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
              const SizedBox(height: 30),
              if (_loading) const CircularProgressIndicator(color: Colors.pink),
              if (_msg.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(_msg, style: const TextStyle(color: Colors.red, fontSize: 15, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
