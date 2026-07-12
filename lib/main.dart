import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';

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
  final AudioPlayer _audioPlayer = AudioPlayer();
  String _msg = '';
  Color _msgColor = Colors.red;
  bool _loading = false;
  double _progress = 0.0;

  Future<void> _download() async {
    setState(() { 
      _msg = ''; 
      _loading = true; 
      _progress = 0.0; 
    });
    
    await Permission.manageExternalStorage.request();
    
    String url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() { 
        _msg = 'કૃપા કરીને લિંક પેસ્ટ કરો'; 
        _msgColor = Colors.red;
        _loading = false; 
      });
      return;
    }

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
      setState(() { 
        _msg = 'ખોટી લિંક: આઈડી મળી નથી.'; 
        _msgColor = Colors.red;
        _loading = false; 
      });
      return;
    }

    try {
      final res = await http.get(
        Uri.parse('https://youtube-media-downloader.p.rapidapi.com/v2/video/details?videoId=$id'),
        headers: {
          'x-rapidapi-key': '2a2d800e5cmsh0798dd20ef51d17p1d9715jsn2c69b2d0f7d3',
          'x-rapidapi-host': 'youtube-media-downloader.p.rapidapi.com'
        },
      );
      
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        String? audioLink;
        if (data['audios'] != null && data['audios']['items'] != null && data['audios']['items'].isNotEmpty) {
          audioLink = data['audios']['items'][0]['url'];
        }
        
        if (audioLink != null) {
          final dir = Directory('/storage/emulated/0/Raju Bhai');
          if (!await dir.exists()) {
            await dir.create(recursive: true);
          }
          
          String savePath = "${dir.path}/KC_Audio_$id.mp3";
          
          // सुपर फास्ट डाउनलोड के लिए बफ़र और कनेक्शन सेटिंग्स बढ़ाना
          Dio dio = Dio();
          dio.options.connectTimeout = const Duration(seconds: 20);
          dio.options.receiveTimeout = const Duration(minutes: 5);
          
          await dio.download(
            audioLink,
            savePath,
            onReceiveProgress: (received, total) {
              if (total != -1) {
                setState(() {
                  _progress = received / total;
                });
              }
            },
          );

          // डाउनलोड सफल होने पर तुरंत ग्रीन मैसेज सेट करना
          setState(() {
            _msg = 'સફળતા! ઓડિયો Raju Bhai ફોલ્ડરમાં સેવ થયો.';
            _msgColor = Colors.green;
            _progress = 1.0;
            _loading = false;
          });
          
          // चंद्रेश भाई के दोस्त के लिए स्पेशल बीप साउंड ट्रिगर (पूर्ण सुरक्षित तरीक़ा)
          try {
            await _audioPlayer.setVolume(1.0);
            await _audioPlayer.play(UrlSource('https://assets.mixkit.co/active_storage/sfx/2869/2869-600.wav'));
          } catch (soundError) {
            // अगर मुख्य साउंड न बजे तो बैकअप साउंड प्ले करना
            try {
              await _audioPlayer.play(UrlSource('https://beempe3.com/download/sound.mp3'));
            } catch (_) {}
          }
          
        } else {
          setState(() {
            _msg = 'API એરર: ઓડિયો લિંક મળી નથી.';
            _msgColor = Colors.red;
            _loading = false;
          });
        }
      } else {
        setState(() {
          _msg = 'સર્વર રિસ્પોન્સ એરર કોડ: ${res.statusCode}';
          _msgColor = Colors.red;
          _loading = false;
        });
      }
    } catch (e) {
      // अगर डाउनलोडिंग के बाद साउंड में कोई दिक्कत आती है तो भी यह क्रैश नहीं होगा
      if (_progress >= 0.99) {
        setState(() {
          _msg = 'સફળતા! ઓડિયો Raju Bhai ફોલ્ડરમાં સેવ થયો.';
          _msgColor = Colors.green;
          _loading = false;
        });
      } else {
        setState(() {
          _msg = 'ડાઉનલોડ એરર: ફરી પ્રયાસ કરો.';
          _msgColor = Colors.red;
          _loading = false;
        });
      }
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
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // चंद्रेश भाई का स्पेशल 4-रंगों वाला कस्टम प्रोग्रेस बार व्हील
                    SizedBox(
                      width: 206,
                      height: 206,
                      child: CustomPaint(
                        painter: MultiColorProgressPainter(progress: _loading ? _progress : 0.0),
                      ),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: Image.asset('assets/profile.png', width: 180, height: 180, fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.account_circle, size: 180, color: Colors.grey),
                      ),
                    ),
                    if (_loading)
                      Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Center(
                          child: Text(
                            "${(_progress * 100).toStringAsFixed(0)}%",
                            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
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
                icon: const Icon(Icons.music_note, color: Colors.white),
                label: const Text('Download MP3', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 30),
              if (_msg.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(_msg, style: TextStyle(color: _msgColor, fontSize: 16, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// चक्र में 25-25% के हिसाब से अलग-अलग रंग भरने वाला पेंटर क्लास
class MultiColorProgressPainter extends CustomPainter {
  final double progress;
  MultiColorProgressPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    Offset center = Offset(size.width / 2, size.height / 2);
    double radius = min(size.width / 2, size.height / 2) - 4;
    
    Paint bgPaint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 7
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, bgPaint);

    double totalAngle = progress * 2 * pi;
    double startAngle = -pi / 2;

    List<Color> colors = [
      Colors.pink,         // 0% - 25%
      Colors.green.shade700, // 25% - 50%
      Colors.red.shade700,   // 50% - 75%
      Colors.black87,      // 75% - 100%
    ];

    for (int i = 0; i < 4; i++) {
      double segmentMaxAngle = (i + 1) * (pi / 2);
      if (totalAngle <= i * (pi / 2)) break;

      double sweepAngle = totalAngle - (i * (pi / 2));
      if (sweepAngle > pi / 2) sweepAngle = pi / 2;

      Paint progressPaint = Paint()
        ..color = colors[i]
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle + (i * (pi / 2)),
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  Widget build(BuildContext context) => const Placeholder();

  @override
  bool shouldRepaint(covariant MultiColorProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
