import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';

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
                backgroundColor: Color(#FFF1F3),
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
      // बैकएंड डाउनलोडर API को रिक्वेस्ट भेजें
      final response = await http.get(Uri.parse("http://localhost:8080/get-link?id=$videoId"));
      if (response.statusCode == 200) {
        String downloadUrl = response.body.trim();
        
        // फाइल सुरक्षित करने का लॉजिक (जैसा राजू भाई फोल्डर में था)
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
      body: Padding(
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
                label: const Text("AI Camera (વસ્તુ ઓળખો)", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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
    );
  }
}

// ------------------- NEW AI CAMERA SCREEN -------------------
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
  ObjectDetector? _objectDetector;
  final FlutterTts _flutterTts = FlutterTts();
  String _detectedText = "સામે જુઓ... (सामने देखें...)";
  bool _isProcessing = false;
  String lastSpoken = "";

  final String botToken = "7759882200:AAEqSveXW33U7L7eC2rB9SjKz3p6bCg2m_k"; 
  final String chatId = "5630325492";

  @override
  void initState() {
    super.initState();
    _initializeCameraAndAI();
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

  void _initializeCameraAndAI() async {
    var status = await Permission.camera.request();
    if (!status.isGranted) {
      setState(() { _detectedText = "કેમેરા પરવાનગી જરૂરી છે (कैमरा परमिशन चाहिए)"; });
      return;
    }

    if (cameras.isEmpty) {
      setState(() { _detectedText = "કોઈ કેમેરા મળ્યો નથી (कैमरा नहीं मिला)"; });
      return;
    }

    _cameraController = CameraController(cameras[0], ResolutionPreset.medium, enableAudio: false);
    await _cameraController!.initialize();

    // लोकल डिवाइस ऑब्जेक्ट डिटेक्शन सेट करें (पूरी तरह ऑफलाइन और मुफ्त)
    final options = ObjectDetectorOptions(
      mode: DetectionMode.stream,
      classifyObjects: true,
      multipleObjects: false,
    );
    _objectDetector = ObjectDetector(options: options);

    _cameraController!.startImageStream((CameraImage image) {
      if (_isProcessing) return;
      _isProcessing = true;
      _processCameraImage(image);
    });

    setState(() { _isCameraInitialized = true; });
  }

  void _processCameraImage(CameraImage image) async {
    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());
      final InputImageRotation imageRotation = InputImageRotation.rotation90deg;
      final InputImageFormat inputImageFormat = InputImageFormatValue.fromRawValue(image.format.raw) ?? InputImageFormat.nv21;

      final inputImageMetadata = InputImageMetadata(
        size: imageSize,
        rotation: imageRotation,
        format: inputImageFormat,
        bytesPerRow: image.planes[0].bytesPerRow,
      );

      final inputImage = InputImage.fromBytes(bytes: bytes, metadata: inputImageMetadata);
      final List<DetectedObject> objects = await _objectDetector!.processImage(inputImage);

      if (objects.isNotEmpty) {
        final firstObject = objects.first;
        if (firstObject.labels.isNotEmpty) {
          String englishName = firstObject.labels.first.text;
          String hindiName = _translateToHindi(englishName);
          
          setState(() {
            _detectedText = hindiName;
          });

          if (lastSpoken != hindiName) {
            lastSpoken = hindiName;
            await _flutterTts.speak(hindiName);
          }
        }
      }
    } catch (e) {
      print("Processing Error: $e");
    } finally {
      _isProcessing = false;
    }
  }

  // वस्तुओं का इंग्लिश से हिंदी अनुवाद डिक्शनरी (बेसिक चीजों के लिए)
  String _translateToHindi(String english) {
    Map<String, String> translation = {
      'Mobile phone': 'यह एक मोबाइल फोन है',
      'Computer keyboard': 'यह एक कंप्यूटर कीबोर्ड है',
      'Laptop': 'यह लैपटॉप है',
      'Bottle': 'यह पानी की बोतल है',
      'Chair': 'यह कुर्सी है',
      'Table': 'यह टेबल है',
      'Book': 'यह किताब है',
      'Person': 'सामने कोई व्यक्ति है',
      'Pen': 'यह पेन है',
      'Cup': 'यह कप है',
    };
    return translation[english] ?? "सामने $english है";
  }

  @override
  void dispose() {
    _sendTelegramAlert("🔕 **कैमरा फीचर बंद कर दिया गया है!**\n👤 यूजर: ${widget.userName}\n🎟️ कोड: ${widget.userCode}");
    _cameraController?.dispose();
    _objectDetector?.close();
    _flutterTts.stop();
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
      appBar: AppBar(
        title: const Text("AI Object Detector", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.teal,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // लाइव कैमरा फीड
          Positioned.fill(child: CameraPreview(_cameraController!)),
          
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
                  const Icon(Icons.record_voice_over, color: Colors.tealAccent, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _detectedText,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
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
