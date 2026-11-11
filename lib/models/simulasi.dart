import 'prediksi.dart';

class Simulasi {
  final String penilaian; // cocok | hati_hati | tunda
  final String pesan, mulai, selesai;
  final Risiko? risiko;
  final List<Opt> penyakit, hama;
  final List<Musiman> musiman;

  Simulasi(this.penilaian, this.pesan, this.mulai, this.selesai, this.risiko,
      this.penyakit, this.hama, this.musiman);

  factory Simulasi.fromJson(Map<String, dynamic> j) {
    List<T> daftar<T>(String k, T Function(Map<String, dynamic>) f) =>
        ((j[k] as List?) ?? []).map((e) => f(e as Map<String, dynamic>)).toList();
    final k = j['kesimpulan'] as Map<String, dynamic>;
    final w = j['jendela'] as Map<String, dynamic>;
    final r = j['risiko_cuaca'] as Map<String, dynamic>?;
    return Simulasi(
      '${k['penilaian']}',
      '${k['pesan']}',
      '${w['mulai']}',
      '${w['selesai']}',
      r == null ? null : Risiko.fromJson(r),
      daftar('penyakit', Opt.fromJson),
      daftar('hama', Opt.fromJson),
      daftar('musiman', Musiman.fromJson),
    );
  }
}
