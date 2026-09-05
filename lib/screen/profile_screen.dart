import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'home_screen.dart' show KColors;
import 'webview_screen.dart';
import '../services/profile_avatar_service.dart';
import '../services/access_service.dart';

/// Halaman Profile — sama untuk semua modul (Menu Utama, Kira Patrol,
/// dan modul lain nantinya). Data user diambil dari database Laravel
/// lewat API kecil (/api/profile/me), memakai WebView tersembunyi
/// supaya session cookie login yang sudah ada otomatis ikut terpakai
/// (tidak perlu sistem token API terpisah).
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  String? _error;
  bool _loading = true;
  bool _loggingOut = false;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
    ProfileAvatarService.instance.addListener(_onAvatarChanged);
  }

  @override
  void dispose() {
    ProfileAvatarService.instance.removeListener(_onAvatarChanged);
    super.dispose();
  }

  void _onAvatarChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _pickPhoto() async {
    if (!mounted) return;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_rounded),
                title: const Text('Ambil Foto'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: const Text('Pilih dari Galeri'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) return;

    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 720,
    );

    if (file == null) return;

    final username = _profile?['username'] as String? ?? '';
    if (username.isEmpty) return; // belum ada data profil, jangan simpan

    await ProfileAvatarService.instance.setPhoto(File(file.path), username);
  }

  Future<void> _fetchProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted);

      final pageLoaded = Completer<void>();

      controller.setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) {
            if (!pageLoaded.isCompleted) pageLoaded.complete();
          },
          onWebResourceError: (error) {
            if (!pageLoaded.isCompleted) {
              pageLoaded.completeError(error.description);
            }
          },
        ),
      );

      await controller.loadRequest(
        Uri.parse('https://office.mykfin.com/api/profile/me'),
      );

      await pageLoaded.future.timeout(const Duration(seconds: 10));

      final raw = await controller.runJavaScriptReturningResult(
        'document.body.innerText',
      );

      String jsonText = raw.toString();
      // runJavaScriptReturningResult membungkus hasil string dalam
      // quote tambahan (mis. "\"{...}\""), buka sekali lagi kalau perlu.
      if (jsonText.startsWith('"') && jsonText.endsWith('"')) {
        jsonText = jsonDecode(jsonText) as String;
      }

      final data = jsonDecode(jsonText) as Map<String, dynamic>;

      if (!mounted) return;
      setState(() {
        _profile = data;
        _loading = false;
      });

      final username = data['username'] as String? ?? '';
      if (username.isNotEmpty) {
        await ProfileAvatarService.instance.load(username);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Gagal memuat data profil.';
        _loading = false;
      });
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar Akun'),
        content: const Text('Yakin ingin logout dari aplikasi ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _logout();
    }
  }

  Future<void> _logout() async {
    setState(() => _loggingOut = true);

    try {
      // Hapus session cookie WebView supaya login Laravel benar-benar
      // ter-clear, bukan cuma pindah layar.
      await WebViewCookieManager().clearCookies();
    } catch (_) {
      // Kalau gagal clear cookie, tetap lanjut ke Login supaya user
      // tidak stuck di halaman Profile.
    }

    // PENTING: AccessService itu singleton yang cache hak akses menu di
    // memori (skip fetch ulang selama _loaded == true). Tanpa reset ini,
    // user BERIKUTNYA yang login (role beda, mis. superadmin -> security)
    // bakal tetap kebawa daftar menu punya user sebelumnya, bukan hak
    // akses miliknya sendiri.
    AccessService.instance.reset();
    ProfileAvatarService.instance.reset();

    if (!mounted) return;

    // Tidak ada LoginScreen Flutter terpisah — login ditangani langsung
    // oleh WebView yang me-load form login Laravel. Hit /logout dulu
    // (route ini bisa diakses langsung via GET) supaya Laravel benar-benar
    // menghapus session di server, lalu Laravel akan redirect ke halaman
    // login yang otomatis tampil di WebView yang sama.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => WebViewScreen(
          title: 'Login',
          // AppBar dimatikan supaya tampilannya persis sama seperti
          // halaman login pertama kali (main.dart) — full screen tanpa
          // judul "Login" di atas.
          showAppBar: false,
          // Tambahkan timestamp unik (?_= ) supaya URL selalu berbeda
          // tiap kali logout, WebView jadi tidak mungkin serve halaman
          // ini dari cache (yang bisa bawa token CSRF basi -> 419).
          url:
              'https://office.mykfin.com/mobile-logout?_=${DateTime.now().millisecondsSinceEpoch}',
          // Abis user login ulang di sini dan Laravel redirect ke
          // dashboard/menu patrol, pindah ke HomeScreen Flutter (sama
          // seperti alur login pertama kali di main.dart), jangan
          // tampilkan dashboard Laravel mentah di dalam WebView ini.
          redirectHomeWhen: (url) =>
              url.contains('/dashboard') || url.contains('/patrol/menu'),
        ),
      ),
      (route) => false,
    );
  }

  String _roleLabel(String? role) {
    if (role == null || role.isEmpty) return '-';
    return role
        .split('-')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  String _initials(String? name) {
    if (name == null || name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KColors.surface,
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        backgroundColor: KColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        foregroundColor: KColors.onSurface,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: KColors.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              KColors.primaryFixed.withValues(alpha: 0.35),
              KColors.surface,
            ],
            stops: const [0.0, 0.35],
          ),
        ),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _ErrorState(message: _error!, onRetry: _fetchProfile)
                : _ProfileContent(
                    profile: _profile!,
                    initials: _initials(_profile!['full_name'] as String?),
                    roleLabel: _roleLabel(_profile!['role'] as String?),
                    loggingOut: _loggingOut,
                    onLogout: _confirmLogout,
                    photoFile: ProfileAvatarService.instance.photoFile,
                    onEditPhoto: _pickPhoto,
                  ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: KColors.onSurfaceVariant.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline_rounded,
                  size: 28, color: KColors.onSurfaceVariant),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: KColors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({
    required this.profile,
    required this.initials,
    required this.roleLabel,
    required this.loggingOut,
    required this.onLogout,
    required this.photoFile,
    required this.onEditPhoto,
  });

  final Map<String, dynamic> profile;
  final String initials;
  final String roleLabel;
  final bool loggingOut;
  final VoidCallback onLogout;
  final File? photoFile;
  final VoidCallback onEditPhoto;

  String _valueOr(dynamic v) {
    if (v == null) return '-';
    final s = v.toString().trim();
    return s.isEmpty ? '-' : s;
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Center(
          child: Column(
            children: [
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: KColors.surfaceContainerLowest,
                      boxShadow: [
                        BoxShadow(
                          color: KColors.primary.withValues(alpha: 0.18),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 44,
                      backgroundColor: KColors.primary,
                      backgroundImage:
                          photoFile != null ? FileImage(photoFile!) : null,
                      child: photoFile == null
                          ? Text(
                              initials,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            )
                          : null,
                    ),
                  ),
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Material(
                      color: KColors.primary,
                      shape: const CircleBorder(
                        side: BorderSide(color: Colors.white, width: 2),
                      ),
                      elevation: 3,
                      shadowColor: KColors.primary.withValues(alpha: 0.4),
                      child: InkWell(
                        onTap: onEditPhoto,
                        customBorder: const CircleBorder(),
                        child: const Padding(
                          padding: EdgeInsets.all(7),
                          child: Icon(
                            Icons.camera_alt_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                _valueOr(profile['full_name']),
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: KColors.primaryFixed,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  roleLabel.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: KColors.primary,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        _InfoTile(
          icon: Icons.badge_rounded,
          label: 'Username',
          value: _valueOr(profile['username']),
        ),
        _InfoTile(
          icon: Icons.email_rounded,
          label: 'Email',
          value: _valueOr(profile['email']),
        ),
        _InfoTile(
          icon: Icons.phone_rounded,
          label: 'No. HP',
          value: _valueOr(profile['phone']),
        ),
        _InfoTile(
          icon: Icons.apartment_rounded,
          label: 'Department',
          value: _valueOr(profile['department']),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: loggingOut ? null : onLogout,
            icon: loggingOut
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout_rounded, color: Colors.red),
            label: Text(
              loggingOut ? 'Sedang keluar...' : 'Logout',
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: OutlinedButton.styleFrom(
              backgroundColor: KColors.surfaceContainerLowest,
              padding: const EdgeInsets.symmetric(vertical: 15),
              side: BorderSide(color: Colors.red.withValues(alpha: 0.4)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: KColors.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: KColors.onSurface.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: KColors.primaryFixed.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: KColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: KColors.onSurfaceVariant,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: KColors.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}