class Notifikasi {
  final int id;
  final String tahap; // 'waspada' | 'saran'
  final String pesan;
  final String tanggal;
  bool dibaca;

  Notifikasi({
    required this.id,
    required this.tahap,
    required this.pesan,
    required this.tanggal,
    required this.dibaca,
  });

  factory Notifikasi.fromJson(Map<String, dynamic> j) => Notifikasi(
        id: j['id_notifikasi'] as int,
        tahap: '${j['tahap']}',
        pesan: '${j['pesan']}',
        tanggal: '${j['tanggal']}',
        dibaca: j['dibaca'] == true,
      );
}
