import 'package:flutter/material.dart';
import 'home_screen.dart' show KColors, HomeScreen;
import 'notifications_screen.dart';
import 'profile_screen.dart';

/// Bottom navigation REUSABLE untuk semua modul (Kira Patrol, Asset
/// Management, dst) — 4 tombol: Home / Beranda / Notifikasi / Profile.
///
/// - Home   : KELUAR modul, balik ke Menu Utama aplikasi (pushReplacement).
/// - Beranda: tetap di modul ini (halaman saat ini), ditandai aktif.
/// - Notifikasi: hanya notifikasi milik modul ini (difilter via [moduleScope]).
/// - Profile: sama untuk semua modul.
///
/// Cara pakai di modul lain (mis. Asset Management):
/// ```dart
/// bottomNavigationBar: const ModuleBottomNavBar(
///   moduleScope: 'asset_management',
///   moduleLabel: 'Beranda',
/// ),
/// ```
class ModuleBottomNavBar extends StatelessWidget {
  const ModuleBottomNavBar({
    super.key,
    required this.moduleScope,
    this.moduleLabel = 'Beranda',
  });

  /// Key unik modul, dipakai buat filter notifikasi (mis. 'kira_patrol').
  final String moduleScope;

  /// Label tombol ke-2 (default 'Beranda', bisa diganti per modul kalau perlu).
  final String moduleLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: BoxDecoration(
        color: KColors.surfaceContainerLowest,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _ModuleNavItem(
            icon: Icons.home_rounded,
            label: 'Home',
            onTap: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const HomeScreen(),
                ),
              );
            },
          ),
          _ModuleNavItem(
            icon: Icons.grid_view_rounded,
            label: moduleLabel,
            active: true,
          ),
          _ModuleNavItem(
            icon: Icons.notifications_rounded,
            label: 'Notifikasi',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NotificationsScreen(
                    moduleScope: moduleScope,
                  ),
                ),
              );
            },
          ),
          _ModuleNavItem(
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

class _ModuleNavItem extends StatelessWidget {
  const _ModuleNavItem({
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
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? KColors.primaryFixedDim.withValues(alpha: 0.5)
              : null,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: active ? KColors.primary : KColors.onSurfaceVariant,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: active ? KColors.primary : KColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}