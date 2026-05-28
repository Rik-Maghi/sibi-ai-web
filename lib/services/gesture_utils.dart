import 'package:hand_landmarker/hand_landmarker.dart';
import 'dart:typed_data';

/// Utility class untuk normalisasi landmark tangan dan mapping label.
/// Digunakan bersama oleh camera_screen.dart dan quiz_screen.dart
/// agar tidak ada duplikasi logika yang bisa desync.
class GestureUtils {
  // Label untuk 26 huruf SIBI + kontrol
  static const List<String> labels = [
    'A','B','C','D','E','F','G','H','I','J','K','L','M',
    'N','O','P','Q','R','S','T','U','V','W','X','Y','Z',
    'SPASI', 'HAPUS', 'SELESAI'
  ];

  // Zero-allocation buffer: 2 tangan x 21 landmark x 3 koordinat = 126.
  static final Float32List _inputBuffer = Float32List(126);

  /// Normalisasi landmark langsung ke buffer global tanpa alokasi List baru.
  static void _normalizeAndScaleInPlace(List<Landmark>? landmarks, int offset) {
    if (landmarks == null || landmarks.isEmpty || landmarks.length != 21) {
      for (int i = 0; i < 63; i++) {
        _inputBuffer[offset + i] = 0.0;
      }
      return;
    }

    final double wristX = landmarks[0].x;
    final double wristY = landmarks[0].y;
    final double wristZ = landmarks[0].z;
    double maxDistance = 0.0;

    for (int i = 0; i < 21; i++) {
      final double nx = landmarks[i].x - wristX;
      final double ny = landmarks[i].y - wristY;
      final double nz = landmarks[i].z - wristZ;

      _inputBuffer[offset + (i * 3)] = nx;
      _inputBuffer[offset + (i * 3) + 1] = ny;
      _inputBuffer[offset + (i * 3) + 2] = nz;

      if (nx.abs() > maxDistance) maxDistance = nx.abs();
      if (ny.abs() > maxDistance) maxDistance = ny.abs();
      if (nz.abs() > maxDistance) maxDistance = nz.abs();
    }

    if (maxDistance > 0.0) {
      for (int i = 0; i < 63; i++) {
        _inputBuffer[offset + i] /= maxDistance;
      }
    }
  }

  /// Mapping index output model ke string label.
  static String mapIndexToLabel(int index) {
    if (index >= 0 && index < labels.length) return labels[index];
    return '?';
  }

  /// Memisahkan dua tangan dari hasil deteksi berdasarkan posisi X pergelangan tangan.
  /// Pada kamera depan (mirrored): tangan di kiri layar = tangan kanan fisik.
  static ({List<Landmark>? left, List<Landmark>? right}) separateHands(
      List<Hand> results) {
    List<Landmark>? leftHand;
    List<Landmark>? rightHand;

    if (results.length == 1) {
      if (results[0].landmarks.isNotEmpty) {
        rightHand = results[0].landmarks;
      }
    } else if (results.length >= 2) {
      final handA = results[0];
      final handB = results[1];
      if (handA.landmarks.isNotEmpty && handB.landmarks.isNotEmpty) {
        final double wristAX = handA.landmarks[0].x;
        final double wristBX = handB.landmarks[0].x;
        if (wristAX < wristBX) {
          rightHand = handA.landmarks;
          leftHand = handB.landmarks;
        } else {
          rightHand = handB.landmarks;
          leftHand = handA.landmarks;
        }
      }
    }

    return (left: leftHand, right: rightHand);
  }

  /// Membangun 126-feature vector dari dua tangan (kiri+kanan masing-masing 63).
  static List<double> buildInputFeatures(
      List<Landmark>? leftHand, List<Landmark>? rightHand) {
    _normalizeAndScaleInPlace(leftHand, 0);
    _normalizeAndScaleInPlace(rightHand, 63);
    return _inputBuffer;
  }
}
