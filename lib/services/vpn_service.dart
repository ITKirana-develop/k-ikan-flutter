import 'dart:async';

import 'package:wireguard_flutter_pro/wireguard_flutter_pro.dart';

import 'vpn_config_service.dart';

/// Konfigurasi WireGuard milik SERVER kantor — nilainya sama untuk
/// semua user/device, jadi di-hardcode di sini (bukan diisi manual
/// tiap user lewat form).
///
/// Beda dengan Private Key & Public Key device, yang harus UNIK per
/// HP dan karena itu tetap digenerate + disimpan lokal lewat
/// VpnConfigService — bukan di file ini.
///
/// GANTI nilai di bawah ini sesuai data dari tim IT (isi file .conf
/// yang mereka kasih). Kalau suatu saat server pindah / key di-rotate,
/// cukup ganti nilai di sini lalu build ulang APK — tidak perlu ubah
/// file lain.
class VpnServerConfig {
  VpnServerConfig._();

  /// PublicKey di bagian [Peer] pada file .conf dari IT.
  static const String publicKey = 'GANTI_DENGAN_PUBLIC_KEY_SERVER';

  /// Endpoint di bagian [Peer], format host:port.
  static const String endpoint = 'GANTI_DENGAN_ENDPOINT'; // mis. vpn.mykfin.com:51820

  /// DNS di bagian [Interface].
  static const String dns = '1.1.1.1';

  /// AllowedIPs di bagian [Peer].
  static const String allowedIps = '0.0.0.0/0';

  /// PersistentKeepalive di bagian [Peer], dalam detik.
  static const int persistentKeepalive = 25;

  /// MTU di bagian [Interface]. Isi null kalau IT tidak mencantumkan
  /// baris MTU (WireGuard pakai default 1420 sendiri).
  static const int mtu = 1420; // ganti sesuai .conf dari IT
}

/// Status koneksi VPN yang dipakai di seluruh UI (VpnGateScreen,
/// ProfileScreen, VpnMenuScreen). Sengaja disederhanakan jadi 4 nilai
/// saja supaya switch-case di UI tetap ringkas — mapping dari VpnStage
/// (native, lebih detail) dilakukan di dalam VpnService.
enum VpnConnectionState { disconnected, connecting, connected, error }

/// Wrapper singleton di atas package `wireguard_flutter`, dipakai semua
/// layar (VpnGateScreen, ProfileScreen, VpnMenuScreen) lewat
/// VpnService.instance supaya tidak ada state VPN yang tercecer.
class VpnService {
  VpnService._();
  static final VpnService instance = VpnService._();

  static const _interfaceName = 'kira_patrol_wg0';
  static const _providerBundleIdentifier =
      'com.kirapatrol.app.WireGuardExtension'; // sesuaikan dgn iOS bundle id

  final _wireguard = WireGuardFlutter.instance;

  bool _initialized = false;
  StreamSubscription<VpnStage>? _nativeSub;

  final _stateController = StreamController<VpnConnectionState>.broadcast();

  /// Stream status VPN yang sudah disederhanakan, dipakai UI lewat
  /// `VpnService.instance.stateStream.listen(...)`.
  Stream<VpnConnectionState> get stateStream => _stateController.stream;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await _wireguard.initialize(interfaceName: _interfaceName);
    _nativeSub = _wireguard.vpnStageSnapshot.listen((stage) {
      _stateController.add(_mapStage(stage));
    });
    _initialized = true;
  }

  VpnConnectionState _mapStage(VpnStage stage) {
    switch (stage) {
      case VpnStage.connected:
        return VpnConnectionState.connected;
      case VpnStage.connecting:
      case VpnStage.preparing:
      case VpnStage.authenticating:
      case VpnStage.waitingConnection:
      case VpnStage.reconnect:
        return VpnConnectionState.connecting;
      case VpnStage.disconnecting:
      case VpnStage.disconnected:
      case VpnStage.noConnection:
      case VpnStage.exiting:
        return VpnConnectionState.disconnected;
      case VpnStage.denied:
        return VpnConnectionState.error;
    }
  }

  /// Cek status VPN sekarang juga (dipanggil sekali waktu layar dibuka),
  /// tanpa perlu nunggu event dari stream.
  Future<bool> isConnectedNow() async {
    await _ensureInitialized();
    final stage = await _wireguard.stage();
    return stage == VpnStage.connected;
  }

  /// Sambungkan VPN pakai config yang tersimpan di VpnConfigService
  /// (Private Key + Address per-device, digabung dengan
  /// VpnServerConfig yang hardcode).
  Future<void> connect() async {
    final config = await VpnConfigService.instance.load();
    if (config == null) {
      throw StateError(
        'Konfigurasi VPN belum diisi. Buka Pengaturan VPN dulu.',
      );
    }

    await _ensureInitialized();
    _stateController.add(VpnConnectionState.connecting);
    try {
      await _wireguard.startVpn(
        serverAddress: config.serverAddress,
        wgQuickConfig: config.toWgQuickConfig(),
        providerBundleIdentifier: _providerBundleIdentifier,
      );
    } catch (e) {
      _stateController.add(VpnConnectionState.error);
      rethrow;
    }
  }

  Future<void> disconnect() async {
    await _ensureInitialized();
    await _wireguard.stopVpn();
  }

  /// Generate keypair WireGuard (X25519) langsung di device lewat
  /// fungsi native package wireguard_flutter_pro — private key tidak
  /// pernah keluar dari HP, cuma public key yang perlu dikirim ke tim
  /// IT untuk didaftarkan sebagai peer.
  Future<WireGuardKeyPair> generateKeyPair() {
    return _wireguard.generateKeyPair();
  }

  void dispose() {
    _nativeSub?.cancel();
    _stateController.close();
  }
}