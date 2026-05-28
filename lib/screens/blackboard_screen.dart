import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/word_prediction_service.dart';
import '../services/tts_service.dart';

class BlackboardScreen extends StatelessWidget {
  final String boardText;
  final VoidCallback onClear;
  final ValueChanged<String> onTextUpdate;
  /// Optional: jika diberikan, tombol "Ucapkan" akan aktif untuk membaca kalimat.
  final TtsService? ttsService;

  const BlackboardScreen({
    super.key,
    required this.boardText,
    required this.onClear,
    required this.onTextUpdate,
    this.ttsService,
  });

  @override
  Widget build(BuildContext context) {
    // Memisahkan karakter untuk tampilan blok
    List<String> chars = boardText.split('');
    // Mengambil prediksi kata berdasarkan teks saat ini
    List<String> predictions = WordPredictionService.getPredictions(boardText);

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
                Icon(Icons.edit_note, color: Colors.tealAccent, size: 28),
                SizedBox(width: 12),
                Text("Papan Tulis (Riwayat)", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ====== INFO BANNER ======
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.tealAccent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.tealAccent.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Colors.tealAccent),
                SizedBox(width: 12),
                Expanded(child: Text(
                  "Setiap huruf yang terdeteksi di Kamera Penerjemah akan otomatis ditampilkan di sini, membentuk sebuah kalimat.",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                )),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ====== WORD PREDICTION BAR ======
          if (predictions.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.tealAccent.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.tealAccent.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bolt, color: Colors.tealAccent, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    "Saran:",
                    style: TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 38,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: predictions.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final word = predictions[index];
                          return InputChip(
                            label: Text(
                              word.toUpperCase(),
                              style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold),
                            ),
                            backgroundColor: const Color(0xFF1E293B),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: Colors.tealAccent.withValues(alpha: 0.4)),
                            ),
                            onPressed: () {
                              final newText = WordPredictionService.completeWord(boardText, word);
                              onTextUpdate(newText);
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ====== BLACKBOARD AREA ======
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1A2332),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF334155), width: 2),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: boardText.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.draw, color: Colors.white12, size: 80),
                          SizedBox(height: 16),
                          Text(
                            "Papan tulis masih kosong.\nMulai peragakan isyarat di Kamera Penerjemah!",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white24, fontSize: 16, height: 1.5),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Tampilan Teks Utama (Kalimat)
                          Text(
                            boardText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                              height: 1.8,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Divider(color: Colors.white12),
                          const SizedBox(height: 16),

                          // Tampilan Blok Huruf
                          const Text("Detail Karakter:", style: TextStyle(color: Colors.white54, fontSize: 14)),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: chars.map((ch) {
                              bool isSpace = ch == ' ';
                              return Container(
                                width: isSpace ? 30 : 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: isSpace
                                      ? Colors.transparent
                                      : const Color(0xFF334155),
                                  borderRadius: BorderRadius.circular(8),
                                  border: isSpace
                                      ? Border.all(color: Colors.white12)
                                      : Border.all(
                                          color: Colors.tealAccent.withValues(alpha: 0.3)),
                                ),
                                child: Center(
                                  child: Text(
                                    isSpace ? '·' : ch,
                                    style: TextStyle(
                                      color: isSpace ? Colors.white24 : Colors.white,
                                      fontSize: isSpace ? 20 : 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),

          // ====== BOTTOM CONTROLS ======
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                // Jumlah Karakter
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF334155),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "${boardText.length} karakter",
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ),
                const Spacer(),

                // Ucapkan Kalimat
                if (ttsService != null)
                  ElevatedButton.icon(
                    onPressed: boardText.isEmpty
                        ? null
                        : () => ttsService!.speak(boardText),
                    icon: const Icon(Icons.volume_up, size: 20),
                    label: const Text("Ucapkan"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple.shade700,
                      foregroundColor: Colors.white,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                if (ttsService != null) const SizedBox(width: 8),

                // Salin Teks
                ElevatedButton.icon(
                  onPressed: boardText.isEmpty
                      ? null
                      : () {
                          Clipboard.setData(ClipboardData(text: boardText));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text("Teks berhasil disalin!"),
                              backgroundColor: Colors.tealAccent.shade700,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                  icon: const Icon(Icons.copy, size: 20),
                  label: const Text("Salin"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade700,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(width: 12),

                // Bersihkan Papan
                ElevatedButton.icon(
                  onPressed: boardText.isEmpty ? null : onClear,
                  icon: const Icon(Icons.delete_sweep, size: 20),
                  label: const Text("Bersihkan"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade800,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
