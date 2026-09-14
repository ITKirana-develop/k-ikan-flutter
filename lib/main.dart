import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'screen/home_screen.dart';
import 'screen/splash_screen.dart';
import 'config/app_config.dart';
import 'services/vpn_service.dart';
import 'screen/vpn_menu_screen.dart';

void main() {
  runApp(const KiraPatrolApp());
}

class KiraPatrolApp extends StatelessWidget {
  const KiraPatrolApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'K-IKAN',
      theme: ThemeData(useMaterial3: true),
      // Urutan: Splash (branding) -> VpnGate (nyambung VPN kalau di luar
      // kantor) -> LoginGateway (WebView login Laravel) -> HomeScreen.
      home: const SplashScreen(
        logoAsset: 'assets/icon/logo.png',
        appName: 'K-IKAN',
        nextScreenBuilder: _buildVpnGate,
      ),
    );
  }
}

Widget _buildVpnGate(BuildContext context) => const VpnGateScreen();

// ============================================================
// VPN GATE SCREEN
// ============================================================
// Layar sebelum WebView login. Kalau user lagi di LUAR jaringan kantor,
// dia belum bisa akses server sama sekali tanpa VPN nyala dulu -- jadi
// kalau langsung dilempar ke WebView login, dia tidak akan pernah sampai
// ke halaman itu, apalagi sampai ke Profile buat nyalain VPN-nya.
class VpnGateScreen extends StatefulWidget {
  const VpnGateScreen({super.key});

  @override
  State<VpnGateScreen> createState() => _VpnGateScreenState();
}

class _VpnGateScreenState extends State<VpnGateScreen> {
  VpnConnectionState _vpnState = VpnConnectionState.disconnected;
  StreamSubscription<VpnConnectionState>? _vpnSub;

  @override
  void initState() {
    super.initState();
    _initVpnStatus();
  }

  Future<void> _initVpnStatus() async {
    // Cek status sekarang dulu (mis. VPN masih nyala dari sesi
    // sebelumnya), biar posisi toggle langsung benar begitu layar dibuka.
    try {
      final connected = await VpnService.instance.isConnectedNow();
      if (mounted) {
        setState(() {
          _vpnState = connected
              ? VpnConnectionState.connected
              : VpnConnectionState.disconnected;
        });
      }
    } catch (_) {
      // Biarkan default disconnected kalau gagal cek.
    }

    _vpnSub = VpnService.instance.stateStream.listen((state) {
      if (mounted) setState(() => _vpnState = state);
    });
  }

  @override
  void dispose() {
    _vpnSub?.cancel();
    super.dispose();
  }

  Future<void> _onToggle(bool wantConnected) async {
    try {
      if (wantConnected) {
        await VpnService.instance.connect();
      } else {
        await VpnService.instance.disconnect();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('VPN gagal: $e')));
    }
  }

  void _continue() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginGatewayScreen()),
    );
  }

  bool get _isOn =>
      _vpnState == VpnConnectionState.connected ||
      _vpnState == VpnConnectionState.connecting;

  String get _statusLabel {
    switch (_vpnState) {
      case VpnConnectionState.connected:
        return 'Terhubung';
      case VpnConnectionState.connecting:
        return 'Menghubungkan...';
      case VpnConnectionState.error:
        return 'Gagal terhubung';
      case VpnConnectionState.disconnected:
        return 'Terputus';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
  backgroundColor: const Color(0xFF3230C4),
  appBar: AppBar(
    backgroundColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    actions: [
      IconButton(
        icon: const Icon(Icons.settings_rounded, color: Colors.white),
        tooltip: 'Pengaturan VPN',
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const VpnMenuScreen(),
            ),
          );
        },
      ),
    ],
  ),
  body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.vpn_lock_rounded, color: Colors.white, size: 56),
              const SizedBox(height: 20),
              const Text(
                'Sambungkan VPN KFI',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Nyalakan hanya jika tidak tersambung jaringan Internet PT. Kirana Food International',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _statusLabel,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Switch(
                      value: _isOn,
                      onChanged: _vpnState == VpnConnectionState.connecting
                          ? null
                          : _onToggle,
                      activeThumbColor: const Color(0xFF3230C4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _continue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF3230C4),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Lanjut',
                    style: TextStyle(fontWeight: FontWeight.w700),
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

// ============================================================
// LOGIN GATEWAY SCREEN
// ============================================================
// WebView yang me-load halaman login Laravel langsung. Begitu berhasil
// login (Laravel redirect ke halaman APAPUN selain /login -- landing
// page beda-beda tergantung role: superadmin -> /dashboard, security ->
// /patrol/menu, staff CSR -> /da/leave-permits, dst), otomatis pindah
// ke HomeScreen Flutter.
class LoginGatewayScreen extends StatefulWidget {
  const LoginGatewayScreen({super.key});

  @override
  State<LoginGatewayScreen> createState() => _LoginGatewayScreenState();
}

class _LoginGatewayScreenState extends State<LoginGatewayScreen> {
  late final WebViewController controller;
  bool _alreadyOpenedHome = false;

  @override
  void initState() {
    super.initState();

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            debugPrint('WEBVIEW START: $url');
          },

         onPageFinished: (url) {
  debugPrint('WEBVIEW FINISH: $url');

  final isLoginPage = url.contains('/login');

  if (!_alreadyOpenedHome && !isLoginPage) {
    _alreadyOpenedHome = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        ),
      );
    });
  }
},
          onWebResourceError: (error) {
            debugPrint('WEBVIEW ERROR: ${error.errorCode}');
            debugPrint('WEBVIEW ERROR DESC: ${error.description}');
            debugPrint('WEBVIEW ERROR URL: ${error.url}');
          },

          onNavigationRequest: (request) {
            debugPrint('WEBVIEW NAVIGATE: ${request.url}');
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse('${AppConfig.baseUrl}/login?mobile_app=1'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: WebViewWidget(controller: controller)),
    );
  }
}