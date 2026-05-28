import 'package:flutter/material.dart';

class ClassificationScreen extends StatelessWidget {
  const ClassificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.bar_chart, color: Colors.greenAccent, size: 28),
                SizedBox(width: 12),
                Text("Hasil Klasifikasi Model",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Charts
          _buildCard(
            title: "Confusion Matrix",
            description: "Menunjukkan distribusi prediksi benar dan salah untuk setiap abjad isyarat tangan.",
            imagePath: "assets/images/confusion_matrix.png",
          ),
          const SizedBox(height: 16),
          _buildCard(
            title: "Kurva Pelatihan (Training Curves)",
            description: "Menunjukkan akurasi dan loss (tingkat error) selama proses pelatihan model AI.",
            imagePath: "assets/images/training_curves.png",
          ),
          const SizedBox(height: 16),
          _buildCard(
            title: "Skor F1 Per Kelas (Huruf)",
            description: "Mengevaluasi keseimbangan presisi dan recall untuk setiap huruf secara individual.",
            imagePath: "assets/images/f1_per_class.png",
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required String title, required String description, required String imagePath}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF334155),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(description, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 16),
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                imagePath,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text("Gambar visualisasi gagal dimuat.", style: TextStyle(color: Colors.redAccent)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
