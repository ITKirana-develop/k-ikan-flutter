import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'home_screen.dart' show KColors;

/// Splash screen animasi (logo scale + fade + jeda sebentar) yang tampil
/// sebelum masuk ke layar login/WebView. Dipasang sebagai `home:` di
/// MaterialApp, menggantikan langsung lempar ke WebViewScreen.
///
/// Cara pakai di main.dart:
///
///   home: SplashScreen(
///     nextScreenBuilder: (context) => const WebViewScreen(
///       title: 'Login',
///       url: 'http://127.0.0.1:8000/login',
///     ),
///   ),
class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    required this.nextScreenBuilder,
    this.logoAsset = 'assets/icon/logo.png',
    this.appName,
    this.minDisplayDuration = const Duration(milliseconds: 3200),
  });

  /// Builder layar tujuan setelah splash selesai (biasanya WebViewScreen
  /// yang me-load halaman login Laravel, atau HomeScreen kalau session
  /// masih aktif — logic pengecekan itu bisa ditaruh di dalam builder ini).
  final WidgetBuilder nextScreenBuilder;

  /// Path asset logo, harus sudah didaftarkan di pubspec.yaml -> assets:.
  final String logoAsset;

  /// Nama aplikasi opsional yang ditampilkan di bawah logo. Kalau null,
  /// hanya logo yang tampil.
  final String? appName;

  /// Total waktu minimum splash tampil sebelum pindah layar (termasuk
  /// waktu animasi). Dibikin minimum, bukan fixed, supaya kalau nanti
  /// ditambah pengecekan session/loading data, splash tidak "berkedip"
  /// kalau proses itu ternyata lebih cepat dari animasinya.
  final Duration minDisplayDuration;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;
  late final Animation<Offset> _nameSlide;
  late final Animation<double> _nameOpacity;

  // Controller kedua yang loop terus-menerus (dipakai untuk glow yang
  // "berdenyut" di belakang logo dan titik loading di bawah).
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Logo mulai agak kecil lalu "melenting" sedikit melewati ukuran
    // normal sebelum settle di scale 1.0 — kesan hidup, tidak kaku.
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.72, end: 1.06)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 70,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.06, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
    ]).animate(_controller);

    _opacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    // Nama app menyusul sedikit belakangan: fade + geser naik tipis.
    _nameOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.45, 1.0, curve: Curves.easeOut),
    );
    _nameSlide = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.45, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _controller.forward();

    // PENTING: jangan mulai hitung mundur navigasi langsung di sini.
    // Di device/emulator yang lagi berat (banyak frame di-skip saat
    // startup), Future.delayed jalan berdasarkan jam sistem — bisa saja
    // durasinya sudah habis SEBELUM frame pertama splash ini sempat
    // benar-benar digambar ke layar, jadi user langsung lompat ke layar
    // berikutnya tanpa pernah melihat splash-nya sama sekali. Dengan
    // addPostFrameCallback, hitung mundur baru mulai setelah splash
    // dipastikan sudah ter-render minimal satu frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduleNavigation();
    });
  }

  Future<void> _scheduleNavigation() async {
    await Future.delayed(widget.minDisplayDuration);
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (context, animation, secondaryAnimation) =>
            widget.nextScreenBuilder(context),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: KColors.primary,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [KColors.primary, KColors.primaryGradientEnd],
            ),
          ),
          child: Stack(
            children: [
              // lingkaran dekoratif blur, senada gaya header di layar lain
              Positioned(
                right: -60,
                top: -70,
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    color: KColors.headerGlowSoft,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                left: -50,
                bottom: -60,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Center(
                child: AnimatedBuilder(
                  animation: Listenable.merge([_controller, _pulseController]),
                  builder: (context, child) {
                    final pulse = 1.0 + (_pulseController.value * 0.10);
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Opacity(
                          opacity: _opacity.value,
                          child: Transform.scale(
                            scale: _scale.value,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // glow yang berdenyut pelan di belakang logo — dibikin lebih pekat
                                // supaya logo lebih kontras dari background gradient
                                Transform.scale(
                                  scale: pulse,
                                  child: Container(
                                    width: 190,
                                    height: 190,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withValues(
                                        alpha: 0.40 - (_pulseController.value * 0.14),
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 118,
                                  height: 118,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withValues(alpha: 0.18),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.20),
                                        blurRadius: 26,
                                        offset: const Offset(0, 12),
                                      ),
                                    ],
                                  ),
                                  child: Image.asset(
                                    widget.logoAsset,
                                    width: 118,
                                    height: 118,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (widget.appName != null) ...[
                          const SizedBox(height: 24),
                          SlideTransition(
                            position: _nameSlide,
                            child: FadeTransition(
                              opacity: _nameOpacity,
                              child: Text(
                                widget.appName!,
                                style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
              // titik loading kecil di bagian bawah, menandakan proses masih berjalan
              Positioned(
                left: 0,
                right: 0,
                bottom: 56,
                child: FadeTransition(
                  opacity: _nameOpacity,
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, _) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (i) {
                          final t = (_pulseController.value - (i * 0.2)) % 1.0;
                          final scale = 0.6 +
                              (0.4 *
                                  (1 - (t - 0.5).abs() * 2)
                                      .clamp(0.0, 1.0)
                                      .toDouble());
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            child: Transform.scale(
                              scale: scale,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          );
                        }),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}