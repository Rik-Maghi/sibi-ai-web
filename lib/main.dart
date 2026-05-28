import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_fonts/google_fonts.dart';

import 'dashboard_layout.dart';

List<CameraDescription>? cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    cameras = await availableCameras();
  } catch (e) {
    debugPrint("Failed to get cameras: $e");
  }

  runApp(const SibiApp());
}

// ====== ROOT APP ======
class SibiApp extends StatelessWidget {
  const SibiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SIBI Translator AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.blueAccent,
        scaffoldBackgroundColor: const Color(0xFF0D1117),
        colorScheme: ColorScheme.dark(
          primary: Colors.blueAccent,
          secondary: Colors.purpleAccent,
          surface: const Color(0xFF161B22),
        ),
        textTheme: GoogleFonts.interTextTheme(
          ThemeData.dark().textTheme,
        ),
        // NavigationBar dark theme — prevents M3 defaults from clashing
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFF0F172A),
          indicatorColor: Colors.blueAccent.withValues(alpha: 0.18),
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final bool selected = states.contains(WidgetState.selected);
            return TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              color: selected ? Colors.white : Colors.white38,
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            final bool selected = states.contains(WidgetState.selected);
            return IconThemeData(
              size: 24,
              color: selected ? Colors.blueAccent : Colors.white38,
            );
          }),
        ),
      ),
      home: const WelcomeScreen(),
    );
  }
}

// ====== WELCOME SCREEN ======
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _navigateToDashboard(BuildContext context) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (ctx, animation, _) =>
            DashboardLayout(cameras: cameras ?? []),
        transitionsBuilder: (ctx, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: Stack(
        children: [
          // Background glow decorations
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.blueAccent.withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -120,
            right: -80,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.purpleAccent.withValues(alpha: 0.10),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Main Content
          Center(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ── Logo Badge ──
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Colors.blueAccent.withValues(alpha: 0.25),
                              Colors.purpleAccent.withValues(alpha: 0.15),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(
                            color: Colors.blueAccent.withValues(alpha: 0.4),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blueAccent.withValues(alpha: 0.2),
                              blurRadius: 40,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.sign_language,
                            size: 72, color: Colors.blueAccent),
                      ),
                      const SizedBox(height: 28),

                      // ── App Name ──
                      const Text(
                        "SIBI Translator AI",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 38,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // ── Tagline ──
                      Text(
                        "Penerjemah Bahasa Isyarat Indonesia berbasis Edge AI",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Badges Row ──
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        alignment: WrapAlignment.center,
                        children: [
                          _buildBadge(
                              Icons.offline_bolt, "100% Offline", Colors.greenAccent),
                          _buildBadge(
                              Icons.memory, "Edge AI", Colors.blueAccent),
                          if (kIsWeb)
                            _buildBadge(
                                Icons.public, "Web Demo", Colors.orangeAccent),
                        ],
                      ),
                      const SizedBox(height: 56),

                      // ── Platform Notice (Web Only) ──
                      if (kIsWeb) ...[
                        Container(
                          constraints: const BoxConstraints(maxWidth: 520),
                          padding: const EdgeInsets.all(20),
                          margin: const EdgeInsets.only(bottom: 32),
                          decoration: BoxDecoration(
                            color: Colors.orangeAccent.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.orangeAccent.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline,
                                  color: Colors.orangeAccent, size: 28),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  "Anda membuka Web Demo 🌐. Fitur kamera real-time digantikan oleh Simulator Panel interaktif agar Anda dapat mencoba semua fitur SIBI langsung di browser!",
                                  style: TextStyle(
                                    color: Colors.orange.shade200,
                                    fontSize: 13,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // ── Device Cards ──
                      Text(
                        kIsWeb ? "Mulai demo sekarang:" : "Pilih platform Anda:",
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 13,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 20,
                        runSpacing: 20,
                        alignment: WrapAlignment.center,
                        children: kIsWeb
                            ? [
                                _DeviceCard(
                                  title: "Coba Demo Web",
                                  subtitle: "Simulator A-Z Interaktif",
                                  icon: Icons.web,
                                  color: Colors.orangeAccent,
                                  badge: "🌐 Web Demo",
                                  onTap: () => _navigateToDashboard(context),
                                ),
                              ]
                            : [
                                _DeviceCard(
                                  title: "Mobile",
                                  subtitle: "Android / iOS",
                                  icon: Icons.smartphone,
                                  color: Colors.greenAccent,
                                  badge: "📱 Kamera AI",
                                  onTap: () => _navigateToDashboard(context),
                                ),
                                _DeviceCard(
                                  title: "Desktop",
                                  subtitle: "Windows / macOS",
                                  icon: Icons.laptop_mac,
                                  color: Colors.blueAccent,
                                  badge: "💻 Full Mode",
                                  onTap: () => _navigateToDashboard(context),
                                ),
                              ],
                      ),
                      const SizedBox(height: 56),

                      // ── Feature Highlights ──
                      Container(
                        constraints: const BoxConstraints(maxWidth: 520),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF161B22),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Fitur Utama",
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildFeatureRow("🎥", "Kamera Penerjemah", "Deteksi gestur tangan real-time dengan AI"),
                            const SizedBox(height: 12),
                            _buildFeatureRow("📚", "Kamus SIBI A-Z", "Panduan lengkap isyarat setiap huruf"),
                            const SizedBox(height: 12),
                            _buildFeatureRow("🎮", "Mode Latihan", "Quiz gamifikasi dengan skor & streak"),
                            const SizedBox(height: 12),
                            _buildFeatureRow("📝", "Papan Tulis", "Rangkai huruf menjadi kalimat utuh"),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // ── Footer ──
                      Text(
                        "Built with Flutter & TensorFlow Lite  •  Edge AI • 100% Offline",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.18),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(String emoji, String title, String subtitle) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45), fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}

// ====== DEVICE CARD ======
class _DeviceCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final String badge;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _DeviceCard({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<_DeviceCard> createState() => _DeviceCardState();
}

class _DeviceCardState extends State<_DeviceCard> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: 200,
          height: 230,
          decoration: BoxDecoration(
            color: _isHovering
                ? widget.color.withValues(alpha: 0.08)
                : const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isHovering
                  ? widget.color
                  : widget.color.withValues(alpha: 0.25),
              width: _isHovering ? 2 : 1.5,
            ),
            boxShadow: _isHovering
                ? [
                    BoxShadow(
                        color: widget.color.withValues(alpha: 0.25),
                        blurRadius: 24,
                        spreadRadius: 2)
                  ]
                : [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3), blurRadius: 10)
                  ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: _isHovering ? 1.1 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Icon(widget.icon, size: 60, color: widget.color),
              ),
              const SizedBox(height: 16),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                widget.subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45), fontSize: 12),
              ),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.badge,
                  style: TextStyle(
                      color: widget.color,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
