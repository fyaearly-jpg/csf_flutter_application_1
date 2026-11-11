import '../models/cuaca.dart';
import '../models/lahan.dart';
import '../models/musim.dart';
import '../models/prediksi.dart';
import '../models/simulasi.dart';
import '../services/api_client.dart';

class LahanRepository {
  final ApiClient _api = ApiClient();

  Future<List<Lahan>> list() async {
    final data = await _api.get('/lahan') as List;
    return data.map((e) => Lahan.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> tambah(String nama, double lat, double lon) async {
    await _api.post('/lahan', {
      'nama_lahan': nama,
      'lokasi': {'lat': lat, 'lon': lon},
    });
  }

  Future<void> ubah(int id, String nama, double lat, double lon) async {
    await _api.patch('/lahan/$id', {
      'nama_lahan': nama,
      'lokasi': {'lat': lat, 'lon': lon},
    });
  }

  Future<List<Musim>> daftarMusim(int id) async {
    final data = await _api.get('/lahan/$id/musim-tanam') as List;
    return data.map((e) => Musim.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> ubahMusim(int idMusim, String tanggal, String varietas) async {
    await _api.patch('/musim-tanam/$idMusim', {
      'tanggal_tanam': tanggal,
      'varietas': varietas,
    });
  }

  Future<void> hapus(int id) async {
    await _api.delete('/lahan/$id');
  }

  Future<void> mulaiMusim(int id, String tanggal, String varietas) async {
    await _api.post('/lahan/$id/musim-tanam', {
      'tanggal_tanam': tanggal,
      'varietas': varietas,
    });
  }

  Future<Simulasi> simulasi(int id, String tanggal) async => Simulasi.fromJson(
      await _api.post('/simulasi/waktu-tanam', {
        'id_lahan': id,
        'tanggal_tanam': tanggal,
      }) as Map<String, dynamic>);

  Future<Cuaca> cuaca(int id) async =>
      Cuaca.fromJson(await _api.get('/lahan/$id/cuaca') as Map<String, dynamic>);

  Future<Prediksi> prediksi(int id) async => Prediksi.fromJson(
      await _api.get('/lahan/$id/prediksi') as Map<String, dynamic>);
}
