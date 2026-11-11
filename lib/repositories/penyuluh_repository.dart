import '../models/antrean.dart';
import '../services/api_client.dart';

class PenyuluhRepository {
  final ApiClient _api = ApiClient();

  Future<List<AntreanItem>> antrean() async {
    final data = await _api.get('/rekomendasi/antrean-validasi') as List;
    return data
        .map((e) => AntreanItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // aksi: 'setujui' | 'ubah' | 'tolak'. tingkat dan saran wajib hanya untuk 'ubah'
  Future<void> koreksi(
    int idRekomendasi,
    String aksi, {
    String? tingkat,
    List<String>? saran,
    String? catatan,
  }) async {
    final body = <String, dynamic>{'aksi': aksi};
    if (tingkat != null) body['tingkat'] = tingkat;
    if (saran != null) body['saran'] = saran;
    if (catatan != null && catatan.isNotEmpty) body['catatan'] = catatan;
    await _api.patch('/rekomendasi/$idRekomendasi/koreksi', body);
  }
}
