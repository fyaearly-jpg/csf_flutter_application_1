import 'package:flutter/material.dart';
import '../models/prediksi.dart';
import '../models/simulasi.dart';
import '../repositories/lahan_repository.dart';
import '../services/api_client.dart';
import '../widgets/common.dart';

class SimulasiScreen extends StatefulWidget {
  final int idLahan;
  final String namaLahan;

  const SimulasiScreen({super.key, required this.idLahan, required this.namaLahan});

  @override
  State<SimulasiScreen> createState() => _SimulasiScreenState();
}

class _SimulasiScreenState extends State<SimulasiScreen> {
  final _repo = LahanRepository();
  DateTime _tanggal = DateTime.now();
  bool _loading = false;
  Simulasi? _hasil;

  String get _iso =>
      '${_tanggal.year}-${_tanggal.month.toString().padLeft(2, '0')}-${_tanggal.day.toString().padLeft(2, '0')}';

  Future<void> _pilihTanggal() async {
    final now = DateTime.now();
    final hariIni = DateTime(now.year, now.month, now.day);
    final d = await showDatePicker(
      context: context,
      initialDate: _tanggal,
      firstDate: hariIni,
      lastDate: hariIni.add(const Duration(days: 9)), // jangkauan prakiraan 10 hari
    );
    if (d != null) {
      setState(() {
        _tanggal = d;
        _hasil = null;
      });
    }
  }

  Future<void> _simulasikan() async {
    setState(() {
      _loading = true;
    });
    try {
      final h = await _repo.simulasi(widget.idLahan, _iso);
      if (!mounted) return;
      setState(() {
        _hasil = h;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = _hasil;
    return Scaffold(
      appBar: AppBar(title: Text('Simulasi • ${widget.namaLahan}')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Pilih tanggal rencana tanam (0 sampai 9 hari dari hari ini), '
                        'lalu lihat risikonya.',
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: Text('Tanggal tanam: $_iso'),
                        onPressed: _pilihTanggal,
                      ),
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed: _loading ? null : _simulasikan,
                        child: _loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Simulasikan'),
                      ),
                    ],
                  ),
                ),
              ),
              if (h != null) ..._hasilWidgets(h),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _hasilWidgets(Simulasi h) {
    final warna = switch (h.penilaian) {
      'cocok' => Colors.green,
      'hati_hati' => Colors.orange,
      _ => Colors.red,
    };
    final label = switch (h.penilaian) {
      'cocok' => 'Cocok tanam',
      'hati_hati' => 'Hati-hati',
      _ => 'Sebaiknya ditunda',
    };

    Widget judul(String t) => Padding(
          padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
          child: Text(t,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        );

    Widget opt(Opt o) => Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(o.nama,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  TingkatChip(o.tingkat),
                ]),
                const SizedBox(height: 4),
                Bullets(o.alasan),
                if (o.saran.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text('Saran:',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  Bullets(o.saran),
                ],
              ],
            ),
          ),
        );

    return [
      const SizedBox(height: 16),
      Card(
        color: warna.withAlpha(30),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: warna),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold, color: warna)),
              const SizedBox(height: 4),
              Text(h.pesan),
              const SizedBox(height: 8),
              Text('Minggu pertama: ${tgl(h.mulai)} sampai ${tgl(h.selesai)}'),
            ],
          ),
        ),
      ),
      if (h.risiko != null) ...[
        judul('Risiko cuaca'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TingkatChip(h.risiko!.tingkat),
                const SizedBox(height: 8),
                Bullets(h.risiko!.alasan),
              ],
            ),
          ),
        ),
      ],
      if (h.penyakit.isNotEmpty) ...[judul('Penyakit'), for (final o in h.penyakit) opt(o)],
      if (h.hama.isNotEmpty) ...[judul('Hama'), for (final o in h.hama) opt(o)],
      if (h.musiman.isNotEmpty) ...[
        judul('Kewaspadaan musiman'),
        for (final m in h.musiman)
          Card(
            child: ListTile(
              leading: const Icon(Icons.warning_amber_outlined),
              title: Text(m.nama),
              subtitle: Text(m.pesan),
            ),
          ),
      ],
      const Padding(
        padding: EdgeInsets.all(12),
        child: Text('Hasil bersifat indikatif dan tidak disimpan.',
            style: TextStyle(fontStyle: FontStyle.italic)),
      ),
    ];
  }
}
