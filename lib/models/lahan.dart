class Lahan {
  final int idLahan;
  final String namaLahan;
  final double lat;
  final double lon;
  final String komoditas;

  Lahan({
    required this.idLahan,
    required this.namaLahan,
    required this.lat,
    required this.lon,
    required this.komoditas,
  });

  factory Lahan.fromJson(Map<String, dynamic> j) => Lahan(
        idLahan: j['id_lahan'] as int,
        namaLahan: j['nama_lahan'] as String,
        lat: (j['lokasi']['lat'] as num).toDouble(),
        lon: (j['lokasi']['lon'] as num).toDouble(),
        komoditas: j['komoditas'] as String,
      );
}
