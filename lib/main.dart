import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

// अब चाबी यहाँ नहीं रहेगी, बल्कि गिटहब इसे बैकग्राउंड से सुरक्षित पास करेगा
const String GEMINI_API_KEY = String.fromEnvironment('GEMINI_KEY');

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
  String _aiResponseText = "લાઇવ કેમેરા શરૂ થઈ રહ્યો છે...";
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
        await _flutterTts.speak("મને ચંદ્રેશ ભાઈએ બનાવ્યા છે.");

        _analysisTimer = Timer.periodic(const Duration(seconds: 6), (timer) {
          _scanLiveFrame();
        });
      }
    } catch (e) {
      setState(() => _aiResponseText = "કેમેરા શરૂ કરવામાં ભૂલ: $e");
    }
  }

  Future<void> _scanLiveFrame() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized || _isProcessing) return;

    if (mounted) setState(() => _isProcessing = true);

    try {
      final XFile image = await _cameraController!.takePicture();
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);

      if (GEMINI_API_KEY.isEmpty || GEMINI_API_KEY == 'null') {
        setState(() => _aiResponseText = "ભૂલ: ચાબી સેટ નથી! ગિટહબ સીક્રેટ્સ ચેક કરો.");
        return;
      }

      final response = await http.post(
        Uri.parse("https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$GEMINI_API_KEY"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {
                  "text": "તમારી સામે જે પણ વસ્તુ છે તેને ઓળખો અને ૧ ટૂંકા ગુજરાતી વાક્યમાં સીધો જવાબ આપો."
                },
                {
                  "inlineData": {"mimeType": "image/jpeg", "data": base64Image}
                }
              ]
            }
          ]
        })
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String textResponse = data['candidates'][0]['content']['parts'][0]['text'] ?? "";
        
        if (textResponse.trim().isNotEmpty && mounted) {
          setState(() {
            _aiResponseText = textResponse.trim();
          });
          await _flutterTts.speak(_aiResponseText);
        }
      } else {
        if (mounted) {
          setState(() {
            _aiResponseText = "સર્વર ભૂલ: ${response.statusCode}\nકોડ ચેક કરો.";
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _aiResponseText = "કનેક્શન ભૂલ: ઈન્ટરનેટ ચેક કરો.";
        });
      }
    } finally {
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
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)
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
