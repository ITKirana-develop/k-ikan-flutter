import 'dart:async';
import 'dart:convert';
import 'package:webview_flutter/webview_flutter.dart';

/// Diambil sekali dari /api/profile/me lewat WebView tersembunyi (supaya
/// otomatis ikut session cookie login yang sudah ada, sama seperti
/// ProfileScreen), lalu di-cache di memori untuk seluruh sesi aplikasi.
/// Semua screen (Home, tiap Beranda modul) pakai instance yang sama ini
/// untuk memutuskan card mana yang ditampilkan.
class AccessService {
  AccessService._();
  static final AccessService instance = AccessService._();

  List<String> _accessibleMenus = [];
  bool _canAccessMaster = false;
  bool _isSecurityOnlyMenu = false;
  bool _loaded = false;
  String _role = '';
  String _fullName = '';
  String _username = '';

  bool get isLoaded => _loaded;
  bool get canAccessMaster => _canAccessMaster;
  bool get isSecurityOnlyMenu => _isSecurityOnlyMenu;
  String get fullName => _fullName;

  /// Inisial nama user (mis. "Super Administrator" -> "SA"), dipakai
  /// buat lingkaran avatar di header Home — ambil dari data yang sama
  /// dengan hasMenu/canAccessMaster, jadi TIDAK perlu fetch terpisah lagi.
  String get initials {
    if (_fullName.trim().isEmpty) return '';
    final parts = _fullName.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  /// Role user yang login, mis. 'superadmin', 'security', 'pj-security'.
  /// Dipakai untuk kasus khusus yang tidak bisa dibedakan hanya dari
  /// accessible_menus (mis. "Laporan Darurat" yang di Laravel dibatasi
  /// role:superadmin walau menu key-nya sama dengan "Lapor Darurat").
  String get role => _role;
  bool get isSuperAdmin => _role == 'superadmin';

  /// Dipakai buat kunci penyimpanan foto profil per-user
  /// (lihat ProfileAvatarService) supaya tiap akun punya foto sendiri.
  String get username => _username;

  /// Cek 1 menu spesifik, mis. hasMenu('assets.index').
  bool hasMenu(String menu) => _accessibleMenus.contains(menu);

  /// Cek apakah punya akses ke MINIMAL 1 menu dari daftar — dipakai untuk
  /// tampil/tidaknya card modul di Menu Utama (mis. card "Asset
  /// Management" tampil kalau user punya akses ke salah satu dari
  /// assets.index / categories.index / locations.index / dst).
  bool hasAnyMenu(List<String> menus) =>
      menus.any((m) => _accessibleMenus.contains(m));

  /// Panggil sekali di awal (mis. di initState HomeScreen). Aman dipanggil
  /// berkali-kali — kalau sudah pernah load sukses, tidak fetch ulang
  /// kecuali forceRefresh: true (mis. setelah ganti akun/login ulang).
  Future<void> load({bool forceRefresh = false}) async {
    if (_loaded && !forceRefresh) return;

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
        // Cache-busting: tanpa ini, WebView Android kadang serve response
        // BASI dari cache (pernah kejadian di alur logout -> 419), yang
        // bisa bikin accessible_menus/can_access_master ketinggalan versi
        // lama walau server aslinya sudah balikin data terbaru.
      Uri.parse(
  'http://127.0.0.1:8000/api/profile/me?_=${DateTime.now().millisecondsSinceEpoch}',
),
      );
      await pageLoaded.future.timeout(const Duration(seconds: 10));

      final raw =
          await controller.runJavaScriptReturningResult('document.body.innerText');
      String jsonText = raw.toString();
      if (jsonText.startsWith('"') && jsonText.endsWith('"')) {
        jsonText = jsonDecode(jsonText) as String;
      }

      final data = jsonDecode(jsonText) as Map<String, dynamic>;

      _accessibleMenus = List<String>.from(data['accessible_menus'] ?? []);
      _canAccessMaster = data['can_access_master'] == true;
      _isSecurityOnlyMenu = data['is_security_only_menu'] == true;
      _role = (data['role'] ?? '').toString();
      _fullName = (data['full_name'] ?? '').toString();
      _username = (data['username'] ?? '').toString();
      _loaded = true;
    } catch (_) {
      // Kalau gagal fetch, biarkan _loaded tetap false — screen yang
      // manggil load() akan cek isLoaded dan bisa retry / tampilkan error.
    }
  }

  /// Dipanggil saat logout, supaya sesi berikutnya (user lain) tidak
  /// kebawa cache akses user sebelumnya.
  void reset() {
    _accessibleMenus = [];
    _canAccessMaster = false;
    _isSecurityOnlyMenu = false;
    _loaded = false;
    _role = '';
    _fullName = '';
    _username = '';
  }
}