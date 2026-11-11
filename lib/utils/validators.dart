// Aturan sama dengan validasi di backend (KONTRAK API v1.0)
class Validators {
  static String? wajib(String? v, String label) =>
      (v == null || v.trim().isEmpty) ? '$label wajib diisi' : null;

  static String? nama(String? v) {
    final s = v?.trim() ?? '';
    if (s.length < 3 || s.length > 60) return 'Nama harus 3 sampai 60 karakter';
    return null;
  }

  static String? username(String? v) {
    if (v == null || !RegExp(r'^[A-Za-z0-9_.-]{3,30}$').hasMatch(v)) {
      return 'Username 3-30 karakter (huruf, angka, . _ -)';
    }
    return null;
  }

  static String? email(String? v) {
    if (v == null || !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) {
      return 'Format email tidak valid';
    }
    return null;
  }

  static String? password(String? v) {
    if (v == null || v.length < 8 || !RegExp(r'\d').hasMatch(v)) {
      return 'Minimal 8 karakter dan mengandung angka';
    }
    return null;
  }

  static String? whatsapp(String? v) {
    if (v == null || !RegExp(r'^(\+62|62|0)8\d{7,12}$').hasMatch(v)) {
      return 'Nomor tidak valid (contoh 081234567890)';
    }
    return null;
  }

  static String? namaLahan(String? v) =>
      (v == null || v.trim().length < 3) ? 'Nama lahan minimal 3 karakter' : null;

  static String? koordinat(String? v, {required bool lat}) {
    final n = double.tryParse((v ?? '').replaceAll(',', '.'));
    if (n == null) return 'Harus berupa angka';
    final batas = lat ? 90 : 180;
    if (n < -batas || n > batas) return 'Di luar rentang (-$batas sampai $batas)';
    return null;
  }

  static double toDouble(String v) => double.parse(v.replaceAll(',', '.'));
}
