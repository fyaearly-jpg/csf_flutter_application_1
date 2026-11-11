class Monitoring {
  final int idLahan, antreanMenunggu, laporanBelumDiverifikasi;
  final String namaLahan, pemilik, risikoTertinggi, cuaca, hama, penyakit;

  Monitoring({
    required this.idLahan,
    required this.antreanMenunggu,
    required this.laporanBelumDiverifikasi,
    required this.namaLahan,
    required this.pemilik,
    required this.risikoTertinggi,
    required this.cuaca,
    required this.hama,
    required this.penyakit,
  });

  factory Monitoring.fromJson(Map<String, dynamic> j) {
    final r = (j['ringkasan'] as Map?)?.cast<String, dynamic>() ?? {};
    return Monitoring(
      idLahan: j['id_lahan'] as int,
      antreanMenunggu: (j['antrean_menunggu'] as num?)?.toInt() ?? 0,
      laporanBelumDiverifikasi:
          (j['laporan_belum_diverifikasi'] as num?)?.toInt() ?? 0,
      namaLahan: '${j['nama_lahan']}',
      pemilik: '${j['pemilik']}',
      risikoTertinggi: '${j['risiko_tertinggi']}',
      cuaca: '${r['cuaca'] ?? '-'}',
      hama: '${r['hama'] ?? '-'}',
      penyakit: '${r['penyakit'] ?? '-'}',
    );
  }
}
