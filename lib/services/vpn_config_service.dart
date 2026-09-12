import 'package:shared_preferences/shared_preferences.dart';

import 'vpn_service.dart';

/// Menyimpan data VPN yang sifatnya PER-DEVICE saja: Private Key hasil
/// generate di HP ini, Public Key pasangannya (buat dikirim ke IT), dan
/// Address yang dijatah IT untuk device ini.
///
/// Data server (Public Key Server, Endpoint, DNS, AllowedIPs,
/// Keepalive, MTU) TIDAK disimpan di sini — nilainya sama untuk semua
/// user, jadi diambil langsung dari VpnServerConfig (hardcode di kode).
///
/// Butuh package `shared_preferences` — tambahkan di pubspec.yaml:
///   shared_preferences: ^2.3.0
class VpnConfigService {
  VpnConfigService._();
  static final VpnConfigService instance = VpnConfigService._();

  static const _kPrivateKey = 'vpn_private_key';
  static const _kAddress = 'vpn_address';
  static const _kDevicePublicKey = 'vpn_device_public_key';

  /// Ambil config yang tersimpan. Return null kalau belum pernah diisi
  /// (field wajib masih kosong) — dipakai UI buat tahu kapan harus
  /// mengarahkan user ke halaman Settings dulu sebelum bisa connect.
  Future<VpnConfigData?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final privateKey = prefs.getString(_kPrivateKey);
    final address = prefs.getString(_kAddress);

    final belumLengkap = [
      privateKey,
      address,
    ].any((v) => v == null || v.trim().isEmpty);
    if (belumLengkap) return null;

    return VpnConfigData(
      privateKey: privateKey!,
      address: address!,
      devicePublicKey: prefs.getString(_kDevicePublicKey) ?? '',
    );
  }

  Future<void> save(VpnConfigData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPrivateKey, data.privateKey.trim());
    await prefs.setString(_kAddress, data.address.trim());
    await prefs.setString(_kDevicePublicKey, data.devicePublicKey.trim());
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in [_kPrivateKey, _kAddress, _kDevicePublicKey]) {
      await prefs.remove(key);
    }
  }
}

/// Data VPN per-device: Private Key & Public Key hasil generate di HP
/// ini, plus Address yang dijatah IT khusus untuk device ini.
class VpnConfigData {
  VpnConfigData({
    required this.privateKey,
    required this.address,
    this.devicePublicKey = '',
  });

  final String privateKey;
  final String address;
  final String devicePublicKey;

  /// Dipakai sebagai parameter `serverAddress` di wireguard_flutter.
  /// Server tujuan koneksi sama untuk semua user, jadi diambil dari
  /// VpnServerConfig, bukan dari data per-device.
  String get serverAddress => VpnServerConfig.endpoint;

  /// Format wg-quick config lengkap: bagian device (privateKey,
  /// address) digabung dengan bagian server yang di-hardcode lewat
  /// VpnServerConfig — persis seperti file .conf dari IT.
  String toWgQuickConfig() {
    final buffer = StringBuffer()
      ..writeln('[Interface]')
      ..writeln('PrivateKey = $privateKey')
      ..writeln('Address = $address')
      ..writeln('DNS = ${VpnServerConfig.dns}');

    buffer.writeln('MTU = ${VpnServerConfig.mtu}');

    buffer
      ..writeln()
      ..writeln('[Peer]')
      ..writeln('PublicKey = ${VpnServerConfig.publicKey}')
      ..writeln('AllowedIPs = ${VpnServerConfig.allowedIps}')
      ..writeln('Endpoint = ${VpnServerConfig.endpoint}')
      ..writeln('PersistentKeepalive = ${VpnServerConfig.persistentKeepalive}');

    return buffer.toString();
  }
}