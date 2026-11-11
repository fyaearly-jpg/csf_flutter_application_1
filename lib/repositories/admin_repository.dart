import '../models/user.dart';
import '../services/api_client.dart';

class AdminRepository {
  final ApiClient _api = ApiClient();

  Future<List<User>> menunggu() async {
    final data = await _api.get('/users?status_akun=pending') as List;
    return data.map((e) => User.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<User>> semua() async {
    final data = await _api.get('/users') as List;
    return data.map((e) => User.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> tambah({
    required String nama,
    required String username,
    required String email,
    required String password,
    required String noWhatsapp,
    required String role,
  }) async {
    await _api.post('/users', {
      'nama': nama,
      'username': username,
      'email': email,
      'password': password,
      'no_whatsapp': noWhatsapp,
      'role': role,
    });
  }

  // status: 'aktif' | 'nonaktif'
  Future<void> ubahStatus(int idUser, String status) async {
    await _api.patch('/users/$idUser', {'status_akun': status});
  }

  Future<void> hapus(int idUser) async {
    await _api.delete('/users/$idUser');
  }

  // keputusan: 'setujui' | 'tolak'
  Future<void> putuskan(int idUser, String keputusan) async {
    await _api.patch('/users/$idUser/approve', {'keputusan': keputusan});
  }
}
