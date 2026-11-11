class Laporan {
  final int idLaporan, idLahan;
  final String namaLahan, pemilik, kode, nama, tingkat, tanggal;
  final String? catatan;

  Laporan({
    required this.idLaporan,
    required this.idLahan,
    required this.namaLahan,
    required this.pemilik,
    required this.kode,
    required this.nama,
    required this.tingkat,
    required this.tanggal,
    this.catatan,
  });

  factory Laporan.fromJson(Map<String, dynamic> j) {
    final lahan = j['lahan'] as Map<String, dynamic>;
    final kode = '${j['kode']}';
    return Laporan(
      idLaporan: j['id_laporan'] as int,
      idLahan: lahan['id_lahan'] as int,
      namaLahan: '${lahan['nama_lahan']}',
      pemilik: '${lahan['pemilik']}',
      kode: kode,
      // KONTRAK hanya memuat kode; nama dipakai kalau server menyediakan
      nama: '${j['nama'] ?? kode.replaceAll('_', ' ')}',
      tingkat: '${j['tingkat']}',
      tanggal: '${j['tanggal']}',
      catatan: j['catatan'] as String?,
    );
  }
}
