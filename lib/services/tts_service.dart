import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// TTS Service terpusat yang mengoptimalkan suara untuk setiap platform.
/// - Android: Menggunakan Google TTS (suara Indonesia paling natural)
/// - Web: Menggunakan Web Speech API Chrome (otomatis pilih suara terbaik)
/// - Desktop: Menggunakan Windows/macOS built-in TTS
class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;
  double _speechRate = 0.45;
  double _pitch = 1.0;
  final double _volume = 1.0;

  FlutterTts get instance => _tts;

  // ─── Inisialisasi ────────────────────────────────────────────
  Future<void> init() async {
    if (_isInitialized) return;

    await _tts.setLanguage("id-ID");
    await _tts.setSpeechRate(_speechRate);
    await _tts.setVolume(_volume);
    await _tts.setPitch(_pitch);

    if (!kIsWeb) {
      // Di Android: Coba pilih suara Google paling natural
      try {
        final voices = await _tts.getVoices;
        if (voices is List) {
          // Cari suara Google Indonesia female (paling jernih untuk demo)
          final googleFemale = voices.firstWhere(
            (v) =>
                v is Map &&
                (v['name'] as String? ?? '').toLowerCase().contains('id') &&
                (v['name'] as String? ?? '').toLowerCase().contains('female'),
            orElse: () => null,
          );
          if (googleFemale != null && googleFemale is Map) {
            await _tts.setVoice({
              'name': googleFemale['name'] as String,
              'locale': 'id-ID',
            });
          }
        }
      } catch (_) {
        // Jika tidak bisa memilih suara spesifik, biarkan sistem yang memilih
      }
    } else {
      // Di Web (Chrome): Web Speech API otomatis memilih suara Google Indonesia
      // yang sangat natural — tidak perlu konfigurasi tambahan
    }

    _isInitialized = true;
  }

  // ─── Metode Berbicara (Smart Speaker) ───────────────────────
  /// Mengucapkan huruf dengan cara yang natural dan profesional.
  /// Contoh: "A" → "Huruf A", "SPASI" → "Spasi", "HAPUS" → "Hapus"
  Future<void> speakLetter(String label) async {
    if (!_isInitialized) await init();

    final String text;
    switch (label) {
      case 'SPASI':
        text = 'Spasi';
        break;
      case 'HAPUS':
        text = 'Hapus';
        break;
      case 'SELESAI':
        text = 'Selesai';
        break;
      default:
        // Untuk huruf A-Z, ucapkan "Huruf A" agar terdengar natural
        text = 'Huruf $label';
    }

    await _tts.stop();
    await _tts.speak(text);
  }

  /// Berbicara bebas (untuk feedback quiz, notifikasi, dll.)
  Future<void> speak(String text) async {
    if (!_isInitialized) await init();
    await _tts.stop();
    await _tts.speak(text);
  }

  /// Feedback positif untuk jawaban benar di Mode Latihan
  Future<void> speakCorrect(String letter) async {
    await speak('Hebat! Huruf $letter, benar!');
  }

  /// Atur kecepatan bicara (0.1 lambat – 1.0 cepat)
  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate;
    await _tts.setSpeechRate(rate);
  }

  /// Atur nada suara (0.5 rendah – 2.0 tinggi, default 1.0)
  Future<void> setPitch(double pitch) async {
    _pitch = pitch;
    await _tts.setPitch(pitch);
  }

  Future<void> stop() async => _tts.stop();

  double get speechRate => _speechRate;
  double get pitch => _pitch;
}
