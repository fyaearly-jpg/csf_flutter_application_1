import 'prediksi.dart' show strs;

class AntreanItem {
  final int idRekomendasi, idLahan, sisaMenit;
  final String namaLahan, pemilik, nama, tingkat, fase;
  final List<String> alasan, saran;
  final bool mendesak;

  AntreanItem({
    required this.idRekomendasi,
    required this.idLahan,
    required this.sisaMenit,
    required this.namaLahan,
    required this.pemilik,
    required this.nama,
    required this.tingkat,
    required this.fase,
    required this.alasan,
    required this.saran,
    required this.mendesak,
  });

  factory AntreanItem.fromJson(Map<String, dynamic> j) {
    final lahan = j['lahan'] as Map<String, dynamic>;
    return AntreanItem(
      idRekomendasi: j['id_rekomendasi'] as int,
      idLahan: lahan['id_lahan'] as int,
      sisaMenit: (j['sisa_menit'] as num).toInt(),
      namaLahan: '${lahan['nama_lahan']}',
      pemilik: '${lahan['pemilik']}',
      nama: '${j['nama']}',
      tingkat: '${j['tingkat']}',
      fase: '${j['fase']}',
      alasan: strs(j['alasan']),
      saran: strs(j['saran_diajukan']),
      mendesak: j['mendesak'] == true,
    );
  }

  String get sisaWaktu =>
      sisaMenit >= 60 ? '${sisaMenit ~/ 60} jam ${sisaMenit % 60} mnt' : '$sisaMenit mnt';
}
