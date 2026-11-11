import '../models/user.dart';
import '../services/api_client.dart';

class AuthRepository {
  final ApiClient _api = ApiClient();

  Future<bool> isLoggedIn() async => (await _api.storage.accessToken) != null;

  Future<User> login(String username, String password) async {
    final data = await _api.post(
      '/auth/login',
      {'username': username, 'password': password},
      auth: false,
    );
    await _api.storage
        .saveTokens(data['access_token'] as String, data['refresh_token'] as String);
    final user = User.fromJson(data['user'] as Map<String, dynamic>);
    await _api.storage.saveRole(user.role);
    return user;
  }

  Future<String?> savedRole() => _api.storage.role;

  Future<void> register({
    required String nama,
    required String username,
    required String email,
    required String password,
    required String noWhatsapp,
    required String namaLahan,
    required double lat,
    required double lon,
  }) async {
    await _api.post(
      '/auth/register',
      {
        'nama': nama,
        'username': username,
        'email': email,
        'password': password,
        'no_whatsapp': noWhatsapp,
        'lahan': {
          'nama_lahan': namaLahan,
          'lokasi': {'lat': lat, 'lon': lon},
        },
      },
      auth: false,
    );
  }

  // Akun penyuluh berstatus pending sampai disetujui admin
  Future<void> registerPenyuluh({
    required String nama,
    required String username,
    required String email,
    required String password,
    required String noWhatsapp,
  }) async {
    await _api.post(
      '/auth/register-penyuluh',
      {
        'nama': nama,
        'username': username,
        'email': email,
        'password': password,
        'no_whatsapp': noWhatsapp,
      },
      auth: false,
    );
  }

  Future<User> me() async =>
      User.fromJson(await _api.get('/auth/me') as Map<String, dynamic>);

  Future<User> ubahProfil({
    required String nama,
    required String email,
    required String noWhatsapp,
    String? passwordLama,
    String? passwordBaru,
  }) async {
    final body = <String, dynamic>{
      'nama': nama,
      'email': email,
      'no_whatsapp': noWhatsapp,
    };
    if (passwordBaru != null && passwordBaru.isNotEmpty) {
      body['password_lama'] = passwordLama ?? '';
      body['password_baru'] = passwordBaru;
    }
    return User.fromJson(await _api.patch('/auth/me', body) as Map<String, dynamic>);
  }

  Future<void> logout() => _api.storage.clear();
}
