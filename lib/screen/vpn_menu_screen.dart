import 'package:flutter/material.dart';
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
      _showSnack('Isi Pengaturan VPN dulu sebelum menyambungkan.');
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
      _showSnack('Gagal ${turnOn ? "menyambungkan" : "memutuskan"} VPN: $e');
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
        title: const Text('VPN Kantor'),
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
                        'VPN Kantor',
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
                  'Konfigurasi VPN belum diisi. Tekan ikon pengaturan di kanan atas untuk mengisi data dari tim IT.',
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
  final _publicKeyCtrl = TextEditingController();
  final _endpointCtrl = TextEditingController();
  bool _saving = false;
  bool _showAdvanced = false;

  final _dnsCtrl = TextEditingController(text: '1.1.1.1');
  final _allowedIpsCtrl = TextEditingController(text: '0.0.0.0/0');
  final _keepaliveCtrl = TextEditingController(text: '25');

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
      _publicKeyCtrl.text = config.publicKey;
      _endpointCtrl.text = config.endpoint;
      _dnsCtrl.text = config.dns;
      _allowedIpsCtrl.text = config.allowedIps;
      _keepaliveCtrl.text = config.persistentKeepalive.toString();
    });
  }

  @override
  void dispose() {
    _privateKeyCtrl.dispose();
    _addressCtrl.dispose();
    _publicKeyCtrl.dispose();
    _endpointCtrl.dispose();
    _dnsCtrl.dispose();
    _allowedIpsCtrl.dispose();
    _keepaliveCtrl.dispose();
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
          publicKey: _publicKeyCtrl.text,
          endpoint: _endpointCtrl.text,
          dns: _dnsCtrl.text.trim().isEmpty ? '1.1.1.1' : _dnsCtrl.text,
          allowedIps: _allowedIpsCtrl.text.trim().isEmpty
              ? '0.0.0.0/0'
              : _allowedIpsCtrl.text,
          persistentKeepalive: int.tryParse(_keepaliveCtrl.text.trim()) ?? 25,
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
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
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
                'Isi persis sesuai data / file .conf dari tim IT.',
                style: TextStyle(fontSize: 13, color: KColors.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _privateKeyCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Private Key (device ini)',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => _required(v, 'Private Key'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressCtrl,
                decoration: const InputDecoration(
                  labelText: 'Address (mis. 10.8.0.5/32)',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => _required(v, 'Address'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _publicKeyCtrl,
                decoration: const InputDecoration(
                  labelText: 'Public Key Server',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => _required(v, 'Public Key Server'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _endpointCtrl,
                decoration: const InputDecoration(
                  labelText: 'Endpoint (host:port, mis. vpn.mykfin.com:51820)',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => _required(v, 'Endpoint'),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => setState(() => _showAdvanced = !_showAdvanced),
                icon: Icon(
                  _showAdvanced
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                ),
                label: const Text('Pengaturan lanjutan'),
              ),
              if (_showAdvanced) ...[
                TextFormField(
                  controller: _dnsCtrl,
                  decoration: const InputDecoration(
                    labelText: 'DNS',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _allowedIpsCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Allowed IPs',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _keepaliveCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Persistent Keepalive (detik)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
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
            ],
          ),
        ),
      ),
    );
  }
}
