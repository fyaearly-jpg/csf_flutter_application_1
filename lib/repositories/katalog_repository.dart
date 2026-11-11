import '../models/katalog.dart';
import '../services/api_client.dart';

class KatalogRepository {
  final ApiClient _api = ApiClient();

  Future<List<OptKatalog>> opt({String q = ''}) async {
    final data =
        await _api.get('/katalog/opt?q=${Uri.encodeQueryComponent(q)}') as List;
    return data
        .map((e) => OptKatalog.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Pertanyaan>> pertanyaan() async {
    final data = await _api.get('/katalog/cek-gejala/pertanyaan') as List;
    return data
        .map((e) => Pertanyaan.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Kemungkinan>> cekGejala(Map<String, bool> jawaban) async {
    final data = await _api.post('/katalog/cek-gejala', {
      'jawaban': [
        for (final e in jawaban.entries)
          {'kode_pertanyaan': e.key, 'jawaban': e.value},
      ],
    }) as Map<String, dynamic>;
    return (data['kemungkinan'] as List)
        .map((e) => Kemungkinan.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
