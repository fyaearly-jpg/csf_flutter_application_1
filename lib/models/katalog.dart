import 'prediksi.dart' show strs;

class OptKatalog {
  final String kode, nama, jenis, penyebab;
  final List<String> gejala, pencegahan;

  OptKatalog(this.kode, this.nama, this.jenis, this.penyebab, this.gejala,
      this.pencegahan);

  factory OptKatalog.fromJson(Map<String, dynamic> j) => OptKatalog(
        '${j['kode']}',
        '${j['nama']}',
        '${j['jenis']}',
        '${j['penyebab'] ?? ''}',
        strs(j['gejala']),
        strs(j['pencegahan']),
      );
}

class Pertanyaan {
  final String kode, teks;

  Pertanyaan(this.kode, this.teks);

  factory Pertanyaan.fromJson(Map<String, dynamic> j) =>
      Pertanyaan('${j['kode_pertanyaan']}', '${j['teks']}');
}

class Kemungkinan {
  final String kode, nama;
  final double kecocokan;

  Kemungkinan(this.kode, this.nama, this.kecocokan);

  factory Kemungkinan.fromJson(Map<String, dynamic> j) => Kemungkinan(
      '${j['kode']}', '${j['nama']}', (j['kecocokan'] as num).toDouble());
}
