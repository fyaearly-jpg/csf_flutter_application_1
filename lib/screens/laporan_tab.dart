import 'package:flutter/material.dart';
import '../models/laporan.dart';
import '../repositories/interaksi_repository.dart';
import '../services/api_client.dart';
import '../widgets/common.dart';
import '../widgets/muat_daftar.dart';

// Penyuluh: laporan serangan dari petani yang menunggu verifikasi
class LaporanTab extends StatelessWidget {
  const LaporanTab({super.key});

  Future<void> _verifikasi(BuildContext context, InteraksiRepository repo,
      Laporan l, bool ya, VoidCallback muatUlang) async {
    try {
      await repo.verifikasi(l.idLaporan, ya);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ya
            ? 'Laporan dikonfirmasi, petani diberi tahu.'
            : 'Laporan ditandai belum terbukti.'),
      ));
      muatUlang();
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = InteraksiRepository();
    return MuatDaftar<Laporan>(
      muat: repo.laporanMenunggu,
      kosong: 'Tidak ada laporan serangan yang menunggu verifikasi.',
      bangun: (context, l, muatUlang) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                  child: Text(cap(l.nama),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                TingkatChip(l.tingkat),
              ]),
              Text('${l.namaLahan} • ${l.pemilik}'),
              Text('Dilaporkan ${tgl(l.tanggal)}'),
              if (l.catatan != null) ...[
                const SizedBox(height: 8),
                Text('Catatan petani: ${l.catatan}'),
              ],
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: 8,
                  children: [
                    TextButton(
                      onPressed: () => _verifikasi(context, repo, l, false, muatUlang),
                      child: const Text('Belum terbukti'),
                    ),
                    FilledButton(
                      onPressed: () => _verifikasi(context, repo, l, true, muatUlang),
                      child: const Text('Konfirmasi'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
