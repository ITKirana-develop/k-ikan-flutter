import 'package:flutter/material.dart';
import 'screen/splash_screen.dart';
import 'screen/vpn_gate_screen.dart';

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
      theme: ThemeData(
        useMaterial3: true,
      ),
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