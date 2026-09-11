import 'dart:async';

import 'package:wireguard_flutter_pro/wireguard_flutter_pro.dart';

import 'vpn_config_service.dart';

/// Konfigurasi VPN WireGuard sekarang diisi user lewat halaman
/// "Pengaturan VPN" (VpnMenuScreen) dan disimpan lokal lewat
/// VpnConfigService — bukan lagi hardcode di sini. Ini supaya tiap
/// device / environment bisa pakai config beda tanpa perlu rebuild APK.

/// Status koneksi VPN yang disederhanakan, dipakai oleh UI (mis. toggle
/// switch di halaman Profile) supaya tidak perlu tahu detail semua
/// kemungkinan VpnStage dari package wireguard_flutter.
enum VpnConnectionState {
  disconnected,
  connecting,
  connected,
  error,
}

/// Singleton pembungkus WireGuardFlutter.
class VpnService {
  VpnService._();
  static final VpnService instance = VpnService._();

  static const String _interfaceName = 'kikan_wg';

  final _wireguard = WireGuardFlutter.instance;
  bool _initialized = false;

  final StreamController<VpnConnectionState> _stateController =
      StreamController<VpnConnectionState>.broadcast();

  Stream<VpnConnectionState> get stateStream => _stateController.stream;

  VpnConnectionState _lastState = VpnConnectionState.disconnected;
  VpnConnectionState get lastState => _lastState;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;

    await _wireguard.initialize(interfaceName: _interfaceName);

    _wireguard.vpnStageSnapshot.listen((stage) {
      _lastState = _mapStage(stage);
      _stateController.add(_lastState);
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
      case VpnStage.disconnected:
      case VpnStage.exiting:
        return VpnConnectionState.disconnected;
      case VpnStage.denied:
      case VpnStage.noConnection:
        return VpnConnectionState.error;
      default:
        return VpnConnectionState.disconnected;
    }
  }

  /// Nyalakan VPN. Dipanggil saat toggle di-ON-kan.
  Future<void> connect() async {
    await _ensureInitialized();

    final config = await VpnConfigService.instance.load();
    if (config == null) {
      throw StateError(
        'Konfigurasi VPN belum diisi. Buka menu Pengaturan VPN dulu.',
      );
    }

    _lastState = VpnConnectionState.connecting;
    _stateController.add(_lastState);

    try {
      await _wireguard.startVpn(
        serverAddress: config.serverAddress,
        wgQuickConfig: config.toWgQuickConfig(),
        providerBundleIdentifier: 'com.kikan.kira_patrol_flutter',
      );
    } catch (e) {
      _lastState = VpnConnectionState.error;
      _stateController.add(_lastState);
      rethrow;
    }
  }

  /// Matikan VPN. Dipanggil saat toggle di-OFF-kan.
  Future<void> disconnect() async {
    await _ensureInitialized();
    await _wireguard.stopVpn();
  }

  /// Cek status koneksi saat ini.
  Future<bool> isConnectedNow() async {
    await _ensureInitialized();
    return _wireguard.isConnected();
  }
}