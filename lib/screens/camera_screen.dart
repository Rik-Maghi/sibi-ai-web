import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hand_landmarker/hand_landmarker.dart';

import '../services/interpreter_service.dart';
import '../services/tts_service.dart';
import '../services/gesture_utils.dart';
import '../widgets/hand_skeleton_painter.dart';

class CameraScreen extends StatefulWidget {
  final CameraController? cameraController;
  final InterpreterService interpreterService;
  final TtsService ttsService;
  final Function(String) onGestureDetected;
  final double confidenceThreshold;

  const CameraScreen({
    super.key,
    required this.cameraController,
    required this.interpreterService,
    required this.ttsService,
    required this.onGestureDetected,
    required this.confidenceThreshold,
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  bool _isScanning = false;
  bool _isProcessing = false;
  String _currentPrediction = "Menunggu...";
  double _confidence = 0.0;
  bool _noHandWarning = false;
  bool _streamActive = false; // FIX: track stream state
  bool _mirrorFrontLandmarks = true; // Device-specific front preview calibration

  final List<String> _predictionBuffer = [];
  final int _bufferSize = 5;
  final List<String> _historyList = [];

  HandLandmarkerPlugin? _handLandmarker;
  List<Hand> _handLandmarks = [];

  bool _isDisposing = false;
  DateTime? _lastSpecialGestureTime;

  @override
  void initState() {
    super.initState();
    _initLandmarker();
  }

  Future<void> _initLandmarker() async {
    try {
      _handLandmarker = HandLandmarkerPlugin.create(
        numHands: 2,
        minHandDetectionConfidence: 0.5,
        delegate: HandLandmarkerDelegate.gpu,
      );
      debugPrint("HandLandmarkerPlugin initialized successfully");
    } catch (e) {
      debugPrint("Failed to initialize HandLandmarkerPlugin: $e");
      // FIX: Try CPU fallback if GPU fails
      try {
        _handLandmarker = HandLandmarkerPlugin.create(
          numHands: 2,
          minHandDetectionConfidence: 0.5,
          delegate: HandLandmarkerDelegate.cpu,
        );
        debugPrint("HandLandmarkerPlugin initialized with CPU fallback");
      } catch (e2) {
        debugPrint("CPU fallback also failed: $e2");
      }
    }
  }

  @override
  void dispose() {
    _isDisposing = true;
    _isProcessing = true; // Lock processing gate permanently during teardown
    _stopStream(); // FIX: properly stop stream on dispose
    // Tunda penghancuran objek native agar proses detect() yang sedang berjalan bisa selesai
    Future.delayed(const Duration(milliseconds: 250), () {
      _handLandmarker?.dispose();
      _handLandmarker = null; // Release native reference after dispose
    });
    super.dispose();
  }

  // FIX: Proper stream start - checks if already active and stops cleanly
  Future<void> _startStream() async {
    final ctrl = widget.cameraController;
    if (ctrl == null || !ctrl.value.isInitialized || _streamActive) return;
    try {
      if (ctrl.value.isStreamingImages) {
        await ctrl.stopImageStream();
      }

      ctrl.startImageStream((CameraImage image) {
        if (_isScanning && !_isProcessing) {
          _isProcessing = true;
          _processCameraImage(image);
        }
      });
      _streamActive = true;
    } catch (e) {
      debugPrint("Error starting image stream: $e");
    }
  }

  // FIX: Proper stream stop to avoid resource leaks
  void _stopStream() {
    if (!_streamActive) return;
    try {
      widget.cameraController?.stopImageStream();
      _streamActive = false;
    } catch (e) {
      debugPrint("Error stopping image stream: $e");
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    // Guard 1: reject new/in-flight frame work if widget is already tearing down.
    if (_isDisposing || !mounted) {
      _isProcessing = false;
      return;
    }

    if (!widget.interpreterService.isReady || _handLandmarker == null) {
      if (mounted && !_isDisposing) _isProcessing = false;
      return;
    }

    final stopwatch = Stopwatch()..start();
    int detectTimeMs = 0;
    int featureTimeMs = 0;
    int inferenceTimeMs = 0;

    try {
      // Guard 2: check again before entering native detection call.
      if (_isDisposing || _handLandmarker == null) return;

      final detectStartMs = stopwatch.elapsedMilliseconds;
      final int sensorOrientation =
          widget.cameraController!.description.sensorOrientation;
      final List<Hand> results =
          _handLandmarker!.detect(image, sensorOrientation);
      detectTimeMs = stopwatch.elapsedMilliseconds - detectStartMs;

      // Guard 3: detection finished, but widget may already be disposed.
      if (_isDisposing || !mounted) return;

      if (results.isEmpty) {
        if (mounted) {
          setState(() {
            _noHandWarning = true;
            _handLandmarks = [];
            _predictionBuffer.clear();
          });
        }
        _isProcessing = false;
        return;
      }

      if (mounted) {
        setState(() {
          _noHandWarning = false;
          _handLandmarks = results;
        });
      }

      // FIX: Use centralized GestureUtils
      final featureStartMs = stopwatch.elapsedMilliseconds;
      final hands = GestureUtils.separateHands(results);
      final List<double> inputFeatures =
          GestureUtils.buildInputFeatures(hands.left, hands.right);
      featureTimeMs = stopwatch.elapsedMilliseconds - featureStartMs;

      final inferenceStartMs = stopwatch.elapsedMilliseconds;
      final List<double> probabilities =
          widget.interpreterService.run(inputFeatures);
      inferenceTimeMs = stopwatch.elapsedMilliseconds - inferenceStartMs;

      int maxIndex = 0;
      double maxProb = probabilities[0];
      for (int i = 1; i < probabilities.length; i++) {
        if (probabilities[i] > maxProb) {
          maxProb = probabilities[i];
          maxIndex = i;
        }
      }

      if (maxProb > widget.confidenceThreshold) {
        final String predictedLabel = GestureUtils.mapIndexToLabel(maxIndex);

        // Gesture kontrol (SELESAI/HAPUS/SPASI) membutuhkan confidence
        // jauh lebih tinggi (97%) agar tidak mudah terpicu secara tidak sengaja
        const specialGestures = {'SELESAI', 'HAPUS', 'SPASI'};
        final double effectiveThreshold = specialGestures.contains(predictedLabel)
            ? 0.97
            : widget.confidenceThreshold;

        if (maxProb < effectiveThreshold) {
          final totalTimeMs = stopwatch.elapsedMilliseconds;
          debugPrint(
              'SIBI-Talk Profile | Total: ${totalTimeMs}ms | MediaPipe: ${detectTimeMs}ms | Features: ${featureTimeMs}ms | TFLite: ${inferenceTimeMs}ms');
          // Tidak memenuhi threshold khusus, lewati frame ini
          _isProcessing = false;
          return;
        }

        _predictionBuffer.add(predictedLabel);
        if (_predictionBuffer.length > _bufferSize) {
          _predictionBuffer.removeAt(0);
        }

        if (_predictionBuffer.length == _bufferSize &&
            _predictionBuffer.every((e) => e == predictedLabel)) {
            
          bool canTrigger = true;
          if (specialGestures.contains(predictedLabel)) {
            if (_lastSpecialGestureTime != null && 
                DateTime.now().difference(_lastSpecialGestureTime!).inMilliseconds < 1500) {
              canTrigger = false;
            } else {
              _lastSpecialGestureTime = DateTime.now();
            }
          }

          if (canTrigger && (_currentPrediction != predictedLabel || specialGestures.contains(predictedLabel))) {
            HapticFeedback.lightImpact();
            if (mounted) {
              setState(() {
                _currentPrediction = predictedLabel;
                _confidence = maxProb;
                if (!specialGestures.contains(predictedLabel) || _historyList.isEmpty || _historyList.first != predictedLabel) {
                  _historyList.insert(0, predictedLabel);
                }
                if (_historyList.length > 20) _historyList.removeLast();
              });
            }
            widget.onGestureDetected(predictedLabel);
            widget.ttsService.speakLetter(predictedLabel);
          }
        }
      }

      final totalTimeMs = stopwatch.elapsedMilliseconds;
      debugPrint(
          'SIBI-Talk Profile | Total: ${totalTimeMs}ms | MediaPipe: ${detectTimeMs}ms | Features: ${featureTimeMs}ms | TFLite: ${inferenceTimeMs}ms');
    } catch (e) {
      debugPrint("Error Processing Frame: $e");
    } finally {
      stopwatch.stop();
      // FIX: Debounce — wait 50ms before allowing next frame to process
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted && !_isDisposing) _isProcessing = false;
      });
    }
  }

  void _toggleScanning() {
    if (_isScanning) {
      // Stop scanning
      setState(() {
        _isScanning = false;
        _handLandmarks = [];
        _noHandWarning = false;
        _currentPrediction = "Menunggu...";
        _confidence = 0.0;
        _predictionBuffer.clear();
      });
      _stopStream(); // FIX: stop stream properly
    } else {
      // Start scanning
      setState(() {
        _isScanning = true;
      });
      _startStream(); // FIX: (re)start stream properly
    }
  }

  void _simulatePrediction(String label) {
    HapticFeedback.lightImpact();
    setState(() {
      _currentPrediction = label;
      _confidence = 0.98;
      _historyList.insert(0, label);
      if (_historyList.length > 20) _historyList.removeLast();
    });
    widget.onGestureDetected(label);
    widget.ttsService.speakLetter(label);
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.camera_alt, color: Colors.blueAccent, size: 28),
                SizedBox(width: 12),
                Text("Kamera Penerjemah",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ====== MAIN CONTENT ======
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                bool isWide = constraints.maxWidth > 700;
                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 3, child: _buildCameraView()),
                      const SizedBox(width: 12),
                      Expanded(flex: 2, child: _buildSidePanel()),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      Expanded(flex: 2, child: _buildCameraView()),
                      const SizedBox(height: 12),
                      Expanded(flex: 1, child: _buildSidePanel()),
                    ],
                  );
                }
              },
            ),
          ),

          // ====== BOTTOM BAR ======
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: _toggleScanning,
                  icon: Icon(
                      _isScanning
                          ? Icons.stop_circle_outlined
                          : Icons.play_circle_outline,
                      size: 28),
                  label: Text(
                      _isScanning ? "Berhenti" : "Mulai Scanning",
                      style: const TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isScanning
                        ? Colors.red.shade700
                        : Colors.green.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                Flexible(
                  child: Text(
                    "Hasil: $_currentPrediction",
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraView() {
    final ctrl = widget.cameraController;
    final isFrontCamera = ctrl?.description.lensDirection ==
        CameraLensDirection.front;
    final shouldMirrorLandmarks = isFrontCamera && _mirrorFrontLandmarks;
    final previewSize = ctrl?.value.previewSize;
    final absoluteImageSize = previewSize == null
        ? const Size(1, 1)
        : Size(previewSize.height, previewSize.width);

    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155), width: 2),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (widget.cameraController != null &&
              widget.cameraController!.value.isInitialized)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Center(
                child: CameraPreview(
                  widget.cameraController!,
                  child: _isScanning
                      ? CustomPaint(
                          painter: HandSkeletonPainter(
                            handLandmarks: _handLandmarks,
                            isFrontCamera: shouldMirrorLandmarks,
                            absoluteImageSize: absoluteImageSize,
                          ),
                        )
                      : null,
                ),
              ),
            )
          else
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.blueAccent),
                  SizedBox(height: 16),
                  Text("Memuat Kamera...",
                      style: TextStyle(color: Colors.white54)),
                ],
              ),
            ),

          // No Hand Warning
          if (_isScanning && _noHandWarning)
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text("Tangan tidak terlihat!",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),

          // LIVE/PAUSED indicator
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            _isScanning ? Colors.greenAccent : Colors.red,
                      )),
                  const SizedBox(width: 8),
                  Text(
                    _isScanning ? "LIVE" : "PAUSED",
                    style: TextStyle(
                        color: _isScanning
                            ? Colors.greenAccent
                            : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                  ),
                ],
              ),
            ),
          ),

          if (isFrontCamera)
            Positioned(
              top: 12,
              right: 12,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _mirrorFrontLandmarks = !_mirrorFrontLandmarks;
                  });
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _mirrorFrontLandmarks
                          ? Colors.greenAccent
                          : Colors.orangeAccent,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _mirrorFrontLandmarks
                            ? Icons.flip
                            : Icons.flip_outlined,
                        color: _mirrorFrontLandmarks
                            ? Colors.greenAccent
                            : Colors.orangeAccent,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _mirrorFrontLandmarks ? "Mirror ON" : "Mirror OFF",
                        style: TextStyle(
                          color: _mirrorFrontLandmarks
                              ? Colors.greenAccent
                              : Colors.orangeAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Detected Letter Overlay
          if (_currentPrediction != "Menunggu...")
            Positioned(
              top: isFrontCamera ? 52 : 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blueAccent, width: 2),
                ),
                child: Text(
                  _currentPrediction,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSidePanel() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Web Simulator Panel
          if (kIsWeb && widget.cameraController == null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: Colors.blueAccent.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.cell_tower, color: Colors.blueAccent),
                      SizedBox(width: 8),
                      Text("Web Simulator Panel 🌐",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                      "Klik tombol huruf untuk mensimulasikan deteksi SIBI!",
                      style:
                          TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      ...List.generate(26, (i) => String.fromCharCode(i + 65))
                          .map((letter) {
                        return SizedBox(
                          width: 38,
                          height: 38,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              backgroundColor:
                                  Colors.blueAccent.shade700,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () => _simulatePrediction(letter),
                            child: Text(letter,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14)),
                          ),
                        );
                      }),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => _simulatePrediction("SPASI"),
                        child: const Text("SPASI",
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => _simulatePrediction("HAPUS"),
                        child: const Text("HAPUS",
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          // Gesture Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF334155),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isScanning)
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.greenAccent,
                        ),
                      ),
                    Text(
                      _isScanning ? "Sedang Mendeteksi" : "Gestur Terdeteksi",
                      style: TextStyle(
                          color: _isScanning
                              ? Colors.greenAccent
                              : Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Divider(color: Colors.white24),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Hand icon with detection ring
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        if (_currentPrediction != "Menunggu...")
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.blueAccent.withValues(alpha: 0.4),
                                  width: 2),
                            ),
                          ),
                        const Icon(Icons.back_hand_outlined,
                            color: Colors.blueAccent, size: 52),
                      ],
                    ),
                    const SizedBox(width: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentPrediction,
                          style: TextStyle(
                              color: _currentPrediction == "Menunggu..."
                                  ? Colors.white38
                                  : Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _currentPrediction == "Menunggu..."
                              ? "Arahkan tangan ke kamera"
                              : "Confidence: ${(_confidence * 100).toStringAsFixed(1)}%",
                          style: TextStyle(
                              color: _currentPrediction == "Menunggu..."
                                  ? Colors.white24
                                  : Colors.greenAccent,
                              fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _currentPrediction == "Menunggu..."
                        ? 0.0
                        : _confidence,
                    backgroundColor: Colors.grey[800],
                    color: _confidence > 0.85
                        ? Colors.greenAccent
                        : Colors.orangeAccent,
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // History List
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF334155),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Riwayat Deteksi",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    if (_historyList.isNotEmpty)
                      TextButton(
                        onPressed: () => setState(() => _historyList.clear()),
                        child: const Text("Hapus",
                            style: TextStyle(
                                color: Colors.redAccent, fontSize: 13)),
                      ),
                  ],
                ),
                const Divider(color: Colors.white24),
                if (_historyList.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                        child: Text("Belum ada gestur terdeteksi",
                            style: TextStyle(color: Colors.white38))),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _historyList.take(15).map((letter) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: Colors.blueAccent.withValues(alpha: 0.3)),
                        ),
                        child: Text(letter,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
