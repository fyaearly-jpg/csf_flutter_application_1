List<String> strs(dynamic v) => ((v as List?) ?? []).map((e) => '$e').toList();

class Fase {
  final String tanggalTanam, varietas, fase;
  final int hst;

  Fase(this.tanggalTanam, this.varietas, this.fase, this.hst);

  factory Fase.fromJson(Map<String, dynamic> j) => Fase('${j['tanggal_tanam']}',
      '${j['varietas']}', '${j['fase']}', (j['hst'] as num?)?.toInt() ?? 0);
}

class Risiko {
  final String tingkat;
  final List<String> alasan;

  Risiko(this.tingkat, this.alasan);

  factory Risiko.fromJson(Map<String, dynamic> j) =>
      Risiko('${j['tingkat']}', strs(j['alasan']));
}

class Jadwal {
  final String aktivitas, status, tanggal;
  final List<String> alasan;
  final int idRekomendasi;

  Jadwal(this.aktivitas, this.status, this.tanggal, this.alasan,
      this.idRekomendasi);

  factory Jadwal.fromJson(Map<String, dynamic> j) => Jadwal(
      '${j['aktivitas']}',
      '${j['status']}',
      '${j['tanggal']}',
      strs(j['alasan']),
      (j['id_rekomendasi'] as num?)?.toInt() ?? 0);
}

// Penyakit atau hama
class Opt {
  final String nama, tingkat, statusValidasi;
  final String? pesanWaspada, saranLabel, catatan;
  final List<String> alasan, saran;
  final bool saranTersedia;
  final int idRekomendasi;

  Opt({
    required this.idRekomendasi,
    required this.nama,
    required this.tingkat,
    required this.statusValidasi,
    required this.alasan,
    required this.saran,
    required this.saranTersedia,
    this.pesanWaspada,
    this.saranLabel,
    this.catatan,
  });

  factory Opt.fromJson(Map<String, dynamic> j) => Opt(
        idRekomendasi: (j['id_rekomendasi'] as num?)?.toInt() ?? 0,
        nama: '${j['nama']}',
        tingkat: '${j['tingkat']}',
        statusValidasi: '${j['status_validasi'] ?? ''}',
        alasan: strs(j['alasan']),
        saran: strs(j['saran']),
        saranTersedia: j['saran_tersedia'] == true,
        pesanWaspada: j['pesan_waspada'] as String?,
        saranLabel: j['saran_label'] as String?,
        catatan: j['catatan_penyuluh'] as String?,
      );
}

class Musiman {
  final String nama, pesan;

  Musiman(this.nama, this.pesan);

  factory Musiman.fromJson(Map<String, dynamic> j) =>
      Musiman('${j['nama']}', '${j['pesan']}');
}

class Prediksi {
  final Fase? fase;
  final Risiko? risiko;
  final List<Jadwal> jadwal;
  final List<Opt> penyakit, hama;
  final List<Musiman> musiman;

  Prediksi(this.fase, this.risiko, this.jadwal, this.penyakit, this.hama,
      this.musiman);

  factory Prediksi.fromJson(Map<String, dynamic> j) {
    List<T> daftar<T>(String k, T Function(Map<String, dynamic>) f) =>
        ((j[k] as List?) ?? []).map((e) => f(e as Map<String, dynamic>)).toList();
    final f = j['fase'] as Map<String, dynamic>?;
    final r = j['risiko_cuaca'] as Map<String, dynamic>?;
    return Prediksi(
      f == null ? null : Fase.fromJson(f),
      r == null ? null : Risiko.fromJson(r),
      daftar('jadwal', Jadwal.fromJson),
      daftar('penyakit', Opt.fromJson),
      daftar('hama', Opt.fromJson),
      daftar('musiman', Musiman.fromJson),
    );
  }
}
