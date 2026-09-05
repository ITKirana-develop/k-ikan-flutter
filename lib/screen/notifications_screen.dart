import 'package:flutter/material.dart';
import 'home_screen.dart' show KColors;
import 'webview_screen.dart';

/// Daftar notifikasi. Dipakai dari 2 tempat:
/// - Menu Utama (Home): [moduleScope] = null -> tampil SEMUA notifikasi
///   dari semua modul.
/// - Dalam sebuah modul (mis. Kira Patrol): [moduleScope] diisi kode
///   modulnya -> cuma tampil notifikasi modul itu.
///
/// Nambah notifikasi modul baru (mis. Asset Management) tinggal tambah
/// entri baru di [_items] dengan `module: 'asset_management'` — otomatis
/// kefilter sendiri di kedua tempat tanpa ubah kode lain.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key, this.moduleScope});

  final String? moduleScope;

  static const _items = <_NotifItemData>[
    _NotifItemData(
      module: 'kira_patrol',
      icon: Icons.warning_rounded,
      iconColor: Color(0xFFD64550),
      title: 'Laporan Kondisi Darurat',
      subtitle: 'Laporan insiden yang masih aktif',
      pageTitle: 'Laporan Darurat',
      url: 'http://127.0.0.1:8000//patrol/emergency-reports?mobile_app=1',
    ),
    _NotifItemData(
      module: 'kira_patrol',
      icon: Icons.fact_check_rounded,
      iconColor: Color(0xFF0E7490),
      title: 'Approval Patroli',
      subtitle: 'Sesi patroli menunggu persetujuan Komandan',
      pageTitle: 'Approval Patroli',
      url: 'http://127.0.0.1:8000//patrol/session/approval?mobile_app=1',
    ),
    _NotifItemData(
      module: 'kira_patrol',
      icon: Icons.verified_rounded,
      iconColor: Color(0xFF047857),
      title: 'Konfirmasi Patroli',
      subtitle: 'Sesi patroli menunggu konfirmasi akhir HRD',
      pageTitle: 'Konfirmasi Patroli',
      url: 'http://127.0.0.1:8000//patrol/session/confirmation?mobile_app=1',
    ),
    _NotifItemData(
      module: 'paket_logging',
      icon: Icons.local_shipping_rounded,
      iconColor: Color(0xFF17A883),
      title: 'Notifikasi Paket',
      subtitle: 'Update status paket yang kamu ajukan',
      pageTitle: 'Notifikasi Paket',
      url: 'http://127.0.0.1:8000//packages/my/notifications/all?mobile_app=1',
    ),
    // Modul lain (Asset Management, dst) tinggal tambah _NotifItemData
    // baru di sini dengan module: 'asset_management', dst.
      _NotifItemData(
      module: 'digital_assignment',
      icon: Icons.logout_rounded,
      iconColor: Color(0xFF3230C4),
      title: 'Surat Ijin Keluar',
      subtitle: 'Surat ijin keluar menunggu approval',
      pageTitle: 'Surat Ijin Keluar',
      url: 'http://127.0.0.1:8000//da/leave-permits?mobile_app=1',
    ),
    _NotifItemData(
      module: 'digital_assignment',
      icon: Icons.login_rounded,
      iconColor: Color(0xFFD98324),
      title: 'Surat Ijin Pulang',
      subtitle: 'Surat ijin pulang menunggu approval',
      pageTitle: 'Surat Ijin Pulang',
      url: 'http://127.0.0.1:8000//da/home-permits?mobile_app=1',
    ),
    // Modul lain (Asset Management, dst) tinggal tambah _NotifItemData
    // baru di sini dengan module: 'asset_management', dst.
    ];


  @override
  Widget build(BuildContext context) {
    final items = moduleScope == null
        ? _items
        : _items.where((e) => e.module == moduleScope).toList();

    return Scaffold(
      backgroundColor: KColors.surface,
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        title: Text(
          moduleScope == null ? 'Notifikasi' : 'Notifikasi Modul',
          style: const TextStyle(
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
            colors: [KColors.surfaceContainerHigh.withValues(alpha: 0.5), KColors.surface],
          ),
        ),
        child: items.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: KColors.primary.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.notifications_off_rounded,
                        color: KColors.primary.withValues(alpha: 0.5),
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Belum ada notifikasi',
                      style: TextStyle(
                        color: KColors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _NotificationTile(
                    icon: item.icon,
                    iconColor: item.iconColor,
                    title: item.title,
                    subtitle: item.subtitle,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => WebViewScreen(
                            title: item.pageTitle,
                            url: item.url,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}


class _NotifItemData {
  
  const _NotifItemData({
    required this.module,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.pageTitle,
    required this.url,
  });

  final String module;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String pageTitle;
  final String url;
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        splashColor: iconColor.withValues(alpha: 0.08),
        highlightColor: iconColor.withValues(alpha: 0.04),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: KColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: KColors.primary.withValues(alpha: 0.05),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 21),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.1,
                        color: KColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: KColors.onSurfaceVariant,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: KColors.surface,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: KColors.outline,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}