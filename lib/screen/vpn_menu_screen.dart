import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'home_screen.dart' show KColors;
import '../services/vpn_service.dart';
import '../services/vpn_config_service.dart';

/// Menu VPN berdiri sendiri: toggle on/off WireGuard + halaman
/// Pengaturan buat isi config server kantor secara manual (bukan
/// hardcode). Dibuat modular supaya nanti tinggal ditambahkan sebagai
/// satu item menu di HomeScreen / dashboard utama K-IKAN.
class VpnMenuScreen extends StatefulWidget {
  const VpnMenuScreen({super.key});

  @override
  State<VpnMenuScreen> createState() => _VpnMenuScreenState();
}

class _VpnMenuScreenState extends State<VpnMenuScreen> {
  VpnConnectionState _state = VpnConnectionState.disconnected;
  bool _busy = false;
  bool _configReady = false;

  @override
  void initState() {
    super.initState();
    _init();
    VpnService.instance.stateStream.listen((s) {
      if (!mounted) return;
      setState(() => _state = s);
    });
  }

  Future<void> _init() async {
    final connected = await VpnService.instance.isConnectedNow();
    final config = await VpnConfigService.instance.load();
    if (!mounted) return;
    setState(() {
      _state = connected
          ? VpnConnectionState.connected
          : VpnConnectionState.disconnected;
      _configReady = config != null;
    });
  }

  Future<void> _toggle(bool turnOn) async {
    if (turnOn && !_configReady) {
      _showSnack('Atur VPN terlebih dahulu sebelum menyambungkan.');
      await _openSettings();
      return;
    }

    setState(() => _busy = true);
    try {
      if (turnOn) {
        await VpnService.instance.connect();
      } else {
        await VpnService.instance.disconnect();
      }
    } catch (e) {
      _showSnack(
        'VPN gagal ${turnOn ? "tersambung" : "diputuskan"}. Silakan coba lagi.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _openSettings() async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const _VpnSettingsSheet(),
    );

    if (saved == true) {
      final config = await VpnConfigService.instance.load();
      if (!mounted) return;
      setState(() => _configReady = config != null);
      _showSnack('Konfigurasi VPN tersimpan.');
    }
  }

  String get _statusLabel {
    switch (_state) {
      case VpnConnectionState.connected:
        return 'Terhubung';
      case VpnConnectionState.connecting:
        return 'Menghubungkan...';
      case VpnConnectionState.error:
        return 'Terjadi kesalahan';
      case VpnConnectionState.disconnected:
        return 'Terputus';
    }
  }

  Color get _statusColor {
    switch (_state) {
      case VpnConnectionState.connected:
        return Colors.green;
      case VpnConnectionState.connecting:
        return Colors.orange;
      case VpnConnectionState.error:
        return Colors.red;
      case VpnConnectionState.disconnected:
        return KColors.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOn =
        _state == VpnConnectionState.connected ||
        _state == VpnConnectionState.connecting;

    return Scaffold(
      appBar: AppBar(
        title: const Text('VPN KFI'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            tooltip: 'Pengaturan VPN',
            onPressed: _openSettings,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: KColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: KColors.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isOn ? Icons.vpn_lock_rounded : Icons.lock_open_rounded,
                    color: _statusColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'VPN KFI',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _statusLabel,
                        style: TextStyle(
                          color: _statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                _busy || _state == VpnConnectionState.connecting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.4),
                      )
                    : Switch(
                        value: isOn,
                        activeThumbColor: KColors.primary,
                        onChanged: _busy ? null : _toggle,
                      ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (!_configReady)
            _NoticeCard(
              icon: Icons.info_outline_rounded,
              text:
                  'VPN belum diatur. Ketuk ikon pengaturan di pojok kanan atas',
              onTap: _openSettings,
            ),
        ],
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({
    required this.icon,
    required this.text,
    required this.onTap,
  });

  final IconData icon;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.orange.shade800, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(fontSize: 13, color: Colors.orange.shade900),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.orange.shade800),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet form untuk mengisi config WireGuard dari data yang
/// diberikan tim IT, disimpan lewat VpnConfigService (bukan hardcode).
class _VpnSettingsSheet extends StatefulWidget {
  const _VpnSettingsSheet();

  @override
  State<_VpnSettingsSheet> createState() => _VpnSettingsSheetState();
}

class _VpnSettingsSheetState extends State<_VpnSettingsSheet> {
  final _formKey = GlobalKey<FormState>();
  final _privateKeyCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _devicePublicKeyCtrl = TextEditingController();
  bool _saving = false;
  bool _generating = false;
  bool _privateKeyVisible = false;

  @override
  void initState() {
    super.initState();
    _prefill();
  }

  Future<void> _prefill() async {
    final config = await VpnConfigService.instance.load();
    if (config == null || !mounted) return;
    setState(() {
      _privateKeyCtrl.text = config.privateKey;
      _addressCtrl.text = config.address;
      _devicePublicKeyCtrl.text = config.devicePublicKey;
    });
  }

  Future<void> _generateKeyPair() async {
    setState(() => _generating = true);
    try {
      final keyPair = await VpnService.instance.generateKeyPair();
      setState(() {
        _privateKeyCtrl.text = keyPair.privateKey;
        _devicePublicKeyCtrl.text = keyPair.publicKey;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal generate key: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  void _copyDevicePublicKey() {
    if (_devicePublicKeyCtrl.text.trim().isEmpty) return;
    Clipboard.setData(ClipboardData(text: _devicePublicKeyCtrl.text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Kode berhasil disalin. Kirim ke tim IT untuk didaftarkan.',
        ),
      ),
    );
  }

  @override
  void dispose() {
    _privateKeyCtrl.dispose();
    _addressCtrl.dispose();
    _devicePublicKeyCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      await VpnConfigService.instance.save(
        VpnConfigData(
          privateKey: _privateKeyCtrl.text,
          address: _addressCtrl.text,
          devicePublicKey: _devicePublicKeyCtrl.text,
        ),
      );
      if (mounted) Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _required(String? v, String label) {
    if (v == null || v.trim().isEmpty) return '$label wajib diisi';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // SafeArea(top: false) di bawah otomatis nambah jarak seukuran
    // navigation bar HP (gesture bar / tombol back-home-recent), jadi
    // tombol Simpan tidak pernah ketutup terlepas dari model HP-nya.
    // Padding.only di sini cuma urus jarak kiri/kanan/atas + keyboard.
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: KColors.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'Pengaturan VPN',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Private Key',
                style: TextStyle(fontSize: 13, color: KColors.onSurfaceVariant),
              ),
              const SizedBox(height: 10),

              // ==== Private Key + toggle show/hide + tombol generate ====
              // Read-only: private key HARUS hasil generate di device ini,
              // tidak boleh diketik manual (beda dengan Address).
              TextFormField(
                controller: _privateKeyCtrl,
                readOnly: true,
                obscureText: !_privateKeyVisible,
                decoration: InputDecoration(
                  labelText: 'Kode Keamanan Perangkat (Private Key)',
                  border: const OutlineInputBorder(),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          _privateKeyVisible
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                        ),
                        tooltip: _privateKeyVisible
                            ? 'Sembunyikan Kode'
                            : 'Tampilkan Kode',
                        onPressed: () => setState(
                          () => _privateKeyVisible = !_privateKeyVisible,
                        ),
                      ),
                      _generating
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : IconButton(
                              icon: const Icon(Icons.refresh_rounded),
                              tooltip: 'Buat kode baru untuk perangkat ini',
                              onPressed: _generateKeyPair,
                            ),
                    ],
                  ),
                ),
                validator: (v) =>
                    _required(v, 'Kode Keamanan Perangkat (ketuk tombol refresh dulu)'),
              ),
                            if (_devicePublicKeyCtrl.text.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Public Key',
                  style: TextStyle(fontSize: 11.5, color: KColors.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _devicePublicKeyCtrl,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Kode Publik Perangkat',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.copy_rounded),
                      tooltip: 'Salin Kode',
                      onPressed: _copyDevicePublicKey,
                    ),
                  ),
                  style: const TextStyle(fontSize: 12.5),
                ),
              ],
              const SizedBox(height: 12),
             
              Text(
                'Address',
                style: TextStyle(fontSize: 11.5, color: KColors.onSurfaceVariant),
              ),
              const SizedBox(height: 10),

              // ==== Address ====
              TextFormField(
                controller: _addressCtrl,
                decoration: const InputDecoration(
                  labelText: 'Alamat VPN (Contoh: 10.8.0.5/32)',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => _required(v, 'Alamat VPN'),
              ),
              const SizedBox(height: 12),

              const SizedBox(height: 8),
              Text(
                'Ketuk Refresh pada Privat Key yang hanya untuk perangkat anda, setelah itu Copy Public Key dan kirimkan ke tim IT',
                style: TextStyle(fontSize: 11.5, color: KColors.onSurfaceVariant),
              ),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: KColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Simpan'),
                ),
              ),
              // Jarak ekstra di bawah tombol supaya ada nafas sebelum
              // SafeArea menambahkan padding navigation bar HP.
              const SizedBox(height: 32),
            ],
          ),
        ),
        ),
      ),
    );
  }
}