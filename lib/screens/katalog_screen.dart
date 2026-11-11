import 'package:flutter/material.dart';
import '../models/katalog.dart';
import '../repositories/katalog_repository.dart';
import '../utils/warna.dart';
import '../widgets/common.dart';

// Katalog hama dan penyakit: kartu berfoto, pencarian, dan filter jenis.
// Foto diambil dari assets/images/opt/<kode>.jpg. Kalau belum ada, tampil ikon berwarna.
class KatalogScreen extends StatefulWidget {
  const KatalogScreen({super.key});

  @override
  State<KatalogScreen> createState() => _KatalogScreenState();
}

class _KatalogScreenState extends State<KatalogScreen> {
  final _repo = KatalogRepository();
  final _cari = TextEditingController();
  late Future<List<OptKatalog>> _future = _repo.opt();
  String _jenis = 'semua';

  @override
  void dispose() {
    _cari.dispose();
    super.dispose();
  }

  void _muat() {
    setState(() {
      _future = _repo.opt(q: _cari.text.trim());
    });
  }

  Color _warna(String jenis) => jenis == 'hama' ? Warna.oranye : Warna.merah;

  Widget _foto(OptKatalog k, {double? tinggi}) {
    final w = _warna(k.jenis);
    return Image.asset(
      'assets/images/opt/${k.kode}.jpg',
      width: double.infinity,
      height: tinggi,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stack) => Container(
        width: double.infinity,
        height: tinggi,
        color: w.withAlpha(35),
        child: Icon(
          k.jenis == 'hama' ? Icons.bug_report_rounded : Icons.healing_rounded,
          size: 48,
          color: w,
        ),
      ),
    );
  }

  Widget _chipJenis(OptKatalog k) {
    final w = _warna(k.jenis);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: w.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(cap(k.jenis),
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: w)),
    );
  }

  void _detail(OptKatalog k) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Warna.krem,
      builder: (_) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: _foto(k, tinggi: 200),
              ),
              const SizedBox(height: 14),
              Text(k.nama,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              _chipJenis(k),
              if (k.penyebab.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('Penyebab: ${k.penyebab}'),
              ],
              const SizedBox(height: 14),
              const Text('Gejala', style: TextStyle(fontWeight: FontWeight.w600)),
              Bullets(k.gejala),
              const SizedBox(height: 14),
              const Text('Pemberantasan & pencegahan',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              Bullets(k.pencegahan),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kartu(OptKatalog k) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _detail(k),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(aspectRatio: 1.15, child: _foto(k)),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(k.nama,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  _chipJenis(k),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Katalog Hama')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _cari,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _muat(),
              decoration: InputDecoration(
                hintText: 'Cari hama atau penyakit',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward_rounded),
                  onPressed: _muat,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Wrap(spacing: 8, children: [
                for (final j in const ['semua', 'hama', 'penyakit'])
                  ChoiceChip(
                    label: Text(cap(j)),
                    selected: _jenis == j,
                    onSelected: (_) {
                      setState(() {
                        _jenis = j;
                      });
                    },
                  ),
              ]),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<OptKatalog>>(
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
                              onPressed: _muat, child: const Text('Coba lagi')),
                        ],
                      ),
                    ),
                  );
                }
                final daftar = snap.data!
                    .where((k) => _jenis == 'semua' || k.jenis == _jenis)
                    .toList();
                if (daftar.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('Tidak ada hama atau penyakit yang cocok.',
                          textAlign: TextAlign.center),
                    ),
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: daftar.length,
                  itemBuilder: (context, i) => _kartu(daftar[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
