import 'package:flutter/material.dart';
import 'home_screen.dart' show KColors;
import 'webview_screen.dart';
import 'module_bottom_nav.dart';
import '../services/access_service.dart';

class DigitalAssignmentScreen extends StatelessWidget {
  const DigitalAssignmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final access = AccessService.instance;

    final cards = <Widget>[
      // CATATAN: MenuPermissionConfig cuma punya 1 key untuk modul Surat
      // Ijin ('da.leave-permits.index' -> "Surat Ijin Keluar Pabrik"),
      // tidak ada key terpisah untuk Surat Ijin Pulang. Jadi keduanya
      // sementara ikut key yang sama. Kalau ternyata harus dipisah,
      // tambahkan key baru dulu di MenuPermissionConfig sisi Laravel.
      if (access.hasMenu('da.leave-permits.index'))
        _GradientCard(
          icon: Icons.logout_rounded,
          gradient: const [Color(0xFF7C8CFF), Color(0xFF3230C4)],
          title: 'Surat Ijin Keluar',
          subtitle: 'Pengajuan ijin keluar pabrik',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const WebViewScreen(
                  title: 'Surat Ijin Keluar',
                  url: 'https://office.mykfin.com/da/leave-permits?mobile_app=1',
                ),
              ),
            );
          },
        ),
      if (access.hasMenu('da.leave-permits.index'))
        _GradientCard(
          icon: Icons.login_rounded,
          gradient: const [Color(0xFFFFC371), Color(0xFFD98324)],
          title: 'Surat Ijin Pulang',
          subtitle: 'Pengajuan ijin pulang karyawan',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const WebViewScreen(
                  title: 'Surat Ijin Pulang',
                  url: 'https://office.mykfin.com/da/home-permits?mobile_app=1',
                ),
              ),
            );
          },
        ),
      if (access.hasMenu('documents.requests.index'))
        _GradientCard(
          icon: Icons.folder_copy_rounded,
          gradient: const [Color(0xFF15C7D6), Color(0xFF00677C)],
          title: 'Customs Archive',
          subtitle: 'Dokumen approval kepabeanan',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const WebViewScreen(
                  title: 'Customs Archive',
                  url: 'https://office.mykfin.com/documents/requests?mobile_app=1',
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

              if (cards.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: _SectionLabel('MENU DIGITAL ASSIGNMENT'),
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
                    children: cards,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: const ModuleBottomNavBar(
        moduleScope: 'digital_assignment',
        moduleLabel: 'Beranda',
      ),
    );
  }
}

class _GradientCard extends StatelessWidget {
  const _GradientCard({
    required this.icon,
    required this.gradient,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final List<Color> gradient;
  final String title;
  final String subtitle;
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
                          Icon(Icons.assignment_rounded, color: Colors.white, size: 14),
                          SizedBox(width: 6),
                          Text(
                            'DIGITAL ASSIGNMENT',
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
                  'Digital Assignment',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Kelola penugasan & approval digital di sini.',
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