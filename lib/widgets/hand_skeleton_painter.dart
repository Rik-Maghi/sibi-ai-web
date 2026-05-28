import 'package:flutter/material.dart';
import 'package:hand_landmarker/hand_landmarker.dart';

class HandSkeletonPainter extends CustomPainter {
  final List<Hand> handLandmarks;
  final bool isFrontCamera;
  final Size absoluteImageSize;

  const HandSkeletonPainter({
    required this.handLandmarks,
    this.isFrontCamera = false, // Default: kamera belakang
    required this.absoluteImageSize,
  });

  // MediaPipe standard hand connections (21 landmarks)
  static const List<List<int>> connections = [
    // Thumb
    [0, 1], [1, 2], [2, 3], [3, 4],
    // Index finger
    [0, 5], [5, 6], [6, 7], [7, 8],
    // Middle finger
    [5, 9], [9, 10], [10, 11], [11, 12],
    // Ring finger
    [9, 13], [13, 14], [14, 15], [15, 16],
    // Pinky
    [13, 17], [0, 17], [17, 18], [18, 19], [19, 20],
    // Palm connections
    [0, 9], [0, 13],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.tealAccent.withValues(alpha: 0.9)
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final jointPaint = Paint()
      ..color = Colors.blueAccent
      ..style = PaintingStyle.fill;

    final fingertipPaint = Paint()
      ..color = Colors.cyanAccent
      ..style = PaintingStyle.fill;

    // FIX: Fingertip indices for visual distinction
    const fingertipIndices = {4, 8, 12, 16, 20};

    for (final hand in handLandmarks) {
      final landmarks = hand.landmarks;
      if (landmarks.length != 21) continue;

      // Draw connections
      for (final conn in connections) {
        final startIdx = conn[0];
        final endIdx = conn[1];
        if (startIdx < landmarks.length && endIdx < landmarks.length) {
          canvas.drawLine(
            _toOffset(landmarks[startIdx], size),
            _toOffset(landmarks[endIdx], size),
            linePaint,
          );
        }
      }

      // Draw landmark points
      for (int i = 0; i < landmarks.length; i++) {
        final offset = _toOffset(landmarks[i], size);
        final isFingertip = fingertipIndices.contains(i);

        // Fingertips lebih besar dan berwarna berbeda
        canvas.drawCircle(
          offset,
          isFingertip ? 6.0 : 4.0,
          isFingertip ? fingertipPaint : jointPaint,
        );

        // White border ring pada fingertips untuk visibilitas
        if (isFingertip) {
          canvas.drawCircle(
            offset,
            6.0,
            Paint()
              ..color = Colors.white.withValues(alpha: 0.6)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5,
          );
        }
      }
    }
  }

  /// Kalibrasi absolut landmark agar selaras pada berbagai rasio layar.
  Offset _toOffset(Landmark landmark, Size canvasSize) {
    double rawX = landmark.x.clamp(0.0, 1.0);
    double rawY = landmark.y.clamp(0.0, 1.0);

    if (isFrontCamera) {
      rawX = 1.0 - rawX;
    }

    final double srcW =
        absoluteImageSize.width <= 0 ? canvasSize.width : absoluteImageSize.width;
    final double srcH = absoluteImageSize.height <= 0
        ? canvasSize.height
        : absoluteImageSize.height;

    final double scaleX = canvasSize.width / srcW;
    final double scaleY = canvasSize.height / srcH;
    final double scale = scaleX < scaleY ? scaleX : scaleY;

    final double offsetX = (canvasSize.width - (srcW * scale)) / 2.0;
    final double offsetY = (canvasSize.height - (srcH * scale)) / 2.0;

    final double finalX = (rawX * srcW * scale) + offsetX;
    final double finalY = (rawY * srcH * scale) + offsetY;

    return Offset(finalX, finalY);
  }

  @override
  bool shouldRepaint(covariant HandSkeletonPainter oldDelegate) {
    if (oldDelegate.handLandmarks.length != handLandmarks.length) return true;
    if (oldDelegate.absoluteImageSize != absoluteImageSize) return true;
    if (oldDelegate.isFrontCamera != isFrontCamera) return true;
    if (handLandmarks.isEmpty) return false;
    return true;
  }
}
