import 'package:flutter/material.dart';
import '../utils/warna.dart';

String cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

// "2026-11-04" -> "04/11"
String tgl(String iso) {
  final p = iso.split('-');
  return p.length == 3 ? '${p[2]}/${p[1]}' : iso;
}

Color warnaTingkat(String t) => switch (t) {
      'tinggi' => Warna.merah,
      'sedang' => Warna.oranye,
      _ => Warna.hijau,
    };

class TingkatChip extends StatelessWidget {
  final String tingkat;
  const TingkatChip(this.tingkat, {super.key});

  @override
  Widget build(BuildContext context) {
    final c = warnaTingkat(tingkat);
    return Chip(
      label: Text(tingkat.toUpperCase(),
          style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 12)),
      backgroundColor: c.withAlpha(30),
      side: BorderSide(color: c),
      visualDensity: VisualDensity.compact,
    );
  }
}

class Bullets extends StatelessWidget {
  final List<String> items;
  const Bullets(this.items, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final s in items)
          Padding(padding: const EdgeInsets.only(top: 2), child: Text('• $s')),
      ],
    );
  }
}
