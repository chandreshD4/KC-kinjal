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

    // स्मार्ट वीडियो आईडी एक्सट्रैक्टर
    String id = '';
    RegExp regExp = RegExp(r'([a-zA-Z0-9_-]{11})');
    Iterable<Match> matches = regExp.allMatches(url);
    for (Match match in matches) {
      String possibleId = match.group(0)!;
      if (possibleId != 'youtu' && possibleId != 'watch') {
        id = possibleId;
        break;
      }
    }

    if (id.isEmpty || id.length != 11) {
      setState(() { _msg = 'ખોટી લિંક: આઈડી મળી નથી.'; _loading = false; });
      return;
    }

    try {
      // YouTube Media Downloader का सही कन्वर्टर एंडपॉइंट
      final res = await http.get(
        Uri.parse('https://youtube-media-downloader.p.rapidapi.com/v2/video/details?videoId=$id'),
        headers: {
          'x-rapidapi-key': '2a2d800e5cmsh0798dd20ef51d17p1d9715jsn2c69b2d0f7d3',
          'x-rapidapi-host': 'youtube-media-downloader.p.rapidapi.com'
        },
      );
      
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        
        // इस API के रिस्पॉन्स से ऑडियो (MP3) का बेस्ट लिंक ढूंढना
        String? audioLink;
        if (data['audios'] != null && data['audios']['items'] != null && data['audios']['items'].isNotEmpty) {
          audioLink = data['audios']['items'][0]['url'];
        }
        
        if (audioLink != null) {
          setState(() => _msg = 'સફળતા! ઓડિયો ડાઉનલોડ શરૂ થયું.');
        } else {
          setState(() => _msg = 'API એરર: ઓડિયો લિંક મળી નથી.');
        }
      } else {
        setState(() => _msg = 'સર્વર રિસ્પોન્સ એરર કોડ: ${res.statusCode}');
      }
    } catch (e) {
      setState(() => _msg = 'કનેક્શન એરર: ફરી પ્રયાસ કરો.');
    } finally {
      setState(() { _loading = false; });
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink, 
                  minimumSize: const Size(double.infinity, 55), 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                ),
                onPressed: _loading ? null : _download,
                icon: const Icon(Icons.music_note, color: Colors.white), // केवल एक सिंगल वाइट म्यूजिक आइकॉन
                label: const Text('Download MP3', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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
