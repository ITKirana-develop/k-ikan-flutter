import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'home_screen.dart' show KColors;
import 'webview_screen.dart';
import 'module_bottom_nav.dart';
import '../services/access_service.dart';

class KiraPatrolScreen extends StatelessWidget {
  const KiraPatrolScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final access = AccessService.instance;

    // ==== LAYANAN UTAMA ====
    final layananUtamaCards = <Widget>[
      if (access.hasMenu('da.security.index'))
        _GradientCard(
          icon: Icons.description_rounded,
          gradient: const [Color(0xFF6D8CFF), Color(0xFF3230C4)],
          title: 'Surat Ijin',
          subtitle: 'Checkout ijin keluar / pulang karyawan',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const WebViewScreen(
                  title: 'Surat Ijin',
                  url: 'http://127.0.0.1:8000/da/security?mobile_app=1',
                ),
              ),
            );
          },
        ),
      if (access.hasMenu('packages.security.index'))
        _GradientCard(
          icon: Icons.inventory_2_rounded,
          gradient: const [Color(0xFFFFC371), Color(0xFFD98324)],
          title: 'Penerimaan Paket',
          subtitle: 'Catat & parkirkan paket yang datang',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const WebViewScreen(
                  title: 'Penerimaan Paket',
                  url: 'http://127.0.0.1:8000/packages/security?mobile_app=1',
                ),
              ),
            );
          },
        ),
    ];

    // ==== PATROLI ====
    // Kontak Darurat selalu tampil — cuma dialer telepon, tidak
    // menyentuh halaman Laravel sama sekali, jadi tidak perlu izin menu.
    final patroliCards = <Widget>[
      _GradientCard(
        icon: Icons.call_rounded,
        gradient: const [Color(0xFFFF6B6B), Color(0xFFBA1A1A)],
        title: 'Kontak Darurat',
        subtitle: 'Damkar, Polisi & Ambulance',
        onTap: () => _showEmergencyContacts(context),
      ),
      if (access.hasMenu('patrol.patrols.index'))
        _GradientCard(
          icon: Icons.qr_code_scanner_rounded,
          gradient: const [Color(0xFF7C8CFF), Color(0xFF3230C4)],
          title: 'Form Patrol',
          subtitle: 'Mulai sesi & scan checkpoint',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const WebViewScreen(
                  title: 'Form Patrol',
                  url: 'http://127.0.0.1:8000/patrol/session/start?mobile_app=1',
                ),
              ),
            );
          },
        ),
      if (access.hasMenu('patrol.check-points.index'))
        _GradientCard(
          icon: Icons.location_on_rounded,
          gradient: const [Color(0xFF15C7D6), Color(0xFF00677C)],
          title: 'Master Checkpoint',
          subtitle: 'Kelola titik & QR checkpoint patroli',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const WebViewScreen(
                  title: 'Master Checkpoint',
                  url: 'http://127.0.0.1:8000/patrol/check-points?mobile_app=1',
                ),
              ),
            );
          },
        ),
      if (access.hasMenu('patrol.patrols.index'))
        _GradientCard(
          icon: Icons.history_rounded,
          gradient: const [Color(0xFFB18CFF), Color(0xFF6D28D9)],
          title: 'Riwayat Patroli',
          subtitle: 'Log sesi patroli sebelumnya',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const WebViewScreen(
                  title: 'Riwayat Patroli',
                  url: 'http://127.0.0.1:8000/patrol?mobile_app=1',
                ),
              ),
            );
          },
        ),
      if (access.hasMenu('patrol.sessions.approval'))
        _GradientCard(
          icon: Icons.fact_check_rounded,
          gradient: const [Color(0xFF4FD1C5), Color(0xFF0E7490)],
          title: 'Approval Patroli',
          subtitle: 'Persetujuan Komandan (PJ Security)',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const WebViewScreen(
                  title: 'Approval Patroli',
                  url: 'http://127.0.0.1:8000/patrol/session/approval?mobile_app=1',
                ),
              ),
            );
          },
        ),
      if (access.hasMenu('patrol.sessions.confirmation'))
        _GradientCard(
          icon: Icons.verified_rounded,
          gradient: const [Color(0xFF34D399), Color(0xFF047857)],
          title: 'Konfirmasi Patroli',
          subtitle: 'Konfirmasi akhir HRD',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const WebViewScreen(
                  title: 'Konfirmasi Patroli',
                  url: 'http://127.0.0.1:8000/patrol/session/confirmation?mobile_app=1',
                ),
              ),
            );
          },
        ),
      if (access.hasMenu('patrol.emergency-reports.index'))
        _GradientCard(
          icon: Icons.warning_rounded,
          gradient: const [Color(0xFFFF9D6C), Color(0xFFD64550)],
          title: 'Lapor Darurat',
          subtitle: 'Buat laporan insiden',
          onTap: () async {
            final result = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (context) => const WebViewScreen(
                  title: 'Lapor Darurat',
                  url: 'http://127.0.0.1:8000/patrol/emergency-reports/create?mobile_app=1',
                  closeOnUrlContains: '/patrol/menu',
                ),
              ),
            );

            if (result == true && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Laporan kondisi darurat berhasil dikirim.'),
                  duration: Duration(seconds: 3),
                ),
              );
            }
          },
        ),
      // Daftar & kelola laporan darurat masuk khusus superadmin di Laravel
      // (route index/show/resolve dibungkus middleware role:superadmin),
      // beda dengan "Lapor Darurat" di atas yang terbuka lebih luas.
      if (access.hasMenu('patrol.emergency-reports.index') && access.isSuperAdmin)
        _GradientCard(
          icon: Icons.report_rounded,
          gradient: const [Color(0xFFEF4444), Color(0xFF7F1D1D)],
          title: 'Laporan Darurat',
          subtitle: 'Kelola laporan insiden masuk',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const WebViewScreen(
                  title: 'Laporan Darurat',
                  url: 'http://127.0.0.1:8000/patrol/emergency-reports?mobile_app=1',
                ),
              ),
            );
          },
        ),
    ];

    // ==== SERAH TERIMA ====
    final serahTerimaCards = <Widget>[
      if (access.hasMenu('patrol.handovers.index'))
        _GradientCard(
          icon: Icons.handshake_rounded,
          gradient: const [Color(0xFFFBBF24), Color(0xFF92400E)],
          title: 'Serah Terima',
          subtitle: 'Proses operan shift',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const WebViewScreen(
                  title: 'Serah Terima',
                  url: 'http://127.0.0.1:8000/patrol/handovers/create?mobile_app=1',
                ),
              ),
            );
          },
        ),
      if (access.hasMenu('patrol.handover-reports.index'))
        _GradientCard(
          icon: Icons.assignment_rounded,
          gradient: const [Color(0xFF64748B), Color(0xFF334155)],
          title: 'Laporan Serah Terima',
          subtitle: 'Riwayat operan shift',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const WebViewScreen(
                  title: 'Laporan Serah Terima',
                  url: 'http://127.0.0.1:8000/patrol/handover-reports?mobile_app=1',
                ),
              ),
            );
          },
        ),
    ];

    return Scaffold(
      backgroundColor: KColors.surface,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _HeroHeader(),
              const SizedBox(height: 24),

              if (layananUtamaCards.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: _SectionLabel('LAYANAN UTAMA'),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.95,
                    children: layananUtamaCards,
                  ),
                ),
                const SizedBox(height: 24),
              ],

              if (patroliCards.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: _SectionLabel('PATROLI'),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.95,
                    children: patroliCards,
                  ),
                ),
                const SizedBox(height: 24),
              ],

              if (serahTerimaCards.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: _SectionLabel('SERAH TERIMA'),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.95,
                    children: serahTerimaCards,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: const ModuleBottomNavBar(
        moduleScope: 'kira_patrol',
        moduleLabel: 'Beranda',
      ),
    );
  }

  void _showEmergencyContacts(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.call_rounded, color: const Color(0xFFBA1A1A)),
                    const SizedBox(width: 8),
                    const Text(
                      'Kontak Darurat',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Ketuk salah satu kontak untuk langsung menelepon.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: KColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                _EmergencyContactTile(
                  icon: Icons.local_fire_department_rounded,
                  iconColor: const Color(0xFFBA1A1A),
                  title: 'Pemadam Kebakaran Terdekat',
                  number: '0356321016',
                ),
                const SizedBox(height: 10),
                _EmergencyContactTile(
                  icon: Icons.local_police_rounded,
                  iconColor: const Color(0xFF3230C4),
                  title: 'Kepolisian Terdekat',
                  number: '110',
                ),
                const SizedBox(height: 10),
                _EmergencyContactTile(
                  icon: Icons.local_hospital_rounded,
                  iconColor: const Color(0xFF047857),
                  title: 'Ambulance',
                  number: '0356811843',
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Tutup'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _tap(BuildContext context, String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title dipilih'),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}

/// Header: solid primary + sudut kanan-bawah membulat + pattern tipis
/// (mereplikasi bg-primary + gambar overlay opacity-20 pada HTML).
/// Kartu gradient seragam — dipakai semua menu (Layanan Utama, Patroli,
/// Serah Terima) supaya ukurannya konsisten, tiap menu beda warna gradasi.
class _GradientCard extends StatelessWidget {
  const _GradientCard({
    required this.icon,
    required this.gradient,
    required this.title,
    required this.subtitle,
    this.onTap,
  }) : showBadge = false;

  final IconData icon;
  final List<Color> gradient;
  final String title;
  final String subtitle;
  final bool showBadge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.white.withValues(alpha: 0.15),
        highlightColor: Colors.white.withValues(alpha: 0.06),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: gradient.last.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Stack(
            children: [
              // dekorasi lingkaran transparan di pojok (senada referensi HTML)
              Positioned(
                right: -18,
                top: -18,
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.24),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.28),
                        width: 1,
                      ),
                    ),
                    child: Icon(icon, color: Colors.white, size: 24),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.white.withValues(alpha: 0.92),
                      fontWeight: FontWeight.w500,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
              if (showBadge)
                Positioned(
                  top: 2,
                  right: 2,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: gradient.last,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(32),
        bottomRight: Radius.circular(32),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [KColors.primary, KColors.primaryGradientEnd],
          ),
          boxShadow: [
            BoxShadow(
              color: KColors.primary.withValues(alpha: 0.32),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -50,
              top: -55,
              child: Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  color: KColors.headerGlowSoft,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              left: -30,
              bottom: -45,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned.fill(
              child: Opacity(
                opacity: 0.10,
                child: Image.asset(
                  'assets/images/network_pattern.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.22),
                          width: 1,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.shield_rounded, color: Colors.white, size: 14),
                          SizedBox(width: 6),
                          Text(
                            'KIRA PATROL',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Text(
                  'Kira Patrol',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Patroli, checkpoint & serah terima keamanan.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 14,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: KColors.primary,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
            color: KColors.outline,
          ),
        ),
      ],
    );
  }
}

class _EmergencyContactTile extends StatelessWidget {
  const _EmergencyContactTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.number,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String number;

  Future<void> _call() async {
    final uri = Uri(scheme: 'tel', path: number);
    await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: KColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: _call,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      number,
                      style: TextStyle(
                        fontSize: 12,
                        color: KColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF047857).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.call_rounded,
                  size: 16,
                  color: Color(0xFF047857),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}