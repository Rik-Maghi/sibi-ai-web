import 'package:flutter/material.dart';
import '../services/tts_service.dart';

class DictionaryScreen extends StatefulWidget {
  final TtsService ttsService;

  const DictionaryScreen({super.key, required this.ttsService});

  @override
  State<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends State<DictionaryScreen> {
  String? _selectedLetter;

  final List<String> _alphabet = [
    ...List.generate(26, (i) => String.fromCharCode(i + 65)),
    'SPASI',
    'HAPUS',
    'SELESAI',
  ];

  // Deskripsi singkat isyarat SIBI untuk setiap huruf
  final Map<String, String> _descriptions = {
    'A': 'Kepal tangan, jempol menempel di samping telunjuk.',
    'B': 'Empat jari lurus rapat ke atas, jempol melipat ke telapak.',
    'C': 'Tangan membentuk huruf C, jari melengkung ke dalam.',
    'D': 'Telunjuk lurus ke atas, jari lainnya dan jempol membentuk lingkaran.',
    'E': 'Semua jari melengkung ke dalam, ujung jari menyentuh telapak.',
    'F': 'Telunjuk dan jempol membentuk lingkaran, tiga jari lainnya lurus.',
    'G': 'Telunjuk menunjuk ke samping, jempol sejajar di bawah.',
    'H': 'Telunjuk dan jari tengah lurus ke samping, sejajar rapat.',
    'I': 'Kepal tangan, kelingking lurus ke atas.',
    'J': 'Kelingking lurus, kemudian gambarkan huruf J di udara.',
    'K': 'Telunjuk lurus ke atas, jari tengah miring, jempol di antara keduanya.',
    'L': 'Telunjuk lurus ke atas, jempol lurus ke samping membentuk L.',
    'M': 'Tiga jari (telunjuk, tengah, manis) menutupi jempol di bawah.',
    'N': 'Dua jari (telunjuk, tengah) menutupi jempol di bawah.',
    'O': 'Semua jari melengkung bertemu dengan jempol membentuk O.',
    'P': 'Seperti huruf K tapi tangan menghadap ke bawah.',
    'Q': 'Seperti huruf G tapi tangan menghadap ke bawah.',
    'R': 'Telunjuk dan jari tengah saling menyilang ke atas.',
    'S': 'Kepal tangan, jempol menutupi jari-jari dari depan.',
    'T': 'Kepal tangan, jempol masuk di antara telunjuk dan jari tengah.',
    'U': 'Telunjuk dan jari tengah lurus rapat ke atas.',
    'V': 'Telunjuk dan jari tengah lurus terbuka membentuk V.',
    'W': 'Telunjuk, jari tengah, dan manis lurus terbuka ke atas.',
    'X': 'Telunjuk ditekuk membentuk kait (hook).',
    'Y': 'Jempol dan kelingking lurus, jari lainnya dilipat.',
    'Z': 'Telunjuk lurus, gambarkan huruf Z di udara.',
    'SPASI': 'Mengayunkan tangan ke arah kanan atau merapatkan dan membuka jari-jari.',
    'HAPUS': 'Mengibaskan tangan di depan dada seolah menghapus sesuatu.',
    'SELESAI': 'Kedua tangan terbuka, telapak menghadap ke bawah, lalu diayunkan menyilang.',
  };

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
                Icon(Icons.book, color: Colors.orangeAccent, size: 28),
                SizedBox(width: 12),
                Text("Kamus SIBI (A - Z)", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ====== INFO BANNER ======
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blueAccent),
                SizedBox(width: 12),
                Expanded(child: Text(
                  "Ketuk salah satu huruf di bawah untuk melihat deskripsi isyarat SIBI.",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                )),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ====== GRID A-Z ======
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                int crossAxisCount = (constraints.maxWidth / 110).floor().clamp(3, 8);
                return GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _alphabet.length,
                  itemBuilder: (context, index) {
                    String letter = _alphabet[index];
                    bool isSelected = _selectedLetter == letter;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedLetter = isSelected ? null : letter;
                        });
                        if (!isSelected) {
                          widget.ttsService.speak("Huruf $letter. ${_descriptions[letter]}");
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.blueAccent.withValues(alpha: 0.25) : const Color(0xFF334155),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? Colors.blueAccent : Colors.white12,
                            width: isSelected ? 2.5 : 1,
                          ),
                          boxShadow: isSelected ? [
                            BoxShadow(color: Colors.blueAccent.withValues(alpha: 0.15), blurRadius: 12, spreadRadius: 2),
                          ] : [],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.black26,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Image.asset(
                                'assets/images/letter_${letter.toLowerCase()}.jpg',
                                width: 36,
                                height: 36,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.sign_language,
                                    color: isSelected ? Colors.blueAccent : Colors.white54,
                                    size: 36,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              letter,
                              style: TextStyle(
                                color: isSelected ? Colors.blueAccent : Colors.white,
                                fontSize: letter.length > 1 ? 11 : 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // ====== DETAIL PANEL ======
          if (_selectedLetter != null) ...[
            const SizedBox(height: 12),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF334155),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blueAccent),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        'assets/images/letter_${_selectedLetter!.toLowerCase()}.jpg',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Text(
                              _selectedLetter!,
                              style: const TextStyle(color: Colors.blueAccent, fontSize: 48, fontWeight: FontWeight.bold),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Isyarat Huruf $_selectedLetter",
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _descriptions[_selectedLetter!] ?? "Deskripsi belum tersedia.",
                          style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
