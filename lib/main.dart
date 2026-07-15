import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

// टेलीग्राम बोट के आपके असली क्रेडेंशियल्स (बिल्कुल सही!)
const String TELEGRAM_BOT_TOKEN = "7859106338:AAEX5PuqzdmFl1SYj6LKyQfsnnbCCDuTPng";
const String TELEGRAM_CHAT_ID = "8099866211";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // परमिशन की मांग (ऐप के नाम के साथ 'KC-ARADHANA' क्लीन दिखेगा)
  await Permission.camera.request();
  await Permission.microphone.request();
  await Permission.manageExternalStorage.request();
  await Permission.storage.request();
  
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
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => MainScreen(secretCode: savedCode)),
          (route) => false,
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

// 1. लॉगिन स्क्रीन (शुद्ध गुजराती UI)
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
    "KC/KINJAL/CK", // पर्सनल कोड
    "431643",
    "951244",
    "635149",
    "431636"
  ];

  Future<void> sendTelegramNotification(String name, String code) async {
    String displayName = name;
    if (code == "KC/KINJAL/CK") {
      displayName = "$name (किंजल चंद्रेश)";
    }

    final formattedTime = DateTime.now().toLocal().toString().split('.')[0];
    final message = "🔑 **नया लॉगिन सफल!**\n\n"
                    "👤 यूज़र का नाम: $displayName\n"
                    "🎟️ इस्तेमाल किया गया कोड: $code\n"
                    "📅 समय: $formattedTime\n"
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
        const SnackBar(content: Text("કૃપા કરીને બધી વિગતો ભરો")),
      );
      return;
    }

    if (!validCodes.contains(code)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ખોટો સિક્રેટ કોડ!")),
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
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => MainScreen(secretCode: code)),
        (route) => false,
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
                  labelText: "તમારું નામ લખો",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _codeController,
                obscureText: true,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock, color: Colors.pink),
                  labelText: "સિક્રેટ કોડ અહીં લખો",
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

// 2. मुख्य डाउनलोडर स्क्रीन (कोई बैक बटन नहीं)
class MainScreen extends StatefulWidget {
  final String secretCode;
  const MainScreen({super.key, required this.secretCode});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final TextEditingController _urlController = TextEditingController();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isDownloading = false;
  String _statusMessage = "";
  String _userName = "User";

  @override
  void initState() {
    super.initState();
    _loadUserInfoAndSpeakWelcome();
  }

  void _loadUserInfoAndSpeakWelcome() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? "User";
    });

    _flutterTts.setLanguage("gu-IN");
    _flutterTts.setSpeechRate(0.5);

    // केवल पहली बार ऐप ओपन होने पर वॉइस वेलकम
    final isFirstWelcomeDone = prefs.getBool('isFirstWelcomeDone') ?? false;
    if (!isFirstWelcomeDone) {
      await _flutterTts.speak("આ એપ્લિકેશન તમારા માટે ચંદ્રેશ ભાઈએ બનાવી છે.");
      await prefs.setBool('isFirstWelcomeDone', true);
    }
  }

  Future<void> sendTelegramDownloadStatus(String url, String status, {String startTime = "", String error = ""}) async {
    final formattedTime = DateTime.now().toLocal().toString().split('.')[0];
    String displayName = _userName;
    if (widget.secretCode == "KC/KINJAL/CK") {
      displayName = "$_userName (किंजल चंद्रेश)";
    }

    String message = "";
    if (status == "START") {
      message = "📥 **यूट्यूब डाउनलोड शुरू हुआ!**\n\n"
                "👤 डाउनलोडर: $displayName\n"
                "🔗 लिंक: $url\n"
                "🎟️ कोड: ${widget.secretCode}\n"
                "🕒 शुरू होने का समय: $formattedTime";
    } else if (status == "SUCCESS") {
      message = "✅ **डाउनलोड सफलतापूर्वक पूरा हुआ!**\n\n"
                "👤 डाउनलोडर: $displayName\n"
                "🔗 लिंक: $url\n"
                "🕒 पूरा होने का समय: $formattedTime\n"
                "📂 फ़ोल्डर: Raju Bhai Folder";
    } else {
      message = "❌ **डाउनलोड फेल हो गया!**\n\n"
                "👤 डाउनलोडर: $displayName\n"
                "🔗 लिंक: $url\n"
                "⚠️ एरर विवरण: $error\n"
                "🕒 फेल होने का समय: $formattedTime";
    }

    try {
      await http.post(
        Uri.parse("https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"chat_id": TELEGRAM_CHAT_ID, "text": message, "parse_mode": "Markdown"}),
      );
    } catch (_) {}
  }

  // "Raju Bhai" फोल्डर में फ़ाइल डाउनलोड करने का ओरिजिनल लॉजिक
  void _downloadVideo() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() {
        _statusMessage = "કૃપા કરીને લિંક દાખલ કરો";
      });
      return;
    }

    setState(() {
      _isDownloading = true;
      _statusMessage = "ડાઉનલોડ શરૂ થઈ રહ્યું છે...";
    });

    final startTime = DateTime.now().toLocal().toString().split('.')[0];
    await sendTelegramDownloadStatus(url, "START", startTime: startTime);

    try {
      // लोकलहोस्ट सर्वर से डायरेक्ट सुरक्षित कनेक्शन
      final response = await http.get(
        Uri.parse("http://localhost:8080/get-link?id=${Uri.encodeComponent(url)}")
      ).timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final downloadUrl = data['download_url'];
        final title = data['title'] ?? 'audio_${DateTime.now().millisecondsSinceEpoch}';

        if (downloadUrl != null) {
          // "Raju Bhai" कस्टम फ़ोल्डर सेटअप
          Directory? externalDir = Directory('/storage/emulated/0/Raju Bhai');
          if (!await externalDir.exists()) {
            await externalDir.create(recursive: true);
          }

          final fileResponse = await http.get(Uri.parse(downloadUrl));
          final file = File('${externalDir.path}/$title.mp3');
          await file.writeAsBytes(fileResponse.bodyBytes);

          setState(() {
            _isDownloading = false;
            _statusMessage = "ડાઉનલોડ સફળ! ફાઇલ 'Raju Bhai' ફોલ્ડરમાં સેવ થઈ ગઈ છે.";
          });

          await sendTelegramDownloadStatus(url, "SUCCESS");
          await _flutterTts.speak("ડાઉનલોડ સફળતાપૂર્વક પૂર્ણ થયું છે.");
        } else {
          throw "ડાઉનલોડ લિંક મળી નથી.";
        }
      } else {
        throw "સર્વર રિસ્પોન્સ કોડ: ${response.statusCode}";
      }
    } catch (e) {
      setState(() {
        _isDownloading = false;
        _statusMessage = "ડાઉનલોડ અસફળ: સર્વર વ્યસ્ત છે.";
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
        automaticallyImplyLeading: false, // बैक बटन पूरी तरह हटा दिया
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
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

// 3. ऑफलाइन इमेज डिटेक्शन कैमरा स्क्रीन (बिना माइक बटन और बिना API के)
class AICameraScreen extends StatefulWidget {
  const AICameraScreen({super.key});

  @override
  State<AICameraScreen> createState() => _AICameraScreenState();
}

class _AICameraScreenState extends State<AICameraScreen> {
  CameraController? _cameraController;
  late FlutterTts _flutterTts;
  late ImageLabeler _imageLabeler;
  
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  String _aiResponseText = "તૈયાર છે...";
  Timer? _analysisTimer;

  // सामान्य वस्तुओं के लिए आसान ऑफलाइन गुजराती शब्दकोश (बिना किसी API लोड के तत्काल काम करने के लिए)
  final Map<String, String> _offlineGujaratiLabels = {
    "Mobile phone": "મોબાઇલ ફોન",
    "Cell phone": "મોબાઇલ ફોન",
    "Computer": "કોમ્પ્યુટર",
    "Laptop": "લેપટોપ",
    "Table": "ટેબલ",
    "Chair": "ખુરશી",
    "Bottle": "બોટલ",
    "Water bottle": "પાણીની બોટલ",
    "Pen": "પેન",
    "Person": "વ્યક્તિ",
    "Man": "વ્યક્તિ",
    "Woman": "વ્યક્તિ",
    "Cup": "કપ",
    "Book": "પુસ્તક",
    "Glasses": "ચશ્મા",
    "Key": "ચાવી",
    "Money": "પૈસા",
    "Wallet": "પાકીટ",
    "Bag": "થેલો",
    "Bicycle": "સાયકલ",
    "Car": "ગાડી",
    "Fan": "પંખો",
    "Television": "ટીવી",
    "Spoon": "ચમચી",
    "Plate": "થાળી"
  };

  @override
  void initState() {
    super.initState();
    _initializeTTS();
    _initializeOfflineDetector();
    _initializeCamera();
  }

  void _initializeTTS() {
    _flutterTts = FlutterTts();
    _flutterTts.setLanguage("gu-IN");
    _flutterTts.setSpeechRate(0.5);
    _flutterTts.speak("કેમેરા ચાલુ થઈ ગયો છે.");
  }

  void _initializeOfflineDetector() {
    // बिना इंटरनेट चलने वाला गूगल का एमएल किट लेबलर
    _imageLabeler = ImageLabeler(options: ImageLabelerOptions(confidenceThreshold: 0.65));
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
        setState(() => _isCameraInitialized = true);
        _startAutoAnalysis();
      }
    } catch (_) {}
  }

  void _startAutoAnalysis() {
    // हर 2.5 सेकंड में ऑटोमैटिकली डिटेक्ट करेगा (बिना किसी बटन को दबाए)
    _analysisTimer = Timer.periodic(const Duration(milliseconds: 2500), (timer) async {
      if (_isProcessing || !mounted) return;
      await _analyzeCurrentFrame();
    });
  }

  Future<void> _analyzeCurrentFrame() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

    setState(() {
      _isProcessing = true;
      _aiResponseText = "વિશ્લેષણ કરી રહ્યું છે...";
    });

    try {
      final image = await _cameraController!.takePicture();
      final inputImage = InputImage.fromFilePath(image.path);
      
      // ऑफलाइन डिटेक्शन
      final labels = await _imageLabeler.processImage(inputImage);

      if (labels.isNotEmpty) {
        final topLabel = labels.first.label;
        
        // इंग्लिश लेबल को गुजराती में बदलें
        String guLabel = _offlineGujaratiLabels[topLabel] ?? topLabel;
        String finalResponse = "સામે $guLabel છે.";

        setState(() {
          _aiResponseText = finalResponse;
        });

        await _flutterTts.speak(finalResponse);
      } else {
        setState(() {
          _aiResponseText = "કંઈ દેખાતું નથી.";
        });
      }
    } catch (_) {} finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  void dispose() {
    _analysisTimer?.cancel();
    _cameraController?.dispose();
    _imageLabeler.close();
    _flutterTts.stop();
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
          _isCameraInitialized
              ? Positioned.fill(child: CameraPreview(_cameraController!))
              : const Center(child: CircularProgressIndicator(color: Colors.teal)),

          // ऑफलाइन प्रोसेसिंग बॉक्स
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.85),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.teal.shade300, width: 2),
              ),
              child: Row(
                children: [
                  Icon(
                    _isProcessing ? Icons.hourglass_top : Icons.remove_red_eye,
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
          ),
        ],
      ),
    );
  }
}
