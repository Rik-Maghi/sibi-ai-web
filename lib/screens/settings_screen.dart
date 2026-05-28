import 'package:flutter/material.dart';
import '../services/tts_service.dart';

class SettingsScreen extends StatefulWidget {
  final double ttsSpeed;
  final double confidenceThreshold;
  final ValueChanged<double> onTtsSpeedChanged;
  final ValueChanged<double> onConfidenceThresholdChanged;
  final TtsService ttsService;
  final String teamName;
  final String universityName;
  final ValueChanged<String> onTeamNameChanged;
  final ValueChanged<String> onUniversityNameChanged;

  const SettingsScreen({
    super.key,
    required this.ttsSpeed,
    required this.confidenceThreshold,
    required this.onTtsSpeedChanged,
    required this.onConfidenceThresholdChanged,
    required this.ttsService,
    required this.teamName,
    required this.universityName,
    required this.onTeamNameChanged,
    required this.onUniversityNameChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _teamController;
  late TextEditingController _univController;

  @override
  void initState() {
    super.initState();
    _teamController = TextEditingController(text: widget.teamName);
    _univController = TextEditingController(text: widget.universityName);
  }

  @override
  void dispose() {
    _teamController.dispose();
    _univController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
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
                  Icon(Icons.settings, color: Colors.grey, size: 28),
                  SizedBox(width: 12),
                  Text("Tentang & Pengaturan", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ====== EDGE AI BADGE ======
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blueAccent.shade700, Colors.deepPurple.shade800],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.blueAccent.withValues(alpha: 0.2), blurRadius: 20, spreadRadius: 2),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.offline_bolt, color: Colors.greenAccent, size: 40),
                      ),
                      const SizedBox(width: 20),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Edge AI — 100% Offline", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                            SizedBox(height: 4),
                            Text(
                              "Tidak membutuhkan koneksi internet",
                              style: TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      "Aplikasi ini menggunakan model Machine Learning TFLite yang berjalan sepenuhnya di perangkat Anda (On-Device AI). "
                      "Semua pemrosesan deteksi tangan dan klasifikasi bahasa isyarat SIBI dilakukan secara lokal tanpa mengirim data ke server manapun. "
                      "Privasi Anda 100% terjaga dan aplikasi ini dapat digunakan di mana saja — bahkan tanpa sinyal.",
                      style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ====== TECH STACK ======
            _buildSectionTitle("Teknologi yang Digunakan"),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF334155),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildTechRow(Icons.flutter_dash, "Flutter", "Framework UI Cross-Platform", Colors.cyanAccent),
                  const Divider(color: Colors.white12, height: 24),
                  _buildTechRow(Icons.memory, "TensorFlow Lite", "Model Inferensi On-Device", Colors.orangeAccent),
                  const Divider(color: Colors.white12, height: 24),
                  _buildTechRow(Icons.back_hand, "MediaPipe", "Deteksi Hand Landmark (21 titik)", Colors.greenAccent),
                  const Divider(color: Colors.white12, height: 24),
                  _buildTechRow(Icons.record_voice_over, "Flutter TTS", "Text-to-Speech Offline", Colors.purpleAccent),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ====== PENGATURAN TTS ======
            _buildSectionTitle("Pengaturan Suara (TTS)"),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
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
                      const Text("Kecepatan Bicara", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.ttsSpeed <= 0.3 ? "Lambat" : widget.ttsSpeed <= 0.6 ? "Normal" : "Cepat",
                          style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: Colors.blueAccent,
                      inactiveTrackColor: Colors.white12,
                      thumbColor: Colors.blueAccent,
                      overlayColor: Colors.blueAccent.withValues(alpha: 0.2),
                    ),
                    child: Slider(
                      value: widget.ttsSpeed,
                      min: 0.1,
                      max: 1.0,
                      divisions: 9,
                      label: widget.ttsSpeed.toStringAsFixed(1),
                      onChanged: (value) {
                        widget.onTtsSpeedChanged(value);
                      },
                    ),
                  ),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("0.1 (Lambat)", style: TextStyle(color: Colors.white38, fontSize: 12)),
                      Text("1.0 (Cepat)", style: TextStyle(color: Colors.white38, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      widget.ttsService.speak("Halo, saya siap menerjemahkan Bahasa Isyarat Indonesia!");
                    },
                    icon: const Icon(Icons.volume_up, size: 20),
                    label: const Text("Uji Coba Suara"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent.withValues(alpha: 0.12),
                      foregroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: Colors.blueAccent, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ====== PENGATURAN THRESHOLD ======
            _buildSectionTitle("Pengaturan Model AI"),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
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
                      const Text("Confidence Threshold", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "${(widget.confidenceThreshold * 100).toStringAsFixed(0)}%",
                          style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Semakin tinggi, semakin akurat tapi semakin sulit model mendeteksi.",
                    style: TextStyle(color: Colors.white38, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: Colors.greenAccent,
                      inactiveTrackColor: Colors.white12,
                      thumbColor: Colors.greenAccent,
                      overlayColor: Colors.greenAccent.withValues(alpha: 0.2),
                    ),
                    child: Slider(
                      value: widget.confidenceThreshold,
                      min: 0.50,
                      max: 0.95,
                      divisions: 9,
                      label: "${(widget.confidenceThreshold * 100).toStringAsFixed(0)}%",
                      onChanged: (value) {
                        widget.onConfidenceThresholdChanged(value);
                      },
                    ),
                  ),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("50% (Sensitif)", style: TextStyle(color: Colors.white38, fontSize: 12)),
                      Text("95% (Ketat)", style: TextStyle(color: Colors.white38, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ====== TENTANG TIM ======
            _buildSectionTitle("Tentang Tim"),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF334155),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("SIBI Translator AI", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text("Versi 1.0.0", style: TextStyle(color: Colors.white38, fontSize: 13)),
                  const SizedBox(height: 16),
                  const Text(
                    "Aplikasi penerjemah bahasa isyarat SIBI (Sistem Isyarat Bahasa Indonesia) "
                    "berbasis Edge AI yang berjalan 100% offline menggunakan kamera smartphone.\n\n"
                    "Dibuat untuk Kompetisi Inovasi IT Bootcamp.",
                    style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.6),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _teamController,
                    decoration: InputDecoration(
                      labelText: "Nama Tim",
                      labelStyle: const TextStyle(color: Colors.blueAccent),
                      prefixIcon: const Icon(Icons.group, color: Colors.blueAccent),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.blueAccent),
                      ),
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                    ),
                    style: const TextStyle(color: Colors.white),
                    onChanged: widget.onTeamNameChanged,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _univController,
                    decoration: InputDecoration(
                      labelText: "Universitas / Instansi",
                      labelStyle: const TextStyle(color: Colors.blueAccent),
                      prefixIcon: const Icon(Icons.school, color: Colors.blueAccent),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.blueAccent),
                      ),
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                    ),
                    style: const TextStyle(color: Colors.white),
                    onChanged: widget.onUniversityNameChanged,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ====== FOOTER ======
            Center(
              child: Text(
                "Built with ❤️ using Flutter & TensorFlow Lite",
                style: TextStyle(color: Colors.white24, fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 1),
    );
  }

  Widget _buildTechRow(IconData icon, String name, String desc, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(desc, style: const TextStyle(color: Colors.white54, fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }
}
