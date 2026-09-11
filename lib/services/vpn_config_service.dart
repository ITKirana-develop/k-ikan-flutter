import 'package:shared_preferences/shared_preferences.dart';

/// Menyimpan konfigurasi WireGuard yang diisi user lewat halaman
/// "Pengaturan VPN" (VpnMenuScreen), supaya tidak perlu hardcode &
/// rebuild APK tiap kali ganti device / endpoint server kantor.
///
/// Butuh package `shared_preferences` — tambahkan di pubspec.yaml:
///   shared_preferences: ^2.3.0
class VpnConfigService {
  VpnConfigService._();
  static final VpnConfigService instance = VpnConfigService._();

  static const _kPrivateKey = 'vpn_private_key';
  static const _kAddress = 'vpn_address';
  static const _kPublicKey = 'vpn_public_key';
  static const _kEndpoint = 'vpn_endpoint';
  static const _kDns = 'vpn_dns';
  static const _kAllowedIps = 'vpn_allowed_ips';
  static const _kKeepalive = 'vpn_keepalive';

  /// Ambil config yang tersimpan. Return null kalau belum pernah diisi
  /// (field wajib masih kosong) — dipakai UI buat tahu kapan harus
  /// mengarahkan user ke halaman Settings dulu sebelum bisa connect.
  Future<VpnConfigData?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final privateKey = prefs.getString(_kPrivateKey);
    final address = prefs.getString(_kAddress);
    final publicKey = prefs.getString(_kPublicKey);
    final endpoint = prefs.getString(_kEndpoint);

    final belumLengkap = [privateKey, address, publicKey, endpoint]
        .any((v) => v == null || v.trim().isEmpty);
    if (belumLengkap) return null;

    return VpnConfigData(
      privateKey: privateKey!,
      address: address!,
      publicKey: publicKey!,
      endpoint: endpoint!,
      dns: prefs.getString(_kDns) ?? '1.1.1.1',
      allowedIps: prefs.getString(_kAllowedIps) ?? '0.0.0.0/0',
      persistentKeepalive: prefs.getInt(_kKeepalive) ?? 25,
    );
  }

  Future<void> save(VpnConfigData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPrivateKey, data.privateKey.trim());
    await prefs.setString(_kAddress, data.address.trim());
    await prefs.setString(_kPublicKey, data.publicKey.trim());
    await prefs.setString(_kEndpoint, data.endpoint.trim());
    await prefs.setString(_kDns, data.dns.trim());
    await prefs.setString(_kAllowedIps, data.allowedIps.trim());
    await prefs.setInt(_kKeepalive, data.persistentKeepalive);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in [
      _kPrivateKey,
      _kAddress,
      _kPublicKey,
      _kEndpoint,
      _kDns,
      _kAllowedIps,
      _kKeepalive,
    ]) {
      await prefs.remove(key);
    }
  }
}

/// Nilai config WireGuard, dipetakan langsung dari isian form Settings.
class VpnConfigData {
  VpnConfigData({
    required this.privateKey,
    required this.address,
    required this.publicKey,
    required this.endpoint,
    this.dns = '1.1.1.1',
    this.allowedIps = '0.0.0.0/0',
    this.persistentKeepalive = 25,
  });

  final String privateKey;
  final String address;
  final String publicKey;
  final String endpoint;
  final String dns;
  final String allowedIps;
  final int persistentKeepalive;

  /// Dipakai sebagai parameter `serverAddress` di wireguard_flutter.
  String get serverAddress => endpoint;

  /// Format wg-quick config lengkap, persis seperti file .conf dari IT.
  String toWgQuickConfig() {
    return '''
[Interface]
PrivateKey = $privateKey
Address = $address
DNS = $dns

[Peer]
PublicKey = $publicKey
AllowedIPs = $allowedIps
Endpoint = $endpoint
PersistentKeepalive = $persistentKeepalive
''';
  }
}
