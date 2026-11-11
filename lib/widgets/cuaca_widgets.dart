import 'package:flutter/material.dart';
import '../models/cuaca.dart';
import '../utils/warna.dart';
import 'common.dart';

// Kartu suhu besar + ikon cuaca
class KartuCuaca extends StatelessWidget {
  final Cuaca? cuaca;

  const KartuCuaca(this.cuaca, {super.key});

  @override
  Widget build(BuildContext context) {
    final suhu = cuaca?.terkini['suhu'];
    final hujan = cuaca?.terkini['curah_hujan'];
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
        child: Row(children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  suhu is num ? '${suhu.round()} °C' : '-',
                  style: const TextStyle(
                      fontSize: 44, fontWeight: FontWeight.w700, height: 1.1),
                ),
                const Text('Cuaca saat ini',
                    style: TextStyle(color: Warna.teksSekunder)),
              ],
            ),
          ),
          SizedBox(
            width: 100,
            height: 76,
            child: Stack(children: [
              const Positioned(
                top: 0,
                right: 10,
                child: Icon(Icons.wb_sunny_rounded, size: 46, color: Warna.oranye),
              ),
              const Positioned(
                bottom: 0,
                left: 0,
                child: Icon(Icons.cloud_rounded, size: 60, color: Warna.biru),
              ),
              if (hujan is num && hujan > 0)
                const Positioned(
                  bottom: 0,
                  right: 18,
                  child: Icon(Icons.water_drop_rounded, size: 20, color: Warna.biru),
                ),
            ]),
          ),
        ]),
      ),
    );
  }
}

// Empat kotak kondisi berwarna: kelembapan, hujan, angin, suhu tanah
class KondisiCuaca extends StatelessWidget {
  final Cuaca? cuaca;

  const KondisiCuaca(this.cuaca, {super.key});

  @override
  Widget build(BuildContext context) {
    String v(String k, String unit) {
      final n = cuaca?.terkini[k];
      return n is num ? '$n $unit' : '-';
    }

    Widget mini(IconData ikon, Color warna, String label, String nilai) => Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: warna.withAlpha(30),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: warna,
                child: Icon(ikon, size: 18, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            fontSize: 11, color: Warna.teksSekunder)),
                    Text(nilai,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ]),
          ),
        );

    return Column(children: [
      Row(children: [
        mini(Icons.water_drop_outlined, Warna.hijau, 'Kelembapan', v('kelembapan_udara', '%')),
        const SizedBox(width: 12),
        mini(Icons.grain, Warna.biru, 'Curah hujan', v('curah_hujan', 'mm')),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        mini(Icons.air, Warna.teal, 'Angin', v('kecepatan_angin', 'km/jam')),
        const SizedBox(width: 12),
        mini(Icons.thermostat, Warna.oranye, 'Suhu tanah', v('suhu_tanah', '°C')),
      ]),
    ]);
  }
}

// Grafik batang curah hujan 7 hari, lengkap dengan suhu maks dan min
class GrafikPrakiraan extends StatelessWidget {
  final List<Prakiraan> data;

  const GrafikPrakiraan(this.data, {super.key});

  Widget _kolom(Prakiraan p, double maks) {
    final hujan = (p.hujan ?? 0).toDouble();
    final tinggi = (hujan / maks * 90).clamp(4, 90).toDouble();
    final warna = hujan >= 12
        ? Warna.merah
        : hujan >= 6
            ? Warna.oranye
            : Warna.biru;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(p.hujan == null ? '-' : '${hujan.round()}',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Container(
          height: tinggi,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: warna,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 6),
        Text(tgl(p.tanggal), style: const TextStyle(fontSize: 11)),
        Text('${p.suhuMaks?.round() ?? '-'}°',
            style: const TextStyle(
                fontSize: 11, color: Warna.oranye, fontWeight: FontWeight.w600)),
        Text('${p.suhuMin?.round() ?? '-'}°',
            style: const TextStyle(fontSize: 11, color: Warna.teksSekunder)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final hari = data.take(7).toList();
    final maks = hari.fold<double>(1, (m, p) {
      final x = (p.hujan ?? 0).toDouble();
      return x > m ? x : m;
    });
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(children: [
              Icon(Icons.circle, size: 10, color: Warna.biru),
              SizedBox(width: 6),
              Text('Curah hujan (mm)', style: TextStyle(fontSize: 12)),
              SizedBox(width: 14),
              Icon(Icons.circle, size: 10, color: Warna.oranye),
              SizedBox(width: 6),
              Text('Suhu maks / min (°C)', style: TextStyle(fontSize: 12)),
            ]),
            const SizedBox(height: 12),
            SizedBox(
              height: 185,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [for (final p in hari) Expanded(child: _kolom(p, maks))],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
