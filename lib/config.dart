class AppConfig {
  // Emulator Android: 10.0.2.2 = localhost laptop.
  // HP asli: ganti ke IP laptop, mis. http://192.168.1.5:5000/api/v1
  static const String baseUrl = 'http://10.0.2.2:5000/api/v1';
  static const Duration timeout = Duration(seconds: 10);
}
