import 'package:flutter/material.dart';
import '../models/katalog.dart';
import '../widgets/common.dart';

// Tindak lanjut rekomendasi: sudah dilakukan atau ditunda + catatan
class TindakanDialog extends StatefulWidget {
  const TindakanDialog({super.key});

  @override
  State<TindakanDialog> createState() => _TindakanDialogState();
}

class _TindakanDialogState extends State<TindakanDialog> {
  String _status = 'sudah';
  final _catatan = TextEditingController();

  @override
  void dispose() {
    _catatan.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tindak lanjut'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'sudah', label: Text('Sudah')),
                ButtonSegment(value: 'tunda', label: Text('Tunda')),
              ],
              selected: {_status},
              onSelectionChanged: (s) {
                setState(() {
                  _status = s.first;
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _catatan,
              maxLength: 120,
              decoration: const InputDecoration(
                labelText: 'Catatan (opsional)',
                hintText: 'Sudah dipupuk pagi tadi',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        FilledButton(
          onPressed: () => Navigator.pop(
              context, {'status': _status, 'catatan': _catatan.text.trim()}),
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}

// Laporan serangan hama atau penyakit yang dilihat petani di lahan
class LaporanSeranganDialog extends StatefulWidget {
  final List<OptKatalog> katalog;

  const LaporanSeranganDialog({super.key, required this.katalog});

  @override
  State<LaporanSeranganDialog> createState() => _LaporanSeranganDialogState();
}

class _LaporanSeranganDialogState extends State<LaporanSeranganDialog> {
  late String _kode = widget.katalog.first.kode;
  String _tingkat = 'sedang';
  final _catatan = TextEditingController();

  @override
  void dispose() {
    _catatan.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Lapor serangan'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _kode,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Yang terlihat',
                border: OutlineInputBorder(),
              ),
              items: widget.katalog
                  .map((k) => DropdownMenuItem(
                        value: k.kode,
                        child: Text('${k.nama} (${k.jenis})',
                            overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
              onChanged: (v) {
                setState(() {
                  _kode = v ?? _kode;
                });
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _tingkat,
              decoration: const InputDecoration(
                labelText: 'Tingkat serangan',
                border: OutlineInputBorder(),
              ),
              items: const ['rendah', 'sedang', 'tinggi']
                  .map((t) => DropdownMenuItem(value: t, child: Text(cap(t))))
                  .toList(),
              onChanged: (v) {
                setState(() {
                  _tingkat = v ?? _tingkat;
                });
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _catatan,
              maxLength: 120,
              decoration: const InputDecoration(
                labelText: 'Catatan (opsional)',
                hintText: 'Terlihat di pojok barat',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        FilledButton(
          onPressed: () => Navigator.pop(context, {
            'kode': _kode,
            'tingkat': _tingkat,
            'catatan': _catatan.text.trim(),
          }),
          child: const Text('Kirim'),
        ),
      ],
    );
  }
}
