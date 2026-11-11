class Prakiraan {
  final String tanggal;
  final num? suhuMin, suhuMaks, hujan;

  Prakiraan(this.tanggal, this.suhuMin, this.suhuMaks, this.hujan);

  factory Prakiraan.fromJson(Map<String, dynamic> j) => Prakiraan(
        '${j['tanggal']}',
        j['suhu_min'] as num?,
        j['suhu_maks'] as num?,
        j['curah_hujan_total'] as num?,
      );
}

class Cuaca {
  final Map<String, dynamic> terkini; // suhu, kelembapan_udara, curah_hujan, ...
  final List<Prakiraan> prakiraan;

  Cuaca(this.terkini, this.prakiraan);

  factory Cuaca.fromJson(Map<String, dynamic> j) {
    final raw = j['prakiraan_harian'];
    return Cuaca(
      (j['terkini'] as Map?)?.cast<String, dynamic>() ?? {},
      raw is List
          ? raw.map((e) => Prakiraan.fromJson(e as Map<String, dynamic>)).toList()
          : [],
    );
  }
}
