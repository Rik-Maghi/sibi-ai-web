/// Layanan prediksi kata (autocomplete) Bahasa Indonesia untuk Papan Tulis SIBI.
/// Berjalan 100% offline dan lokal di dalam perangkat.
class WordPredictionService {
  // Kamus kata Bahasa Indonesia yang sering digunakan (terutama dalam konteks percakapan sehari-hari)
  static const List<String> _indonesianDictionary = [
    'saya', 'kamu', 'dia', 'mereka', 'kita', 'kami', 'anda',
    'makan', 'minum', 'belajar', 'tidur', 'pergi', 'datang', 'pulang', 'mandi',
    'bisa', 'boleh', 'harus', 'mau', 'ingin', 'suka', 'cinta', 'benci',
    'halo', 'hai', 'terima', 'kasih', 'sama-sama', 'maaf', 'tolong', 'bantu',
    'bahasa', 'isyarat', 'indonesia', 'sibi', 'aplikasi', 'kamera', 'penerjemah',
    'siapa', 'apa', 'kapan', 'dimana', 'mengapa', 'bagaimana', 'berapa',
    'ya', 'tidak', 'belum', 'sudah', 'sedang', 'akan', 'pernah', 'selalu',
    'hebat', 'pintar', 'bagus', 'baik', 'buruk', 'salah', 'benar', 'cantik', 'ganteng',
    'buku', 'sekolah', 'kampus', 'guru', 'dosen', 'teman', 'sahabat', 'keluarga',
    'ayah', 'ibu', 'kakak', 'adik', 'anak', 'orang', 'masyarakat',
    'satu', 'dua', 'tiga', 'empat', 'lima', 'enam', 'tujuh', 'delapan', 'sembilan', 'sepuluh',
    'hari', 'besok', 'kemarin', 'sekarang', 'nanti', 'pagi', 'siang', 'sore', 'malam',
    'rumah', 'jalan', 'kota', 'desa', 'negara', 'dunia',
    'kerja', 'main', 'nonton', 'dengar', 'baca', 'tulis', 'gambar', 'nyanyi',
    'senang', 'sedih', 'marah', 'takut', 'terkejut', 'bosan', 'lelah', 'capek',
    'sehat', 'sakit', 'dokter', 'obat', 'rumah-sakit',
    'baru', 'lama', 'cepat', 'lambat', 'besar', 'kecil', 'tinggi', 'rendah', 'jauh', 'dekat',
    'banyak', 'sedikit', 'semua', 'sebagian', 'kosong', 'penuh'
  ];

  /// Mengambil rekomendasi kata berdasarkan teks yang sedang diketik saat ini.
  /// Mencari prefiks dari kata terakhir yang sedang disusun.
  static List<String> getPredictions(String currentText) {
    if (currentText.isEmpty) return [];

    // Jika karakter terakhir adalah spasi, artinya kata sebelumnya sudah selesai,
    // kita tidak menampilkan rekomendasi untuk kata baru (atau bisa dikembangkan ke next-word prediction)
    if (currentText.endsWith(' ')) return [];

    // Mengambil kata terakhir yang sedang diketik
    final words = currentText.split(' ');
    final lastWord = words.last.toLowerCase();

    if (lastWord.isEmpty) return [];

    // Filter kamus yang berawalan dengan kata terakhir
    final matches = _indonesianDictionary
        .where((word) => word.startsWith(lastWord) && word != lastWord)
        .toList();

    // Urutkan berdasarkan panjang kata (yang terpendek dulu agar prediksi lebih intuitif)
    matches.sort((a, b) => a.length.compareTo(b.length));

    // Kembalikan maksimal 4 rekomendasi teratas
    return matches.take(4).toList();
  }

  /// Melengkapi kata terakhir dalam kalimat dengan kata rekomendasi pilihan.
  static String completeWord(String currentText, String prediction) {
    if (currentText.isEmpty) return '${prediction.toUpperCase()} ';

    final words = currentText.split(' ');
    if (words.isEmpty) return '${prediction.toUpperCase()} ';

    // Hapus kata terakhir yang belum lengkap
    words.removeLast();

    // Tambahkan kata hasil prediksi (dikonversi ke uppercase agar konsisten dengan output huruf SIBI)
    words.add(prediction.toUpperCase());

    // Gabungkan kembali dengan spasi di ujungnya untuk bersiap ke kata berikutnya
    return '${words.join(' ')} ';
  }
}
