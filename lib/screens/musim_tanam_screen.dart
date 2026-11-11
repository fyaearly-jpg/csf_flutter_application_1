import 'package:flutter/material.dart';
import '../models/musim.dart';
import '../repositories/lahan_repository.dart';
import '../services/api_client.dart';
import '../widgets/common.dart';
import '../widgets/muat_daftar.dart';
import 'detail_lahan_screen.dart' show MusimTanamDialog;

// Riwayat musim tanam sebuah lahan: lihat, ubah, dan mulai musim baru
class MusimTanamScreen extends StatefulWidget {
  final int idLahan;
  final String namaLahan;

  const MusimTanamScreen({super.key, required this.idLahan, required this.namaLahan});

  @override
  State<MusimTanamScreen> createState() => _MusimTanamScreenState();
}

class _MusimTanamScreenState extends State<MusimTanamScreen> {
  final _repo = LahanRepository();
  final _kunci = GlobalKey<MuatDaftarState<Musim>>();

  void _pesan(String teks) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(teks)));

  Future<void> _baru() async {
    final h = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => const MusimTanamDialog(),
    );
    if (h == null) return;
    try {
      await _repo.mulaiMusim(widget.idLahan, h['tanggal']!, h['varietas']!);
      if (!mounted) return;
      _pesan('Musim tanam baru dimulai.');
      _kunci.currentState?.muatUlang();
    } on ApiException catch (e) {
      if (mounted) _pesan(e.message);
    }
  }

  Future<void> _ubah(Musim m) async {
    final h = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => MusimTanamDialog(
        judul: 'Ubah musim tanam',
        tanggalAwal: DateTime.tryParse(m.tanggalTanam),
        varietasAwal: m.varietas,
      ),
    );
    if (h == null) return;
    try {
      await _repo.ubahMusim(m.idMusim, h['tanggal']!, h['varietas']!);
      if (!mounted) return;
      _pesan('Musim tanam diperbarui.');
      _kunci.currentState?.muatUlang();
    } on ApiException catch (e) {
      if (mounted) _pesan(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Musim tanam • ${widget.namaLahan}')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _baru,
        icon: const Icon(Icons.add),
        label: const Text('Musim baru'),
      ),
      body: MuatDaftar<Musim>(
        key: _kunci,
        muat: () => _repo.daftarMusim(widget.idLahan),
        kosong: 'Belum ada musim tanam. Tekan "Musim baru" untuk memulai.',
        bangun: (context, m, muatUlang) => Card(
          child: ListTile(
            leading: Icon(m.aktif ? Icons.eco : Icons.history),
            title: Text('${m.varietas} • ${tgl(m.tanggalTanam)}'),
            subtitle: Text('${m.hst} HST • fase ${m.fase}${m.aktif ? ' • aktif' : ''}'),
            trailing: IconButton(
              tooltip: 'Ubah',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _ubah(m),
            ),
          ),
        ),
      ),
    );
  }
}
