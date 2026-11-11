class Musim {
  final int idMusim, hst;
  final String tanggalTanam, varietas, fase;
  final bool aktif;

  Musim({
    required this.idMusim,
    required this.hst,
    required this.tanggalTanam,
    required this.varietas,
    required this.fase,
    required this.aktif,
  });

  factory Musim.fromJson(Map<String, dynamic> j) => Musim(
        idMusim: j['id_musim_tanam'] as int,
        hst: (j['hst'] as num?)?.toInt() ?? 0,
        tanggalTanam: '${j['tanggal_tanam']}',
        varietas: '${j['varietas']}',
        fase: '${j['fase']}',
        aktif: j['aktif'] == true,
      );
}
