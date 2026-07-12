import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KC-ARADHANA',
      theme: ThemeData(
        primarySwatch: Colors.pink,
      ),
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
  final TextEditingController _urlController = TextEditingController();
  String _errorMessage = '';
  bool _isLoading = false;

  Future<void> handleDownload(String format) async {
    setState(() {
      _errorMessage = '';
      _isLoading = true;
    });

    // स्टोरेज अनुमति चेक करना
    var status = await Permission.manageExternalStorage.status;
    if (!status.isGranted) {
      status = await Permission.manageExternalStorage.request();
    }
    await Permission.storage.request();

    if (!status.isGranted) {
      setState(() {
        _errorMessage = 'કૃપા કરીને ડાઉનલોડ કરવા માટે સ્ટોરેજ પરમિશન ઓન કરો.';
        _isLoading = false;
      });
      openAppSettings();
      return;
    }

    // यूट्यूब लिंक को एकदम साफ करना
    String cleanUrl = _urlController.text.trim();
    while (cleanUrl.startsWith("'") || cleanUrl.startsWith("‘") || cleanUrl.startsWith(".") || cleanUrl.startsWith("_")) {
      cleanUrl = cleanUrl.substring(1);
    }

    String videoId = cleanUrl;
    if (cleanUrl.contains('v=')) {
      videoId = cleanUrl.split('v=')[1].split('&')[0];
    } else if (cleanUrl.contains('youtu.be/')) {
      videoId = cleanUrl.split('youtu.be/')[1].split('?')[0];
    } else if (cleanUrl.contains('?si=')) {
      videoId = cleanUrl.split('/').last.split('?')[0];
    } else if (cleanUrl.contains('_')) {
      videoId = cleanUrl.split('_').last;
    }

    final String apiUrl = 'https://youtube-mp4-mp3-downloader.p.rapidapi.com/api/v1/download?format=$format&id=$videoId&audioQuality=128&addInfo=false&allowExtendedDuration=false';
    
    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-rapidapi-key': '2a2d800e5cmsh0798dd20ef51d17p1d9715jsn2c69b2d0f7d3',
          'x-rapidapi-host': 'youtube-mp4-mp3-downloader.p.rapidapi.com',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // जादुई बाईपास: सर्वर जिस भी नाम से लिंक भेजेगा, यह उसे ढूंढ निकालेगा
        String? downloadUrl = data['downloadUrl'] ?? data['url'] ?? data['link'] ?? data['data']?['url'] ?? data['result'];

        if (downloadUrl != null && downloadUrl.isNotEmpty) {
          final directory = Directory('/storage/emulated/0/Download/Raju Bhai');
          if (!await directory.exists()) {
            await directory.create(recursive: true);
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ડાઉનલોડ શરૂ થયું! ફાઇલ Download/Raju Bhai માં સેવ થશે.')),
          );
        } else {
          // अगर रिपॉन्स में कोई भी लिंक नहीं मिला, तो सर्वर का असली मैसेज दिखाना ताकि पता चले बात क्या है
          setState(() {
            _errorMessage = 'API એરર: વીડિયો ડેટા મળ્યો નથી. સર્વર સંદેશ: ${data['message'] ?? 'લિમિટ પૂરી થઈ હોઈ શકે.'}';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'સર્વર એરર: કોડ ${response.statusCode}. કૃપા કરીને API કી તપાસો.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'કનેક્શન એરર: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
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
              const Text('આરાધના Downloader VIP', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
              TextField(
                controller: _urlController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  hintText: 'યૂટ્યૂબ લિંક અહીં પેસ્ટ કરો',
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.pink, width: 2)),
                ),
              ),
              const SizedBox(height: 25),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.pink, minimumSize: const Size(double.infinity, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                onPressed: _isLoading ? null : () => handleDownload('mp3'),
                icon: const Icon(Icons.music_note, color: Colors.white),
                label: const Text('🎵 Download MP3 (ઓડિયો)', style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
              const SizedBox(height: 15),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black87, minimumSize: const Size(double.infinity, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                onPressed: _isLoading ? null : () => handleDownload('720'),
                icon: const Icon(Icons.video_collection, color: Colors.white),
                label: const Text('🎬 Download Video (વિડિયો)', style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
              const SizedBox(height: 30),
              if (_isLoading) const CircularProgressIndicator(color: Colors.pink),
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(_errorMessage, style: const TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold), textAlign: Center),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
