import 'package:flutter/material.dart';
import '../models/monitoring.dart';
import '../repositories/interaksi_repository.dart';
import '../widgets/common.dart';
import '../widgets/muat_daftar.dart';
import 'detail_lahan_screen.dart';

// Penyuluh: ringkasan risiko semua lahan binaan, diurutkan dari yang paling berisiko
class MonitoringTab extends StatelessWidget {
  const MonitoringTab({super.key});

  Widget _ringkas(String label, String tingkat) {
    final c = warnaTingkat(tingkat);
    return Chip(
      label: Text('$label: $tingkat', style: TextStyle(color: c, fontSize: 12)),
      side: BorderSide(color: c),
      backgroundColor: c.withAlpha(25),
      visualDensity: VisualDensity.compact,
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = InteraksiRepository();
    return MuatDaftar<Monitoring>(
      muat: repo.monitoring,
      kosong: 'Belum ada lahan binaan.',
      bangun: (context, m, muatUlang) => Card(
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  DetailLahanScreen(idLahan: m.idLahan, namaLahan: m.namaLahan),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(m.namaLahan,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  TingkatChip(m.risikoTertinggi),
                ]),
                Text('Pemilik: ${m.pemilik}'),
                const SizedBox(height: 8),
                Wrap(spacing: 8, children: [
                  _ringkas('Cuaca', m.cuaca),
                  _ringkas('Hama', m.hama),
                  _ringkas('Penyakit', m.penyakit),
                ]),
                const SizedBox(height: 4),
                Text('Antrean menunggu: ${m.antreanMenunggu} • '
                    'Laporan belum diverifikasi: ${m.laporanBelumDiverifikasi}'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
