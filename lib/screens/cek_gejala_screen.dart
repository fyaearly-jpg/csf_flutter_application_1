import 'package:flutter/material.dart';
import '../models/katalog.dart';
import '../repositories/katalog_repository.dart';
import '../services/api_client.dart';
import '../utils/warna.dart';
import 'katalog_screen.dart';

// Cek gejala: satu pertanyaan per layar (Ya atau Tidak), lalu hasil kecocokan
class CekGejalaScreen extends StatefulWidget {
  const CekGejalaScreen({super.key});

  @override
  State<CekGejalaScreen> createState() => _CekGejalaScreenState();
}

class _CekGejalaScreenState extends State<CekGejalaScreen> {
  final _repo = KatalogRepository();
  late Future<List<Pertanyaan>> _future = _repo.pertanyaan();
  final Map<String, bool> _jawaban = {};
  int _i = 0;
  List<Kemungkinan>? _hasil;
  bool _loading = false;

  void _muatUlang() {
    setState(() {
      _future = _repo.pertanyaan();
    });
  }

  void _ulang() {
    setState(() {
      _i = 0;
      _jawaban.clear();
      _hasil = null;
    });
  }

  Future<void> _jawab(List<Pertanyaan> soal, bool ya) async {
    _jawaban[soal[_i].kode] = ya;
    if (_i < soal.length - 1) {
      setState(() {
        _i++;
      });
      return;
    }
    setState(() {
      _loading = true;
    });
    try {
      final h = await _repo.cekGejala(Map.of(_jawaban));
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
    return Scaffold(
      appBar: AppBar(title: const Text('Cek Gejala')),
      body: FutureBuilder<List<Pertanyaan>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${snap.error}', textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton(
                        onPressed: _muatUlang, child: const Text('Coba lagi')),
                  ],
                ),
              ),
            );
          }
          final soal = snap.data!;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Image.asset(
                      'assets/images/gejala_header.jpg',
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_hasil != null)
                    ..._tampilHasil(_hasil!)
                  else if (soal.isNotEmpty)
                    ..._tampilPertanyaan(soal),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _tampilPertanyaan(List<Pertanyaan> soal) {
    final q = soal[_i];
    return [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pertanyaan ${_i + 1} dari ${soal.length}',
                  style: const TextStyle(fontSize: 12, color: Warna.teksSekunder)),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: (_i + 1) / soal.length,
                minHeight: 8,
                borderRadius: BorderRadius.circular(8),
                color: Warna.oranye,
                backgroundColor: Warna.oranye.withAlpha(40),
              ),
              const SizedBox(height: 18),
              Text(q.teks,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
      if (_loading) const LinearProgressIndicator(),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(
          child: FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Warna.oranye),
            onPressed: _loading ? null : () => _jawab(soal, true),
            child: const Text('Ya'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            onPressed: _loading ? null : () => _jawab(soal, false),
            child: const Text('Tidak'),
          ),
        ),
      ]),
      if (_i > 0)
        TextButton(
          onPressed: _loading
              ? null
              : () {
                  setState(() {
                    _i--;
                  });
                },
          child: const Text('Pertanyaan sebelumnya'),
        ),
    ];
  }

  List<Widget> _tampilHasil(List<Kemungkinan> hasil) {
    return [
      const Padding(
        padding: EdgeInsets.fromLTRB(4, 0, 4, 10),
        child: Text('Kemungkinan penyebab',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      if (hasil.isEmpty)
        const Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Text('Tidak ada kecocokan dengan gejala yang Anda jawab "Ya".'),
          ),
        ),
      for (final k in hasil)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(k.nama,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                  Text('Kecocokan ${(k.kecocokan * 100).round()}%',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: k.kecocokan,
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(8),
                  color: k.kecocokan >= 0.7
                      ? Warna.merah
                      : k.kecocokan >= 0.4
                          ? Warna.oranye
                          : Warna.hijau,
                  backgroundColor: const Color(0xFFEFEAE2),
                ),
              ],
            ),
          ),
        ),
      const Padding(
        padding: EdgeInsets.all(8),
        child: Text('Hasil bersifat indikatif, bukan diagnosis. Hubungi penyuluh bila ragu.',
            style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
      ),
      const SizedBox(height: 8),
      FilledButton(
        style: FilledButton.styleFrom(backgroundColor: Warna.oranye),
        onPressed: _ulang,
        child: const Text('Ulangi cek gejala'),
      ),
      const SizedBox(height: 10),
      OutlinedButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const KatalogScreen()),
        ),
        child: const Text('Buka katalog'),
      ),
    ];
  }
}
