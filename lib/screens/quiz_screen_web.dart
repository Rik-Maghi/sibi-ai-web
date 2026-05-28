import 'package:flutter/material.dart';

import '../services/interpreter_service.dart';
import '../services/tts_service.dart';

class QuizScreen extends StatelessWidget {
  final dynamic cameraController;
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
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Center(
        child: Text(
          'Mode Latihan Web masih simulator.\n'
          'Deteksi tangan real-time membutuhkan pipeline web terpisah.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
        ),
      ),
    );
  }
}
