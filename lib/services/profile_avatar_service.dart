import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Nyimpen foto profil user LOKAL di HP (folder dokumen aplikasi),
/// tanpa backend Laravel. Foto disimpan TERPISAH per-username, supaya
/// kalau beberapa akun login gantian di device yang sama, tiap akun
/// tetap punya foto sendiri-sendiri (bukan saling menimpa/kebagi).
///
/// Dipakai bareng oleh ProfileScreen (buat ganti foto) dan HomeScreen
/// (buat nampilin di lingkaran avatar header) — begitu foto diganti di
/// satu tempat, otomatis update di tempat lain karena keduanya dengerin
/// ChangeNotifier yang sama.
///
/// Catatan: karena ini murni lokal, foto akan HILANG kalau app
/// di-uninstall atau pindah HP/device. Kalau nanti mau foto ini juga
/// tersimpan di server (biar muncul di Laravel web / device lain),
/// perlu ditambah endpoint upload di backend terpisah.
class ProfileAvatarService extends ChangeNotifier {
  ProfileAvatarService._();
  static final ProfileAvatarService instance = ProfileAvatarService._();

  File? photoFile;
  String? _loadedForUser;

  Future<File> _targetFile(String userKey) async {
    final dir = await getApplicationDocumentsDirectory();
    // Bersihin karakter yang gak aman buat nama file.
    final safeKey = userKey.replaceAll(RegExp(r'[^a-zA-Z0-9_.-]'), '_');
    return File('${dir.path}/profile_avatar_$safeKey.jpg');
  }

  /// Panggil dengan username user yang lagi login (dari
  /// AccessService.instance.username atau profile['username']). Kalau
  /// usernamenya beda dari yang terakhir di-load (ganti akun), otomatis
  /// switch ke foto milik user itu. Aman dipanggil berkali-kali dengan
  /// username yang sama — di-skip kalau memang belum berubah.
  Future<void> load(String userKey) async {
    if (userKey.isEmpty) return;
    if (_loadedForUser == userKey) return;

    _loadedForUser = userKey;
    final file = await _targetFile(userKey);
    photoFile = await file.exists() ? file : null;
    notifyListeners();
  }

  /// Simpan foto baru (hasil pilih dari kamera/galeri) sebagai foto
  /// profil MILIK userKey ini. Otomatis notify semua screen yang
  /// dengerin.
  Future<void> setPhoto(File source, String userKey) async {
    final target = await _targetFile(userKey);
    await target.writeAsBytes(await source.readAsBytes());

    _loadedForUser = userKey;
    // Instance File baru dipakai supaya widget yang nampilin Image.file
    // pasti rebuild (bukan cuma pakai path yang sama).
    photoFile = File(target.path);
    notifyListeners();
  }

  Future<void> clearPhoto(String userKey) async {
    final file = await _targetFile(userKey);
    if (await file.exists()) {
      await file.delete();
    }
    if (_loadedForUser == userKey) {
      photoFile = null;
    }
    notifyListeners();
  }

  /// Dipanggil pas logout, biar avatar tidak "nyangkut" nampilin foto
  /// user sebelumnya sesaat sebelum user berikutnya login & load()
  /// dipanggil ulang dengan username yang baru.
  void reset() {
    _loadedForUser = null;
    photoFile = null;
    notifyListeners();
  }
}