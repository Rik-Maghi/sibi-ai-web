import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:hand_landmarker/hand_landmarker.dart';

import '../services/interpreter_service.dart';
import '../services/tts_service.dart';
import '../services/gesture_utils.dart';
import '../widgets/hand_skeleton_painter.dart';

class QuizScreen extends StatefulWidget {
  final CameraController? cameraController;
  final InterpreterService interpreterService;
  final TtsService ttsService;
  final double confidenceThreshold;

  const QuizScreen({
    super.key,
    required this.cameraController,
    required this.interpreterService,
    required this.ttsService,
    required this.confidenceThreshold,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen>
    with SingleTickerProviderStateMixin {
  final Random _random = Random();
  final List<String> _alphabet =
      List.generate(26, (i) => String.fromCharCode(i + 65));

  String _targetLetter = "A";
  String _detectedLetter = "?";
  bool _isQuizActive = false;
  bool _isProcessing = false;
  bool _showSuccess = false;
  bool _showHint = false;
  bool _streamActive = false; // FIX: track stream state

  int _score = 0;
  int _totalAttempts = 0;
  int _streak = 0;

  final List<String> _predictionBuffer = [];
  final int _bufferSize = 5;

  late AnimationController _successAnimController;
  late Animation<double> _successScaleAnim;

  HandLandmarkerPlugin? _handLandmarker;
  List<Hand> _handLandmarks = [];

  @override
  void initState() {
    super.initState();
    _generateNewTarget();
    _initLandmarker();

    _successAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _successScaleAnim = CurvedAnimation(
      parent: _successAnimController,
      curve: Curves.elasticOut,
    );
  }

  Future<void> _initLandmarker() async {
    try {
      _handLandmarker = HandLandmarkerPlugin.create(
        numHands: 2,
        minHandDetectionConfidence: 0.5,
        delegate: HandLandmarkerDelegate.gpu,
      );
      debugPrint("Quiz HandLandmarkerPlugin initialized (GPU)");
    } catch (e) {
      debugPrint("GPU failed, trying CPU fallback: $e");
      try {
        _handLandmarker = HandLandmarkerPlugin.create(
          numHands: 2,
          minHandDetectionConfidence: 0.5,
          delegate: HandLandmarkerDelegate.cpu,
        );
        debugPrint("Quiz HandLandmarkerPlugin initialized (CPU fallback)");
      } catch (e2) {
        debugPrint("Quiz HandLandmarker init failed: $e2");
      }
    }
  }

  @override
  void dispose() {
    _stopStream(); // FIX: stop stream on dispose
    _handLandmarker?.dispose();
    _successAnimController.dispose();
    super.dispose();
  }

  void _generateNewTarget() {
    setState(() {
      _targetLetter = _alphabet[_random.nextInt(_alphabet.length)];
      _detectedLetter = "?";
      _showSuccess = false;
      _showHint = false;
      _predictionBuffer.clear();
    });
  }

  void _startQuiz() {
    setState(() {
      _isQuizActive = true;
      _score = 0;
      _totalAttempts = 0;
      _streak = 0;
    });
    _generateNewTarget();
    _startStream(); // FIX: use managed stream start
  }

  void _stopQuiz() {
    _stopStream(); // FIX: properly stop stream
    setState(() {
      _isQuizActive = false;
      _handLandmarks = [];
    });
  }

  // FIX: Force-stop any existing stream (from camera tab) before starting quiz stream.
  // Kamera tab dan Quiz tab berbagi satu CameraController yang sama.
  // Harus di-await agar native thread Android tidak mengalami deadlock (ANR freeze).
  Future<void> _startStream() async {
    final ctrl = widget.cameraController;
    if (ctrl == null || !ctrl.value.isInitialized) return;
    if (_streamActive) return;
    try {
      // Paksa stop stream yang mungkin masih berjalan secara async
      if (ctrl.value.isStreamingImages) {
        await ctrl.stopImageStream();
      }

      ctrl.startImageStream((CameraImage image) {
        if (_isQuizActive && !_isProcessing && !_showSuccess) {
          _isProcessing = true;
          _processQuizFrame(image);
        }
      });
      _streamActive = true;
    } catch (e) {
      debugPrint("Error starting quiz stream: $e");
    }
  }

  // FIX: Proper stream stop to prevent resource leaks
  void _stopStream() {
    if (!_streamActive) return;
    try {
      widget.cameraController?.stopImageStream();
      _streamActive = false;
    } catch (e) {
      debugPrint("Error stopping quiz stream: $e");
    }
  }

  Future<void> _processQuizFrame(CameraImage image) async {
    if (!widget.interpreterService.isReady || _handLandmarker == null) {
      if (mounted) _isProcessing = false;
      return;
    }
    try {
      final int sensorOrientation =
          widget.cameraController!.description.sensorOrientation;
      final List<Hand> results =
          _handLandmarker!.detect(image, sensorOrientation);

      if (results.isEmpty) {
        if (mounted) {
          setState(() {
            _handLandmarks = [];
            _predictionBuffer.clear();
          });
        }
        _isProcessing = false;
        return;
      }

      if (mounted) {
        setState(() => _handLandmarks = results);
      }

      // FIX: Use centralized GestureUtils
      final hands = GestureUtils.separateHands(results);
      final List<double> features =
          GestureUtils.buildInputFeatures(hands.left, hands.right);

      final List<double> probs = widget.interpreterService.run(features);
      int maxIdx = 0;
      double maxP = probs[0];
      for (int i = 1; i < probs.length; i++) {
        if (probs[i] > maxP) {
          maxP = probs[i];
          maxIdx = i;
        }
      }

      if (maxP > widget.confidenceThreshold) {
        final String pred = GestureUtils.mapIndexToLabel(maxIdx);
        _predictionBuffer.add(pred);
        if (_predictionBuffer.length > _bufferSize) {
          _predictionBuffer.removeAt(0);
        }

        // FIX: Only act when buffer is full (5/5 consistent predictions)
        if (_predictionBuffer.length == _bufferSize &&
            _predictionBuffer.every((e) => e == pred)) {
          if (mounted) {
            setState(() => _detectedLetter = pred);
          }
          if (pred == _targetLetter && !_showSuccess) {
            _onCorrectAnswer();
          }
        }
      }
    } catch (e) {
      debugPrint("Quiz Error: $e");
    } finally {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) _isProcessing = false;
      });
    }
  }

  void _checkQuizCompletion() {
    if (_totalAttempts >= 3) {
      _stopStream();
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text("Uji Coba Selesai! 🎉", style: TextStyle(color: Colors.white)),
          content: Text(
            "Kamu berhasil mendapat skor $_score dari 3 stage.\n\nMode tantangan selanjutnya akan dikembangkan lebih lanjut!",
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _totalAttempts = 0;
                  _score = 0;
                  _streak = 0;
                  _isQuizActive = false;
                });
                _generateNewTarget();
              },
              child: const Text("Mulai Ulang", style: TextStyle(color: Colors.blueAccent)),
            )
          ],
        )
      );
    } else {
      _generateNewTarget();
    }
  }

  void _onCorrectAnswer() {
    setState(() {
      _showSuccess = true;
      _score++;
      _totalAttempts++;
      _streak++;
    });
    _successAnimController.forward(from: 0);
    widget.ttsService.speakCorrect(_targetLetter);

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _isQuizActive) {
        _checkQuizCompletion();
      }
    });
  }

  void _skipLetter() {
    setState(() {
      _totalAttempts++;
      _streak = 0;
    });
    _checkQuizCompletion();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ====== TITLE BAR ======
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.videogame_asset,
                    color: Colors.purpleAccent, size: 28),
                const SizedBox(width: 12),
                const Text("Mode Latihan (Quiz)",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.shade800,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text("Skor: $_score/3",
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ====== MAIN CONTENT ======
          Expanded(
            child: _isQuizActive
                ? _buildQuizContent()
                : _buildStartScreen(),
          ),
        ],
      ),
    );
  }

  Widget _buildStartScreen() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(40),
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: const Color(0xFF334155),
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: Colors.purpleAccent.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events, color: Colors.amber, size: 80),
            const SizedBox(height: 24),
            const Text(
              "Mode Latihan Isyarat",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              "Aplikasi akan menampilkan huruf acak.\nPeragakan isyarat yang benar di depan kamera!\nSemakin banyak benar berturut-turut, semakin tinggi streak Anda!",
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white70, fontSize: 15, height: 1.6),
            ),
            const SizedBox(height: 32),
            if (_totalAttempts > 0) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatItem("Skor", "$_score"),
                    _buildStatItem("Total", "$_totalAttempts"),
                    _buildStatItem(
                        "Akurasi",
                        _totalAttempts > 0
                            ? "${((_score / _totalAttempts) * 100).toStringAsFixed(0)}%"
                            : "0%"),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            ElevatedButton.icon(
              onPressed: _startQuiz,
              icon: const Icon(Icons.play_arrow, size: 28),
              label: Text(
                _totalAttempts > 0 ? "Main Lagi!" : "Mulai Latihan!",
                style: const TextStyle(fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purpleAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 40, vertical: 18),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label,
            style:
                const TextStyle(color: Colors.white54, fontSize: 13)),
      ],
    );
  }

  Widget _buildQuizContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isWide = constraints.maxWidth > 700;
        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 3, child: _buildCameraArea()),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: _buildChallengePanel()),
            ],
          );
        } else {
          return Column(
            children: [
              Expanded(flex: 2, child: _buildCameraArea()),
              const SizedBox(height: 12),
              Expanded(flex: 1, child: _buildChallengePanel()),
            ],
          );
        }
      },
    );
  }

  Widget _buildCameraArea() {
    final ctrl = widget.cameraController;
    final previewSize = ctrl?.value.previewSize;
    final absoluteImageSize = previewSize == null
        ? const Size(1, 1)
        : Size(previewSize.height, previewSize.width);
    final isFrontCamera =
        ctrl?.description.lensDirection == CameraLensDirection.front;

    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155), width: 2),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (ctrl != null && ctrl.value.isInitialized) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Center(
                child: CameraPreview(
                  ctrl,
                  child: _isQuizActive
                      ? CustomPaint(
                          painter: HandSkeletonPainter(
                            handLandmarks: _handLandmarks,
                            isFrontCamera: isFrontCamera,
                            absoluteImageSize: absoluteImageSize,
                          ),
                        )
                      : null,
                ),
              ),
            ),
          ] else
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: Colors.purpleAccent.withValues(alpha: 0.3), width: 2),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.purpleAccent.withValues(alpha: 0.1),
                        border: Border.all(
                            color: Colors.purpleAccent.withValues(alpha: 0.4)),
                      ),
                      child: const Icon(Icons.web,
                          color: Colors.purpleAccent, size: 52),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Mode Web 🌐",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Kamera tidak tersedia di browser.\nGunakan tombol \"Simulasikan\"\nuntuk menjawab tantangan!",
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(color: Colors.white54, fontSize: 14, height: 1.6),
                    ),
                  ],
                ),
              ),
            ),

          // Guide box
          Center(
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(
                    color: Colors.purpleAccent.withValues(alpha: 0.7),
                    width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          // Detected Letter Badge
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: _detectedLetter == _targetLetter
                        ? Colors.greenAccent
                        : Colors.white24),
              ),
              child: Text(
                _detectedLetter,
                style: TextStyle(
                  color: _detectedLetter == _targetLetter
                      ? Colors.greenAccent
                      : Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Success Overlay
          if (_showSuccess)
            Center(
              child: ScaleTransition(
                scale: _successScaleAnim,
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.green.shade800.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle,
                          color: Colors.greenAccent, size: 80),
                      SizedBox(height: 12),
                      Text("Hebat! Benar! ✅",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChallengePanel() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Target Letter Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF334155),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: Colors.purpleAccent.withValues(alpha: 0.4)),
            ),
            child: Column(
              children: [
                const Text("Peragakan Huruf:",
                    style: TextStyle(
                        color: Colors.white70, fontSize: 18)),
                const SizedBox(height: 12),
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.purpleAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.purpleAccent, width: 3),
                  ),
                  child: Center(
                    child: Text(
                      _targetLetter,
                      style: const TextStyle(
                          color: Colors.purpleAccent,
                          fontSize: 72,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Tunjukkan isyarat tangan di depan kamera!",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () =>
                      setState(() => _showHint = !_showHint),
                  icon: Icon(
                      _showHint
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.purpleAccent),
                  label: Text(
                      _showHint
                          ? "Sembunyikan Petunjuk"
                          : "Tampilkan Petunjuk",
                      style: const TextStyle(
                          color: Colors.purpleAccent,
                          fontWeight: FontWeight.bold)),
                ),
                if (_showHint) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: 100,
                    height: 100,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.purpleAccent.withValues(alpha: 0.5)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        'assets/images/letter_${_targetLetter.toLowerCase()}.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(Icons.help_outline,
                                color: Colors.purpleAccent, size: 40),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Stats Row
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF334155),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem("Skor", "$_score"),
                Container(
                    width: 1, height: 40, color: Colors.white12),
                _buildStatItem("Streak", "🔥 $_streak"),
                Container(
                    width: 1, height: 40, color: Colors.white12),
                _buildStatItem("Total", "$_totalAttempts"),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Action Buttons
          Row(
            children: [
              if (kIsWeb) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() => _detectedLetter = _targetLetter);
                      _onCorrectAnswer();
                    },
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text("Simulasikan"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _skipLetter,
                  icon: const Icon(Icons.skip_next),
                  label: const Text("Lewati"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade800,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _stopQuiz,
                  icon: const Icon(Icons.stop),
                  label: const Text("Selesai"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade800,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
