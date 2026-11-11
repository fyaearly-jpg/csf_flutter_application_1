import '../models/notifikasi.dart';
import '../services/api_client.dart';

class NotifikasiRepository {
  final ApiClient _api = ApiClient();

  Future<List<Notifikasi>> list({bool? dibaca}) async {
    final q = dibaca == null ? '' : '&dibaca=$dibaca';
    final data = await _api.get('/notifikasi?per_page=50$q') as List;
    return data
        .map((e) => Notifikasi.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> baca(int id) async {
    await _api.patch('/notifikasi/$id/baca', {});
  }

  // Dipakai untuk badge lonceng. Kalau gagal (selain sesi habis), anggap 0
  Future<int> jumlahBelumDibaca() async {
    try {
      return (await list(dibaca: false)).length;
    } on ApiException catch (e) {
      if (e.status == 401) rethrow;
      return 0;
    }
  }
}
