import '../models/laporan.dart';
import '../models/monitoring.dart';
import '../services/api_client.dart';

// Tindak lanjut, laporan serangan, dan monitoring
class InteraksiRepository {
  final ApiClient _api = ApiClient();

  // status: 'sudah' | 'tunda'
  Future<void> tindakan(int idRekomendasi, String status, String catatan) async {
    await _api.post('/rekomendasi/$idRekomendasi/tindakan', {
      'status': status,
      if (catatan.isNotEmpty) 'catatan': catatan,
    });
  }

  Future<void> kirimLaporan(
      int idLahan, String kode, String tingkat, String catatan) async {
    await _api.post('/lahan/$idLahan/laporan-serangan', {
      'kode': kode,
      'tingkat': tingkat,
      if (catatan.isNotEmpty) 'catatan': catatan,
    });
  }

  Future<List<Laporan>> laporanMenunggu() async {
    final data = await _api.get('/laporan-serangan?terverifikasi=null') as List;
    return data.map((e) => Laporan.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> verifikasi(int idLaporan, bool terkonfirmasi) async {
    await _api.patch(
        '/laporan-serangan/$idLaporan/verifikasi', {'terkonfirmasi': terkonfirmasi});
  }

  Future<List<Monitoring>> monitoring() async {
    final data = await _api.get('/monitoring/lahan-binaan') as List;
    return data
        .map((e) => Monitoring.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
