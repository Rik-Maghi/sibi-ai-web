import 'package:flutter/material.dart';

import '../services/interpreter_service.dart';
import '../services/tts_service.dart';

class CameraScreen extends StatelessWidget {
  final dynamic cameraController;
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
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Center(
        child: Text(
          'Web mode aktif. Pipeline AI native (JNI/FFI) tidak tersedia di browser.\n'
          'Gunakan versi mobile untuk deteksi landmark real-time saat ini.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
        ),
      ),
    );
  }
}
