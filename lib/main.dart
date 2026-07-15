import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:google_generative_ai/google_generative_ai.dart';

List<CameraDescription> cameras = [];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    cameras = await availableCameras();
  } catch (e) {
    print("Camera error: $e");
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KC ARADHANA',
      theme: ThemeData(
        primarySwatch: Colors.pink,
      ),
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// ------------------- LOGIN SCREEN -------------------
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;

  final String botToken = "7759882200:AAEqSveXW33U7L7eC2rB9SjKz3p6bCg2m_k"; 
  final String chatId = "5630325492";

  Future<void> sendTelegramMessage(String message) async {
    final url = Uri.parse("https://api.telegram.org/bot$botToken/sendMessage");
    try {
      await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"chat_id": chatId, "text": message}),
      );
    } catch (e) {
      print("Telegram Error: $e");
    }
  }

  Future<String> getDeviceModel() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      return androidInfo.model;
    }
    return "Unknown Device";
  }

  void _handleLogin() async {
    String name = _nameController.text.trim();
    String code = _codeController.text.trim();

    if (name.isEmpty || code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("કૃપા કરીને બધી વિગતો ભરો (कृपया पूरी जानकारी भरें)")),
      );
      return;
    }

    setState(() { _isLoading = true; });

    if (code == "KC\\KINJAL/\\CK" || code == "635149") {
      String customName = (code == "KC\\KINJAL/\\CK") ? "KINJAL CHANDRESH" : name;
      
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', customName);
      await prefs.setString('user_code', code);

      String deviceModel = await getDeviceModel();

      String telegramMsg = "🔑 **नया VIP लॉगिन सफल!** 🔑\n\n"
          "👤 यूजर का नाम: $customName\n"
          "🎟️ इस्तेमाल किया गया कोड: $code\n"
          "📱 मोबाइल मॉडल: $deviceModel";

      await sendTelegramMessage(telegramMsg);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DownloadScreen()),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ખોટો સિક્રેટ કોડ! (गलत सीक्रेट कोड!)")),
      );
    }

    setState(() { _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("KC VIP ACCESS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.pink,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 50),
              const CircleAvatar(
                radius: 60,
                backgroundColor: Color(0xFFFFF1F3),
                child: Icon(Icons.security, size: 70, color: Colors.pink),
              ),
              const SizedBox(height: 30),
              const Text(
                "આરાધના VIP કંટ્રોલ પેનલ",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              const Text(
                "ચાલુ રાખવા માટે વિગતો ભરો",
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 40),
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
                  labelText: "સિક્રેટ કોડ અહીં લખો (સીક્રેટ કોડ)",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 40),
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

// ------------------- DOWNLOAD SCREEN -------------------
class DownloadScreen extends StatefulWidget {
  const DownloadScreen({super.key});

  @override
  State<DownloadScreen> createState() => _DownloadScreenState();
}

class _DownloadScreenState extends State<DownloadScreen> {
  final TextEditingController _urlController = TextEditingController();
  bool _isDownloading = false;
  String _statusMessage = "";
  String userName = "";
  String userCode = "";

  final String botToken = "7759882200:AAEqSveXW33U7L7eC2rB9SjKz3p6bCg2m_k"; 
  final String chatId = "5630325492";

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  void _loadUserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('user_name') ?? "Guest";
      userCode = prefs.getString('user_code') ?? "Unknown";
    });
  }

  Future<void> sendTelegramMessage(String message) async {
    final url = Uri.parse("https://api.telegram.org/bot$botToken/sendMessage");
    try {
      await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"chat_id": chatId, "text": message}),
      );
    } catch (e) {
      print("Telegram Error: $e");
    }
  }

  Future<void> _startDownload() async {
    String videoUrl = _urlController.text.trim();
    if (videoUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("કૃપા કરીને લિંક દાખલ કરો (कृपया लिंक डालें)")),
      );
      return;
    }

    setState(() {
      _isDownloading = true;
      _statusMessage = "ડાઉનલોડ શરૂ થઈ રહ્યું છે... (डाउनलोड शुरू हो रहा है...)";
    });

    String videoId = "";
    if (videoUrl.contains("youtu.be/")) {
      videoId = videoUrl.split("youtu.be/")[1].split("?")[0];
    } else if (videoUrl.contains("v=")) {
      videoId = videoUrl.split("v=")[1].split("&")[0];
    } else {
      videoId = videoUrl;
    }

    String startMsg = "📥 **नया डाउनलोड शुरू हुआ!** 📥\n\n"
        "🔗 यूट्यूब आईडी: $videoId\n"
        "🌐 लिंक: https://youtu.be/$videoId\n"
        "👤 यूजर: $userName\n"
        "🎟️ कोड: $userCode\n"
        "📱 डिवाइस: OPPO CPH2325";
    await sendTelegramMessage(startMsg);

    try {
      final response = await http.get(Uri.parse("http://localhost:8080/get-link?id=$videoId"));
      if (response.statusCode == 200) {
        String downloadUrl = response.body.trim();
        
        var status = await Permission.storage.request();
        if (status.isGranted) {
          final directory = Directory('/storage/emulated/0/Raju Bhai');
          if (!await directory.exists()) {
            await directory.create(recursive: true);
          }
          
          final filePath = "${directory.path}/KC_Audio_$videoId.mp3";
          final fileResponse = await http.get(Uri.parse(downloadUrl));
          final file = File(filePath);
          await file.writeAsBytes(fileResponse.bodyBytes);

          setState(() {
            _statusMessage = "ડાઉનલોડ સફળ! ફાઇલ 'Raju Bhai' માં સાચવેલ છે.";
          });

          String successMsg = "✅ **डाउनलोड सफल!** ✅\n"
              "📁 फाइल सुरक्षित रूप से 'Raju Bhai' फोल्डर में सहेज ली गई है।\n"
              "👤 यूजर: $userName\n"
              "🎟️ कोड: $userCode\n"
              "📱 डिवाइस: OPPO CPH2325";
          await sendTelegramMessage(successMsg);
        } else {
          setState(() {
            _statusMessage = "સ્ટોરેજ પરવાનગી નકારી કાઢી (स्टोरेज परमिशन नहीं मिली)";
          });
        }
      } else {
        setState(() {
          _statusMessage = "ભૂલ: ડાઉનલોડ લિંક મળી નથી (एरर: लिंक नहीं मिला)";
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = "કનેક્શન ભૂલ (कनेक्शन एरर): $e";
      });
    }

    setState(() { _isDownloading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Welcome to KC-ARADHANA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.pink,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              CircleAvatar(
                radius: 90,
                backgroundImage: const AssetImage('assets/profile.png'),
                backgroundColor: Colors.grey[200],
              ),
              const SizedBox(height: 20),
              const Text(
                "આરાધના MP3 Downloader VIP",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _urlController,
                decoration: InputDecoration(
                  hintText: "યૂટ્યૂબ લિંક અહીં પેસ્ટ કરો",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isDownloading ? null : _startDownload,
                  icon: const Icon(Icons.music_note, color: Colors.white),
                  label: const Text("Download MP3", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // ---- नया AI कैमरा बटन ----
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CameraScreen(userName: userName, userCode: userCode)),
                    );
                  },
                  icon: const Icon(Icons.camera_alt, color: Colors.white),
                  label: const Text("AI Camera (આંખો ખોલો)", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(_statusMessage, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal)),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------- 🌟 NEW ADVANCED AI CAMERA SCREEN -------------------
class CameraScreen extends StatefulWidget {
  final String userName;
  final String userCode;
  const CameraScreen({super.key, required this.userName, required this.userCode});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  final FlutterTts _flutterTts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();
  
  bool _isListening = false;
  bool _isAnalyzing = false;
  bool _isAutoMode = true; // डिफ़ॉल्ट रूप से ऑटो मोड चालू रहेगा
  String _displayText = "सामने देखें या पूछने के लिए माइक दबाएं...";
  String _spokenQuestion = "";
  
  // चंद्रेश भाई की जेमिनी एपीआई की (Gemini API Key)
  final String apiKey = "AIzaSyD-your-actual-api-key-here"; // [नोट: यहाँ अपनी जेमिनी एपीआई की डालें]
  late final GenerativeModel _model;

  final String botToken = "7759882200:AAEqSveXW33U7L7eC2rB9SjKz3p6bCg2m_k"; 
  final String chatId = "5630325492";

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
    _initializeCameraAndServices();
    _sendTelegramAlert("🔔 **कैमरा फीचर चालू किया गया!**\n👤 यूजर: ${widget.userName}\n🎟️ कोड: ${widget.userCode}");
  }

  Future<void> _sendTelegramAlert(String message) async {
    final url = Uri.parse("https://api.telegram.org/bot$botToken/sendMessage");
    try {
      await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"chat_id": chatId, "text": message}),
      );
    } catch (e) {
      print("Telegram Log Error: $e");
    }
  }

  void _initializeCameraAndServices() async {
    // अनुमतियाँ (Permissions) प्राप्त करें
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.microphone,
    ].request();

    if (statuses[Permission.camera] != PermissionStatus.granted) {
      setState(() { _displayText = "कैमरा परमिशन आवश्यक है!"; });
      return;
    }

    if (cameras.isEmpty) {
      setState(() { _displayText = "कोई कैमरा नहीं मिला!"; });
      return;
    }

    // कैमरा शुरू करें
    _cameraController = CameraController(cameras[0], ResolutionPreset.medium, enableAudio: false);
    await _cameraController!.initialize();

    // टीटीएस (TTS) गुजराती सेटिंग
    await _flutterTts.setLanguage("gu-IN");
    await _flutterTts.setSpeechRate(0.5); // बोलने की गति

    setState(() { _isCameraInitialized = true; });

    // स्वागत भाषण और ऑटो डिटेक्शन शुरू
    _speakWelcomeAndStartLoop();
  }

  // पहला स्पेशल वेलकम मैसेज (एक बार के लिए)
  void _speakWelcomeAndStartLoop() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isFirstTime = prefs.getBool('camera_first_time') ?? true;

    if (isFirstTime) {
      String welcomeMsg = "મને ચંદ્રેશભાઈએ ખાસ તમારા માટે બનાવ્યો છે. હું તમારી આસપાસની દુનિયાને જોવામાં મદદ કરીશ.";
      setState(() {
        _displayText = "मुझे चंद्रेश भाई ने आपके लिए बनाया है। मैं आपकी मदद करूँगा।";
      });
      await _flutterTts.speak(welcomeMsg);
      await prefs.setBool('camera_first_time', false);
      // स्वागत संदेश बोलने के बाद थोड़ा रुककर ऑटो डिटेक्शन शुरू करें
      await Future.delayed(const Duration(seconds: 5));
    }
    
    _startAutoAnalysisLoop();
  }

  // ऑटो डिटेक्शन लूप (हर 5 सेकंड में फोटो विश्लेषण)
  void _startAutoAnalysisLoop() async {
    while (mounted && _isAutoMode) {
      if (!_isAnalyzing && !_isListening) {
        await _captureAndAnalyzeImage();
      }
      await Future.delayed(const Duration(seconds: 6));
    }
  }

  // फोटो खींचना और जेमिनी एआई को विश्लेषण के लिए भेजना
  Future<void> _captureAndAnalyzeImage({String? customPrompt}) async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

    setState(() { _isAnalyzing = true; });

    try {
      XFile file = await _cameraController!.takePicture();
      final bytes = await file.readAsBytes();

      // जेमिनी प्रॉम्प्ट: चंद्रेश भाई की पसंद के अनुसार डिटेल्स मांगना
      String prompt = customPrompt ?? 
          "You are a helpful visual assistant for a visually impaired user. "
          "Look at this image and describe it in 1 or 2 natural sentences. "
          "Mention key objects, their colors, location, and details like weather if sky is visible or gender/clothes of a person if visible. "
          "Reply ONLY in Gujarati language. Do not use English text in output.";

      final content = [
        Content.multi([
          DataPart('image/jpeg', bytes),
          TextPart(prompt),
        ])
      ];

      final response = await _model.generateContent(content);
      String gujaratiReply = response.text ?? "હું આ જોઈ શકતો નથી.";

      // स्क्रीन पर हिंदी अनुवाद के लिए जेमिनी से ही अनुवाद करवाएं
      final translationResponse = await _model.generateContent([
        Content.text("Translate this Gujarati text to Simple Hindi: '$gujaratiReply'. Return ONLY the translated Hindi text.")
      ]);
      String hindiText = translationResponse.text ?? "सामने कोई वस्तु है।";

      setState(() {
        _displayText = hindiText;
      });

      // गुजराती में बोलकर सुनाएँ
      await _flutterTts.speak(gujaratiReply);

    } catch (e) {
      print("AI Analysis Error: $e");
    } finally {
      if (mounted) {
        setState(() { _isAnalyzing = false; });
      }
    }
  }

  // वॉयस कमांड सुनना (माइक मोड)
  void _toggleListening() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => print('Speech Status: $val'),
        onError: (val) => print('Speech Error: $val'),
      );

      if (available) {
        setState(() {
          _isListening = true;
          _isAutoMode = false; // माइक ऑन करते ही ऑटो मोड थोड़ी देर के लिए रुकेगा
          _displayText = "सुन रहा हूँ... बोलिए भाई";
        });

        _speech.listen(
          onResult: (val) async {
            setState(() {
              _spokenQuestion = val.recognizedWords;
            });
            
            if (val.finalResult) {
              setState(() {
                _isListening = false;
                _displayText = "सोच रहा हूँ: '${val.recognizedWords}'";
              });
              
              // अगर यूजर ने निर्माता के बारे में पूछा
              String query = val.recognizedWords.toLowerCase();
              if (query.contains("बनाया") || query.contains("બનાવ્યો") || query.contains("maker") || query.contains("owner") || query.contains("मालिक") || query.contains("માલિક")) {
                String creatorMsg = "મને મારા માલિક ચંદ્રેશભાઈએ બનાવ્યો છે!";
                setState(() { _displayText = "मुझे मेरे मालिक चंद्रेश भाई ने बनाया है!"; });
                await _flutterTts.speak(creatorMsg);
              } else {
                // जेमिनी को यूजर के प्रश्न के साथ फोटो भेजें
                String customPrompt = "Answer the user's question: '$query' based on this image. Answer in 1 or 2 sweet sentences in Gujarati language only.";
                await _captureAndAnalyzeImage(customPrompt: customPrompt);
              }

              // सवाल का जवाब देने के बाद वापस ऑटो मोड में लौटें
              setState(() { _isAutoMode = true; });
              _startAutoAnalysisLoop();
            }
          },
        );
      }
    } else {
      setState(() {
        _isListening = false;
        _isAutoMode = true;
      });
      _speech.stop();
      _startAutoAnalysisLoop();
    }
  }

  @override
  void dispose() {
    _sendTelegramAlert("🔕 **कैमरा फीचर बंद कर दिया गया है!**\n👤 यूजर: ${widget.userName}\n🎟️ कोड: ${widget.userCode}");
    _cameraController?.dispose();
    _flutterTts.stop();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.pink)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("AI Object Companion", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.teal,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // लाइव कैमरा फीड
          Positioned.fill(
            child: CameraPreview(_cameraController!),
          ),

          // माइक बटन (राइट साइड में गोल और सुंदर फ्लोटिंग बटन)
          Positioned(
            right: 20,
            bottom: 110,
            child: FloatingActionButton(
              onPressed: _toggleListening,
              backgroundColor: _isListening ? Colors.red : Colors.tealAccent,
              child: Icon(
                _isListening ? Icons.mic : Icons.mic_none,
                color: Colors.black,
                size: 30,
              ),
            ),
          ),

          // सबसे नीचे सुंदर स्लिम पट्टी (प्राइवेसी फ्रेंडली और कॉम्पेक्ट)
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.85),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.teal, width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isAnalyzing ? Icons.hourglass_empty : Icons.record_voice_over,
                    color: Colors.tealAccent,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _displayText,
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
