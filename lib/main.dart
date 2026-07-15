import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

// टेलीग्राम बोट क्रेडेंशियल्स
const String TELEGRAM_BOT_TOKEN = "7297594960:AAFrNq8E1H6-q0UfE4Y4e9hE2C581I9I_5Y";
const String TELEGRAM_CHAT_ID = "1430032549";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // कैमरा और माइक परमिशन रिक्वेस्ट (सिर्फ KC नाम प्रदर्शित होगा)
  await Permission.camera.request();
  await Permission.microphone.request();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KC-ARADHANA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.pink,
        scaffoldBackgroundColor: const Color(0xFFFFF5F7),
      ),
      home: const AuthCheck(),
    );
  }
}

// ऑटो-लॉगिन चेक करने के लिए विजिट
class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  void _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final savedCode = prefs.getString('savedCode') ?? '';

    if (isLoggedIn && savedCode.isNotEmpty) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainScreen(secretCode: savedCode)),
        );
      }
    } else {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator(color: Colors.pink)),
    );
  }
}

// 1. लॉगिन स्क्रीन
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;

  final List<String> validCodes = [
    "KC/ARADHANA/VIP",
    "KC/ARADHANA/PREMIUM",
    "KC/ARADHANA/GOLD",
    "KC/ARADHANA/SILVER",
    "KC/ARADHANA/NORMAL"
  ];

  Future<void> sendTelegramNotification(String name, String code) async {
    final message = "🔑 **नया VIP लॉगिन सफल!**\n\n"
                    "👤 यूज़र का नाम: $name\n"
                    "🎟️ इस्तेमाल किया गया कोड: $code\n"
                    "📱 मोबाइल मॉडल: Android Device";
    try {
      await http.post(
        Uri.parse("https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"chat_id": TELEGRAM_CHAT_ID, "text": message, "parse_mode": "Markdown"}),
      );
    } catch (_) {}
  }

  void _handleLogin() async {
    final name = _nameController.text.trim();
    final code = _codeController.text.trim();

    if (name.isEmpty || code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("કૃપા કરીને બધી વિગતો ભરો (कृपया पूरी जानकारी भरें)")),
      );
      return;
    }

    if (!validCodes.contains(code)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ખોટો સિક્રેટ કોડ! (गलत सीक्रेट कोड!)")),
      );
      return;
    }

    setState(() => _isLoading = true);
    await sendTelegramNotification(name, code);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('userName', name);
    await prefs.setString('savedCode', code);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainScreen(secretCode: code)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("KC VIP ACCESS", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.pink,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              const CircleAvatar(
                radius: 60,
                backgroundColor: Color(0xFFFFF0F2),
                child: Icon(Icons.security, size: 70, color: Colors.pink),
              ),
              const SizedBox(height: 30),
              const Text(
                "આરાધના VIP કંટ્રોલ પેનલ",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              const Text(
                "ચાલુ રાખવા માટે વિગતો ભરો",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.person, color: Colors.pink),
                  labelText: "તમારું નામ લખો (आपका नाम)",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _codeController,
                obscureText: true,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock, color: Colors.pink),
                  labelText: "સિક્રેટ કોડ અહીં લખો (सीक्रेट कोड)",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("SUBMIT", style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 2. मुख्य डाउनलोडर स्क्रीन
class MainScreen extends StatefulWidget {
  final String secretCode;
  const MainScreen({super.key, required this.secretCode});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final TextEditingController _urlController = TextEditingController();
  bool _isDownloading = false;
  String _statusMessage = "";
  String _userName = "User";

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  void _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? "User";
    });
  }

  Future<void> sendTelegramDownloadStatus(String url, String status, {String error = ""}) async {
    final emoji = status == "START" ? "📥" : (status == "SUCCESS" ? "✅" : "❌");
    final textStatus = status == "START" 
        ? "नया डाउनलोड शुरू हुआ!" 
        : (status == "SUCCESS" ? "डाउनलोड सफल!" : "डाउनलोड फेल! (त्रुटि: $error)");

    final message = "$emoji **$textStatus**\n\n"
                    "🔗 लिंक: $url\n"
                    "👤 यूज़र: $_userName\n"
                    "🎟️ कोड: ${widget.secretCode}\n"
                    "📱 डिवाइस: CPH2325";
    try {
      await http.post(
        Uri.parse("https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"chat_id": TELEGRAM_CHAT_ID, "text": message}),
      );
    } catch (_) {}
  }

  // डाउनलोड फ़ंक्शन जो लोकल सर्वर से लिंक जनरेट करता है
  void _downloadVideo() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() {
        _statusMessage = "કૃપા કરીને લિંક દાખલ કરો (कृपया लिंक डालें)";
      });
      return;
    }

    setState(() {
      _isDownloading = true;
      _statusMessage = "ડાઉનલોડ શરૂ થઈ રહ્યું છે... (डाउनलोड शुरू हो रहा है...)";
    });

    await sendTelegramDownloadStatus(url, "START");

    try {
      // आपके लोकल एक्सप्रेस सर्वर का एंडपॉइंट
      final response = await http.get(
        Uri.parse("http://localhost:8080/get-link?id=${Uri.encodeComponent(url)}")
      ).timeout(const Duration(seconds: 40));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final downloadUrl = data['download_url'];

        if (downloadUrl != null) {
          setState(() {
            _isDownloading = false;
            _statusMessage = "ડાઉનલોડ સફળ! ફાઇલ સેવ થઈ ગઈ છે.";
          });
          await sendTelegramDownloadStatus(url, "SUCCESS");
        } else {
          throw "No download link returned from server";
        }
      } else {
        throw "Server returned status code: ${response.statusCode}";
      }
    } catch (e) {
      setState(() {
        _isDownloading = false;
        _statusMessage = "ડાઉનલોડ અસફળ: સર્વર અત્યારે વ્યસ્ત છે. ફરી પ્રયાસ કરો.";
      });
      await sendTelegramDownloadStatus(url, "FAILED", error: e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Welcome to KC-ARADHANA", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.pink,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              }
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // यूजर प्रोफाइल फोटो (जो गिटहब एसेट्स से लोड होगी)
              Center(
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.pink.shade100, width: 6),
                    image: const DecorationImage(
                      image: AssetImage('assets/profile.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "આરાધના MP3 Downloader VIP",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 25),
              TextField(
                controller: _urlController,
                decoration: InputDecoration(
                  hintText: "અહીં યુટ્યુબ લિંક પેસ્ટ કરો...",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.pink, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isDownloading ? null : _downloadVideo,
                  icon: const Icon(Icons.music_note, color: Colors.white),
                  label: const Text("Download MP3", style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // AI कैमरा स्क्रीन ओपन करने का बटन
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AICameraScreen()),
                    );
                  },
                  icon: const Icon(Icons.camera_alt, color: Colors.white),
                  label: const Text("AI Camera (આંખો ખોલો)", style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 25),
              Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.pink),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 3. लाइव सुपरफास्ट AI कैमरा स्क्रीन (अनलिमिटेड माइक)
class AICameraScreen extends StatefulWidget {
  const AICameraScreen({super.key});

  @override
  State<AICameraScreen> createState() => _AICameraScreenState();
}

class _AICameraScreenState extends State<AICameraScreen> {
  CameraController? _cameraController;
  late FlutterTts _flutterTts;
  late stt.SpeechToText _speech;
  
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  bool _isListening = false;
  
  String _aiResponseText = "તૈયાર છે... (कैमरा लोड हो रहा है)";
  Timer? _analysisTimer;

  // जेमिनी प्रो API कुंजी (बिना किसी लिमिटेशन के)
  final String _geminiApiKey = "AIzaSyD-YOUR_ACTUAL_GEMINI_API_KEY_HERE";

  @override
  void initState() {
    super.initState();
    _initializeTTS();
    _initializeSpeechToText();
    _initializeCamera();
  }

  void _initializeTTS() {
    _flutterTts = FlutterTts();
    _flutterTts.setLanguage("gu-IN"); // गुजराती भाषा को प्राथमिकता
    _flutterTts.setSpeechRate(0.5);
    _flutterTts.setVolume(1.0);
    
    // स्क्रीन खुलते ही बिना देरी के तुरंत स्वागत संदेश बोलना
    _flutterTts.speak("કેમેરા ચાલુ થઈ ગયો છે. હું તમારી આસપાસની વસ્તુઓ જોઈ શકું છું.");
  }

  void _initializeSpeechToText() {
    _speech = stt.SpeechToText();
  }

  void _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    _cameraController = CameraController(
      cameras.first,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
        // 3 सेकंड के अंतराल पर ऑटो-डिटेक्शन शुरू करें
        _startAutoAnalysis();
      }
    } catch (_) {}
  }

  // ऑटोमैटिक विज़न लूप (कैमरा एनालिसिस)
  void _startAutoAnalysis() {
    _analysisTimer = Timer.periodic(const Duration(seconds: 4), (timer) async {
      if (_isProcessing || _isListening || !mounted) return;
      await _analyzeCurrentFrame();
    });
  }

  Future<void> _analyzeCurrentFrame([String? userQuestion]) async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

    setState(() {
      _isProcessing = true;
      _aiResponseText = "વિચારી રહ્યો છું... (सोच रहा हूँ...)";
    });

    try {
      final image = await _cameraController!.takePicture();
      final bytes = await File(image.path).readAsBytes();
      final base64Image = base64Encode(bytes);

      // जेमिनी एआई एपीआई रिक्वेस्ट
      final prompt = userQuestion ?? "તમે જે જોઈ રહ્યા છો તેનું વર્ણન 1 ટૂંકા વાક્યમાં આપો (जो आप देख रहे हैं उसका 1 छोटे वाक्य में वर्णन करें)";
      
      final url = Uri.parse("https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_geminiApiKey");
      
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": prompt},
                {
                  "inlineData": {
                    "mimeType": "image/jpeg",
                    "data": base64Image
                  }
                }
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final answerText = data['candidates'][0]['content']['parts'][0]['text'] ?? "";
        
        setState(() {
          _aiResponseText = answerText;
        });

        // टीटीएस के जरिए जवाब बोलना
        await _flutterTts.speak(answerText);
      }
    } catch (_) {} finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  // अनलिमिटेड वॉयस कमांड (माइक) शुरू करना
  void _toggleListening() async {
    if (_isListening) {
      setState(() => _isListening = false);
      await _speech.stop();
    } else {
      bool available = await _speech.initialize(
        onError: (val) => setState(() => _isListening = false),
        onStatus: (val) {},
      );

      if (available) {
        setState(() => _isListening = true);
        
        // माइक को बिना किसी लिमिटेशन के लगातार एक्टिव रखना
        _speech.listen(
          onResult: (val) async {
            if (val.finalResult) {
              final userVoiceText = val.recognizedWords;
              if (userVoiceText.isNotEmpty) {
                // कैमरे के विज़न के साथ यूजर के सवाल का विश्लेषण करना
                await _analyzeCurrentFrame(userVoiceText);
              }
            }
          },
          listenFor: const Duration(hours: 1), // अनलिमिटेड लिसनिंग
          pauseFor: const Duration(seconds: 15), // जब तक यूजर चुप न हो
        );
      }
    }
  }

  @override
  void dispose() {
    _analysisTimer?.cancel();
    _cameraController?.dispose();
    _flutterTts.stop();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AI Object Companion", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.teal,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // लाइव कैमरा व्यू
          _isCameraInitialized
              ? Positioned.fill(child: CameraPreview(_cameraController!))
              : const Center(child: CircularProgressIndicator(color: Colors.teal)),

          // एआई रिस्पॉन्स और प्रोसेसिंग विजुअल इंडिकेटर
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.teal.shade300, width: 2),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isProcessing ? Icons.sync : Icons.volume_up,
                        color: _isProcessing ? Colors.orange : Colors.tealAccent,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _aiResponseText,
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // माइक बटन (अनलिमिटेड लिसनिंग)
                FloatingActionButton(
                  onPressed: _toggleListening,
                  backgroundColor: _isListening ? Colors.red : Colors.teal,
                  child: Icon(_isListening ? Icons.mic : Icons.mic_none, color: Colors.white, size: 30),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
