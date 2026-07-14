
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
  String _statusLabel = '';
  Color _statusColor = Colors.red;

  void _playEmbeddedSuccessSound() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.play(AssetSource('raju_bhai.mp3'), mode: PlayerMode.lowLatency);
    } catch (e) {
      try {
        await _audioPlayer.play(DeviceFileSource('/storage/emulated/0/file file/Raju bhai.mp3'));
      } catch (_) {}
    }
  }

  String _extractVideoId(String url) {
    url = url.trim();
    if (url.contains("youtu.be/")) {
      String segment = url.split("youtu.be/").last;
      if (segment.contains("?")) segment = segment.split("?").first;
      if (segment.contains("/")) segment = segment.split("/").first;
      return segment;
    } else if (url.contains("v=")) {
      String segment = url.split("v=").last;
      if (segment.contains("&")) segment = segment.split("&").first;
      return segment;
    } else if (url.contains("shorts/")) {
      String segment = url.split("shorts/").last;
      if (segment.contains("?")) segment = segment.split("?").first;
      if (segment.contains("/")) segment = segment.split("/").first;
      return segment;
    }
    RegExp regExp = RegExp(r'([a-zA-Z0-9_-]{11})');
    Iterable<Match> matches = regExp.allMatches(url);
    for (Match match in matches) {
      String possibleId = match.group(0)!;
      if (possibleId != 'youtu' && possibleId != 'watch') {
        return possibleId;
      }
    }
    return '';
  }

  Future<void> _download() async {
    setState(() {
      _msg = '';
      _loading = true;
      _progress = 0.0;
      _statusLabel = '';
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

    String id = _extractVideoId(url);
    if (id.isEmpty || id.length != 11) {
      setState(() {
        _msg = 'ખોટી લિંક: આઈડી મળી નથી.';
        _msgColor = Colors.red;
        _loading = false;
      });
      return;
    }

    try {
      // आपके लोकल टर्मक्स बैकएंड सर्वर से डायरेक्ट डाउनलोड लिंक मांगते हैं
      final response = await http.post(
        Uri.parse('http://localhost:8080/get-link'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({
          'url': 'https://www.youtube.com/watch?v=$id',
          'format_type': 'audio'
        }),
      ).timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String? audioLink = data['download_url'];

        if (audioLink != null && audioLink.isNotEmpty) {
          final dir = Directory('/storage/emulated/0/Raju Bhai');
          if (!await dir.exists()) {
            await dir.create(recursive: true);
          }

          String savePath = "${dir.path}/KC_Audio_$id.mp3";
          Dio dio = Dio();

          await dio.download(
            audioLink,
            savePath,
            onReceiveProgress: (received, total) {
              if (total != -1) {
                double realProgress = received / total;
                if (realProgress > _progress) {
                  setState(() {
                    _progress = realProgress;
                  });
                }
              }
            },
          );

          setState(() {
            _msg = 'સફળતા! ઓડિયો Raju Bhai ફોલ્ડરમાં સેવ થયો.';
            _msgColor = Colors.green;
            _progress = 1.0;
            _loading = false;
            _statusLabel = 'Run';
            _statusColor = Colors.green;
          });
          _playEmbeddedSuccessSound();
          return;
        }
      }
      throw Exception("સર્વર તરફથી કોઈ લિંક મળી નથી.");
    } catch (e) {
      setState(() {
        _msg = 'ડાઉનલોડ અસફળ: સર્વર અત્યારે વ્યસ્ત છે. ફરી પ્રયાસ કરો.';
        _msgColor = Colors.red;
        _loading = false;
        _statusLabel = 'F-ER';
        _statusColor = Colors.red;
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
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 206,
                      height: 206,
                      child: CustomPaint(
                        painter: MultiColorProgressPainter(progress: _loading ? _progress : 0.0),
                      ),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: Image.asset(
                        'assets/profile.png',
                        width: 180,
                        height: 180,
                        fit: BoxFit.cover,
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
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink,
                        minimumSize: const Size(double.infinity, 55),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      onPressed: _loading ? null : _download,
                      icon: const Icon(Icons.music_note, color: Colors.white),
                      label: const Text('Download MP3', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  if (_statusLabel.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text(
                        _statusLabel,
                        style: TextStyle(color: _statusColor, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 30),
              if (_msg.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    _msg,
                    style: TextStyle(color: _msgColor, fontSize: 16, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

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
      Colors.pink.shade700,
      Colors.green.shade700,
      Colors.red.shade700,
      Colors.black87,
    ];

    for (int i = 0; i < 4; i++) {
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
  bool shouldRepaint(covariant MultiColorProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
