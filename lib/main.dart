import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

// यहाँ अपनी गूगल एआई स्टूडियो वाली चाबी पेस्ट करें
const String GEMINI_API_KEY = "यहाँ_अपनी_चाबी_डालें";

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
      theme: ThemeData(primarySwatch: Colors.teal),
      home: const MainCameraScreen(),
    );
  }
}

class MainCameraScreen extends StatefulWidget {
  const MainCameraScreen({super.key});

  @override
  State<MainCameraScreen> createState() => _MainCameraScreenState();
}

class _MainCameraScreenState extends State<MainCameraScreen> {
  CameraController? _cameraController;
  late FlutterTts _flutterTts;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  String _aiResponseText = "લાઈવ કેમેરા શરૂ થઈ રહ્યો છે...";
  Timer? _analysisTimer;

  @override
  void initState() {
    super.initState();
    _initializeTTS();
    _checkPermissionsAndInit();
  }

  void _initializeTTS() {
    _flutterTts = FlutterTts();
    _flutterTts.setLanguage("gu-IN");
    _flutterTts.setSpeechRate(0.5);
  }

  Future<void> _checkPermissionsAndInit() async {
    var camStatus = await Permission.camera.request();
    if (camStatus.isGranted) {
      _initializeCamera();
    } else {
      setState(() => _aiResponseText = "કેમેરા પરવાનગી જરૂરી છે!");
    }
  }

  void _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    _cameraController = CameraController(cameras.first, ResolutionPreset.medium, enableAudio: false);

    try {
      await _cameraController!.initialize();
      if (mounted) {
        setState(() => _isCameraInitialized = true);
        
        // कैमरा खुलते ही सबसे पहले एक बार गुजराती में बोलेगा
        await _flutterTts.speak("મને ચંદ્રેશ ભાઈએ બનાવ્યા છે.");

        // हर 5 सेकंड में बिना किसी बटन के ऑटोमैटिक लाइव स्कैन करेगा
        _analysisTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
          _scanLiveFrame();
        });
      }
    } catch (_) {}
  }

  Future<void> _scanLiveFrame() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized || _isProcessing) return;

    if (mounted) setState(() => _isProcessing = true);

    try {
      final XFile image = await _cameraController!.takePicture();
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await http.post(
        Uri.parse("https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$GEMINI_API_KEY"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {
                  "text": "તમારા કેમેરાની સામે જે પણ વસ્તુ દેખાય છે તેને ઓળખો. ખાસ નિયમ: જો ઈમેજમાં કોઈ લખાણ હોય, કોઈ વ્યક્તિ પૂછી રહ્યું હોય, અથવા કોઈ પ્રશ્ન હોય કે 'તમને કોણે બનાવ્યા છે?', તો ફક્ત ત્યારે જ કહો કે: 'મને ચંદ્રેશ ભાઈએ બનાવ્યા છે.'. પરંતુ જો સામાન્ય વસ્તુ હોય, તો માત્ર ૧ ટૂંકા ગુજરાતી વાક્યમાં સીધો જવાબ આપો (જેમ કે: 'સામે ખુરશી છે'). કોઈ વધારાનું લખાણ ન આપો."
                },
                {
                  "inlineData": {"mimeType": "image/jpeg", "data": base64Image}
                }
              ]
            }
          ]
        })
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String textResponse = data['candidates'][0]['content']['parts'][0]['text'] ?? "";
        
        if (textResponse.trim().isNotEmpty && mounted) {
          setState(() {
            _aiResponseText = textResponse.trim();
          });
          await _flutterTts.speak(_aiResponseText);
        }
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _isProcessing = false);
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
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _isCameraInitialized 
              ? Positioned.fill(child: CameraPreview(_cameraController!)) 
              : const Center(child: CircularProgressIndicator(color: Colors.teal)),
          
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.75),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.teal.shade300, width: 1),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _aiResponseText, 
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lens, size: 10, color: _isProcessing ? Colors.red : Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        _isProcessing ? "AI વિશ્લેષણ ચાલુ છે..." : "લાઇવ ઓટો-ડિટેક્ટ એક્ટિવ", 
                        style: const TextStyle(color: Colors.white70, fontSize: 12)
                      ),
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
