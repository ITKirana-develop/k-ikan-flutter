import 'dart:io';

import 'package:flutter/material.dart';
import 'kira_patrol_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'paket_logging_screen.dart';
import 'digital_assignment_screen.dart';
import 'it_profiling_screen.dart';
import 'asset_management_screen.dart';
import 'master_screen.dart';
import '../services/access_service.dart';
import '../services/profile_avatar_service.dart';

/// ==== PALET WARNA (diambil dari referensi HTML K-IKAN) ====
class KColors {
  static const primary = Color(0xFF3230C4);
  static const primaryContainer = Color(0xFF4C4DDC);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryFixed = Color(0xFFE1E0FF); // teks subtitle di header
  static const primaryFixedDim = Color(0xFFC1C1FF); // bg icon "IT Profiling"

  static const secondaryContainer = Color(0xFF69DEFE); // bg icon "Kira Patrol"
  static const secondaryFixed = Color(0xFFB1EBFF); // badge "MASTER"
  static const onSecondaryFixed = Color(0xFF001F27);

  static const surface = Color(0xFFF7FAFC);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerHigh = Color(0xFFE5E9EB); // bg icon "Paket Logging"
  static const surfaceVariant = Color(0xFFE0E3E5); // badge "LOG"
  static const onSurfaceVariant = Color(0xFF464555);
  static const surfaceDim = Color(0xFFD7DADC); // bg icon "MASTER"
  static const outlineVariant = Color(0xFFC7C4D7); // badge "ADMIN"

  static const errorContainer = Color(0xFFFFDAD6); // bg icon "Digital Assignment"

  static const tertiaryFixed = Color(0xFFFFDEA7); // badge "AKTIF" / "TUGAS"
  static const onTertiaryFixed = Color(0xFF271900);

  static const onPrimaryFixed = Color(0xFF07006C); // teks badge "DATA"
  static const onSurface = Color(0xFF181C1E);
  static const outline = Color(0xFF767586);

  // ==== Aksen tambahan untuk sentuhan "modern" (gradient & glow) ====
  static const primaryGradientEnd = Color(0xFF6F6FFF);
  static const headerGlowSoft = Color(0x33FFFFFF);
  static const cardShadow = Color(0x14111C2D);
}

/// Util kecil untuk menghasilkan gradient lembut dari satu warna dasar,
/// dipakai untuk kotak ikon & badge supaya terasa lebih hidup tanpa
/// mengubah palet warna aslinya per-kartu.
class _Grad {
  static LinearGradient soft(Color base) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.lerp(base, Colors.white, 0.18) ?? base,
        Color.lerp(base, Colors.black, 0.06) ?? base,
      ],
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _loadAccess();
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

  Future<void> _loadAccess() async {
    await AccessService.instance.load();
    // Load foto per-username SETELAH access selesai fetch, supaya
    // username-nya sudah kebaca dari response yang sama (tidak perlu
    // request terpisah lagi).
    await ProfileAvatarService.instance.load(AccessService.instance.username);
    if (mounted) setState(() {});
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  @override
  Widget build(BuildContext context) {
    final access = AccessService.instance;

    if (!access.isLoaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final canAssets = access.hasAnyMenu([
      'dashboard', 'assets.index', 'categories.index', 'locations.index',
      'usage.index', 'repairs.index', 'reports.index',
    ]);
    final canPackages = access.hasAnyMenu([
      'packages.requester.index', 'packages.requester.notifications',
      'packages.security.index', 'packages.report.index',
    ]);
    final canDigitalAssignment = access.hasAnyMenu([
      'da.leave-permits.index', 'da.security.index', 'documents.requests.index',
    ]);
    final canItProfiling = access.hasAnyMenu([
      'it.users.index', 'it.devices.index', 'it.usage.index', 'it.repairs.index',
      'it.connections.index', 'it.credentials.index', 'it.zentyal.index',
      'it.samba.index', 'it.cups.index',
    ]);
    final canPatrol = access.hasAnyMenu([
      'patrol.check-points.index', 'patrol.patrols.index', 'patrol.handovers.index',
      'patrol.handover-reports.index', 'patrol.emergency-reports.index',
      'patrol.sessions.approval', 'patrol.sessions.confirmation',
    ]);
    final canMaster = access.canAccessMaster;

    return Scaffold(
      backgroundColor: KColors.surface,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeroHeader(
                greeting: _greeting(),
                initials: access.initials,
                photoFile: ProfileAvatarService.instance.photoFile,
                onAvatarTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 22),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: _SectionLabel('MENU UTAMA'),
              ),
              const SizedBox(height: 14),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    if (canPatrol) ...[
                      _MenuCard(
                        icon: Icons.verified_user_rounded,
                        iconBg: KColors.secondaryContainer,
                        iconColor: KColors.onSecondaryFixed,
                        title: 'Kira Patrol',
                        subtitle: 'Patroli, checkpoint & serah terima keamanan',
                        badgeText: 'AKTIF',
                        badgeBg: KColors.tertiaryFixed,
                        badgeColor: KColors.onTertiaryFixed,
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (context) => const KiraPatrolScreen(),
                          ));
                        },
                      ),
                      const SizedBox(height: 14),
                    ],
                    if (canAssets) ...[
                      _MenuCard(
                        icon: Icons.inventory_2_rounded,
                        iconBg: KColors.primaryFixed,
                        iconColor: KColors.primary,
                        title: 'Asset Management',
                        subtitle: 'Data aset, lokasi & perbaikan',
                        badgeText: 'MASTER',
                        badgeBg: KColors.secondaryFixed,
                        badgeColor: KColors.onSecondaryFixed,
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (context) => const AssetManagementScreen(),
                          ));
                        },
                      ),
                      const SizedBox(height: 14),
                    ],
                    if (canPackages) ...[
                      _MenuCard(
                        icon: Icons.local_shipping_rounded,
                        iconBg: KColors.surfaceContainerHigh,
                        iconColor: const Color(0xFF17A883),
                        title: 'Paket Logging',
                        subtitle: 'Catat keluar masuk paket',
                        badgeText: 'LOG',
                        badgeBg: KColors.surfaceVariant,
                        badgeColor: KColors.onSurfaceVariant,
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (context) => const PaketLoggingScreen(),
                          ));
                        },
                      ),
                      const SizedBox(height: 14),
                    ],
                    if (canDigitalAssignment) ...[
                      _MenuCard(
                        icon: Icons.assignment_rounded,
                        iconBg: KColors.errorContainer,
                        iconColor: const Color(0xFFBA1A1A),
                        title: 'Digital Assignment',
                        subtitle: 'Penugasan & approval digital',
                        badgeText: 'TUGAS',
                        badgeBg: KColors.tertiaryFixed,
                        badgeColor: KColors.onTertiaryFixed,
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (context) => const DigitalAssignmentScreen(),
                          ));
                        },
                      ),
                      const SizedBox(height: 14),
                    ],
                    if (canItProfiling) ...[
                      _MenuCard(
                        icon: Icons.computer_rounded,
                        iconBg: KColors.primaryFixedDim,
                        iconColor: KColors.onPrimaryFixed,
                        title: 'IT Profiling',
                        subtitle: 'Data & profil aset IT',
                        badgeText: 'DATA',
                        badgeBg: KColors.primaryFixedDim,
                        badgeColor: KColors.onPrimaryFixed,
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (context) => const ItProfilingScreen(),
                          ));
                        },
                      ),
                      const SizedBox(height: 14),
                    ],
                    if (canMaster)
                      _MenuCard(
                        icon: Icons.settings_rounded,
                        iconBg: KColors.surfaceDim,
                        iconColor: KColors.onSurfaceVariant,
                        title: 'MASTER',
                        subtitle: 'Pengaturan master data sistem',
                        badgeText: 'ADMIN',
                        badgeBg: KColors.outlineVariant,
                        badgeColor: KColors.onSurface,
                        uppercaseTitle: true,
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (context) => const MasterScreen(),
                          ));
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const _KBottomNavBar(),
    );
  }
}

  void _comingSoon(BuildContext context, String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title belum tersedia'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

/// ==== HEADER: solid primary + sudut kanan-bawah membulat + lingkaran dekoratif ====
class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.greeting,
    this.initials,
    this.photoFile,
    this.onAvatarTap,
  });

  final String greeting;
  final String? initials;
  final File? photoFile;
  final VoidCallback? onAvatarTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(36),
        bottomRight: Radius.circular(36),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [KColors.primary, KColors.primaryGradientEnd],
          ),
          boxShadow: [
            BoxShadow(
              color: KColors.primary.withValues(alpha: 0.35),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          children: [
            // lingkaran dekoratif blur di kanan atas
            Positioned(
              right: -50,
              top: -60,
              child: Container(
                width: 210,
                height: 210,
                decoration: BoxDecoration(
                  color: KColors.headerGlowSoft,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // lingkaran dekoratif kedua untuk kedalaman ekstra
            Positioned(
              left: -30,
              bottom: -50,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                          Icon(
                            Icons.grid_view_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'K-IKAN',
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
                    InkWell(
                      onTap: onAvatarTap,
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: 42,
                        height: 42,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.2),
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          image: photoFile != null
                              ? DecorationImage(
                                  image: FileImage(photoFile!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: photoFile == null
                            ? Text(
                                initials ?? '',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  greeting,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Pilih menu di bawah untuk mulai bekerja.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w400,
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

/// ==== KARTU MENU: layout horizontal, icon 80x80, badge chip, chevron ====
/// Mengikuti gaya kartu pada referensi HTML (bukan grid 2 kolom).
class _MenuCard extends StatelessWidget {
  const _MenuCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.badgeBg,
    required this.badgeColor,
    this.onTap,
    this.uppercaseTitle = false,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String badgeText;
  final Color badgeBg;
  final Color badgeColor;
  final VoidCallback? onTap;
  final bool uppercaseTitle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: iconColor.withValues(alpha: 0.08),
        highlightColor: iconColor.withValues(alpha: 0.04),
        child: Container(
          decoration: BoxDecoration(
            color: KColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: KColors.outlineVariant.withValues(alpha: 0.25),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: KColors.cardShadow,
                blurRadius: 22,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: _Grad.soft(iconBg),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: iconColor.withValues(alpha: 0.22),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(icon, color: iconColor, size: 25),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      uppercaseTitle ? title.toUpperCase() : title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        color: KColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: KColors.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 3.5,
                      ),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: badgeColor,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: KColors.surface,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: KColors.outline,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ==== BOTTOM NAV BAR — Menu Utama: Home / Notifikasi / Profile ====
class _KBottomNavBar extends StatelessWidget {
  const _KBottomNavBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: KColors.surfaceContainerLowest,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(icon: Icons.home_rounded, label: 'Home', active: true),
          _NavItem(
            icon: Icons.notifications_rounded,
            label: 'Notifikasi',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
              );
            },
          ),
          _NavItem(
            icon: Icons.person_rounded,
            label: 'Profile',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    this.active = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          gradient: active
              ? LinearGradient(
                  colors: [KColors.primary, KColors.primaryGradientEnd],
                )
              : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: KColors.primary.withValues(alpha: 0.28),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: active ? Colors.white : KColors.onSurfaceVariant,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? Colors.white : KColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}