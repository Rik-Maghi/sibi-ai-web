import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'services/interpreter_service.dart';
import 'services/tts_service.dart';
import 'screens/dictionary_screen.dart';
import 'screens/blackboard_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/classification_screen.dart';
import 'screens/camera_screen_web.dart'
    if (dart.library.io) 'screens/camera_screen.dart';
import 'screens/quiz_screen_web.dart'
    if (dart.library.io) 'screens/quiz_screen.dart';

class DashboardLayout extends StatefulWidget {
  final List<CameraDescription> cameras;
  
  const DashboardLayout({super.key, required this.cameras});

  @override
  State<DashboardLayout> createState() => _DashboardLayoutState();
}

class _DashboardLayoutState extends State<DashboardLayout> {
  int _selectedIndex = 0;
  
  // --- Global States ---
  CameraController? _cameraController;
  int _currentCameraIndex = 0;
  bool _isSwitchingCamera = false;
  // Eagerly initialized to prevent LateInitializationError on Web
  final InterpreterService _interpreterService = InterpreterService();
  final TtsService _ttsService = TtsService();
  
  String _blackboardText = ""; // State for Blackboard
  double _ttsSpeed = 0.5;
  double _confidenceThreshold = 0.70;
  String _teamName = "Tim SIBI AI";
  String _universityName = "Universitas Indonesia";

  @override
  void initState() {
    super.initState();
    _initTts();
    _loadModel();
    _initCamera();
  }

  Future<void> _initCamera() async {
    if (widget.cameras.isNotEmpty) {
      await _cameraController?.dispose();
      _cameraController = CameraController(
        widget.cameras[_currentCameraIndex],
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await _cameraController!.initialize();
      if (!mounted) return;
      setState(() {});
    }
  }

  Future<void> _switchCamera() async {
    if (_isSwitchingCamera || widget.cameras.length < 2) return;
    
    setState(() {
      _isSwitchingCamera = true;
    });

    _currentCameraIndex = (_currentCameraIndex + 1) % widget.cameras.length;

    // Dispose old controller safely
    await _cameraController?.dispose();
    
    // Initialize new controller
    await _initCamera();
    
    if (mounted) {
      setState(() {
        _isSwitchingCamera = false;
      });
    }
  }

  Future<void> _initTts() async {
    await _ttsService.init();
    await _ttsService.setSpeechRate(_ttsSpeed);
  }

  void _updateTtsSpeed(double speed) {
    setState(() {
      _ttsSpeed = speed;
    });
    _ttsService.setSpeechRate(speed);
  }

  void _updateConfidenceThreshold(double threshold) {
    setState(() {
      _confidenceThreshold = threshold;
    });
  }

  Future<void> _loadModel() async {
    try {
      await _interpreterService.loadModel();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Failed to load model: $e");
    }
  }
  
  void _appendToBlackboard(String text) {
    setState(() {
      if (text == "SPASI") {
        _blackboardText += " ";
      } else if (text == "HAPUS") {
        if (_blackboardText.isNotEmpty) {
          _blackboardText = _blackboardText.substring(0, _blackboardText.length - 1);
        }
      } else if (text != "SELESAI") {
        _blackboardText += text;
      }
    });
  }

  void _clearBlackboard() {
    setState(() {
      _blackboardText = "";
    });
  }

  void _updateFullBlackboardText(String text) {
    setState(() {
      _blackboardText = text;
    });
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _interpreterService.close();
    super.dispose();
  }

  void _onMenuTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Menyiapkan layar yang dipilih
    Widget activeScreen;
    switch (_selectedIndex) {
      case 0:
        activeScreen = CameraScreen(
          cameraController: _cameraController, 
          interpreterService: _interpreterService,
          ttsService: _ttsService,
          onGestureDetected: _appendToBlackboard,
          confidenceThreshold: _confidenceThreshold,
        );
        break;
      case 1:
        activeScreen = DictionaryScreen(ttsService: _ttsService);
        break;
      case 2:
        activeScreen = QuizScreen(
          cameraController: _cameraController,
          interpreterService: _interpreterService,
          ttsService: _ttsService,
          confidenceThreshold: _confidenceThreshold,
        );
        break;
      case 3:
        activeScreen = BlackboardScreen(
          boardText: _blackboardText,
          onClear: _clearBlackboard,
          onTextUpdate: _updateFullBlackboardText,
          ttsService: _ttsService,
        );
        break;
      case 4:
        activeScreen = SettingsScreen(
          ttsSpeed: _ttsSpeed,
          confidenceThreshold: _confidenceThreshold,
          onTtsSpeedChanged: _updateTtsSpeed,
          onConfidenceThresholdChanged: _updateConfidenceThreshold,
          ttsService: _ttsService,
          teamName: _teamName,
          universityName: _universityName,
          onTeamNameChanged: (val) => setState(() => _teamName = val),
          onUniversityNameChanged: (val) => setState(() => _universityName = val),
        );
        break;
      case 5:
        activeScreen = const ClassificationScreen();
        break;
      default:
        activeScreen = const Center(child: Text("Halaman Tidak Ditemukan"));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1E293B),
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.sign_language, color: Colors.blueAccent),
            const SizedBox(width: 10),
            const Text("SIBI AI", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.greenAccent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.greenAccent.withValues(alpha: 0.35),
                ),
              ),
              child: Text(
                "Edge AI",
                style: TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        actions: [
          if (widget.cameras.length > 1 && (_selectedIndex == 0 || _selectedIndex == 2))
            IconButton(
              icon: _isSwitchingCamera 
                  ? const SizedBox(
                      width: 20, height: 20, 
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                    )
                  : const Icon(Icons.flip_camera_android, color: Colors.white),
              onPressed: _isSwitchingCamera ? null : _switchCamera,
              tooltip: "Ganti Kamera",
            ),
        ],
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFF0F172A),
        child: Column(
          children: [
            const SizedBox(height: 50),
            // Logo
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blueAccent.withValues(alpha: 0.12),
                border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.sign_language, size: 44, color: Colors.blueAccent),
            ),
            const SizedBox(height: 10),
            const Text("SIBI AI",
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 28),

            _buildMenuItem(0, Icons.camera_alt, "Kamera Penerjemah"),
            _buildMenuItem(1, Icons.book, "Kamus SIBI"),
            _buildMenuItem(2, Icons.videogame_asset, "Mode Latihan"),
            _buildMenuItem(3, Icons.edit_note, "Papan Tulis"),
            _buildMenuItem(5, Icons.bar_chart, "Hasil Klasifikasi"),
            const Spacer(),
            _buildMenuItem(4, Icons.settings, "Pengaturan"),
            const SizedBox(height: 16),
          ],
        ),
      ),
      body: SafeArea(child: activeScreen),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget? _buildBottomNav() {
    // Tabs 0-4 use the bottom nav; tab 5 (Classification) is drawer-only.
    final int navIndex = _selectedIndex < 5 ? _selectedIndex : 0;
    return NavigationBar(
      selectedIndex: navIndex,
      onDestinationSelected: _onMenuTapped,
      backgroundColor: const Color(0xFF0F172A),
      indicatorColor: Colors.blueAccent.withValues(alpha: 0.18),
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      animationDuration: const Duration(milliseconds: 300),
      destinations: [
        NavigationDestination(
          icon: Icon(Icons.camera_alt_outlined, color: Colors.white38),
          selectedIcon: const Icon(Icons.camera_alt, color: Colors.blueAccent),
          label: 'Kamera',
        ),
        NavigationDestination(
          icon: Icon(Icons.book_outlined, color: Colors.white38),
          selectedIcon: const Icon(Icons.book, color: Colors.orangeAccent),
          label: 'Kamus',
        ),
        NavigationDestination(
          icon: Icon(Icons.videogame_asset_outlined, color: Colors.white38),
          selectedIcon: const Icon(Icons.videogame_asset, color: Colors.purpleAccent),
          label: 'Latihan',
        ),
        NavigationDestination(
          icon: Icon(Icons.edit_note_outlined, color: Colors.white38),
          selectedIcon: const Icon(Icons.edit_note, color: Colors.tealAccent),
          label: 'Papan',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings_outlined, color: Colors.white38),
          selectedIcon: const Icon(Icons.settings, color: Colors.grey),
          label: 'Pengaturan',
        ),
      ],
    );
  }

  Widget _buildMenuItem(int index, IconData icon, String title) {
    bool isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () {
        _onMenuTapped(index);
        // Menutup otomatis laci (drawer) saat menu dipilih
        Navigator.pop(context);
      },
      child: Container(
        color: isSelected ? Colors.blueAccent.withValues(alpha: 0.2) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.blueAccent : Colors.white54, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title, 
                style: TextStyle(
                  color: isSelected ? Colors.blueAccent : Colors.white70,
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
