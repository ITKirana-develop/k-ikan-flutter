class AppConfig {
  AppConfig._();

  /// Base URL server Laravel. Ganti di sini kalau mau pindah
  /// environment (localhost / mykfin.com / production), tidak perlu
  /// cari-cari satu-satu di tiap file lagi.
  static const String baseUrl = 'http://127.0.0.1:8000';
}