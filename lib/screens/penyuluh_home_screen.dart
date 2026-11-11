import 'package:flutter/material.dart';
import '../models/antrean.dart';
import '../repositories/auth_repository.dart';
import '../repositories/penyuluh_repository.dart';
import '../services/api_client.dart';
import '../utils/warna.dart';
import '../widgets/common.dart';
import 'detail_lahan_screen.dart';
import 'edit_dialogs.dart';
import 'laporan_tab.dart';
import 'monitoring_tab.dart';
import 'login_screen.dart';

class PenyuluhHomeScreen extends StatefulWidget {
  const PenyuluhHomeScreen({super.key});

  @override
  State<PenyuluhHomeScreen> createState() => _PenyuluhHomeScreenState();
}

class _PenyuluhHomeScreenState extends State<PenyuluhHomeScreen> {
  final _auth = AuthRepository();
  final _repo = PenyuluhRepository();
  late Future<List<AntreanItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<AntreanItem>> _load() async {
    try {
      return await _repo.antrean();
    } on ApiException catch (e) {
      if (e.status == 401) await _keLogin();
      rethrow;
    }
  }

  Future<void> _keLogin() async {
    await _auth.logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _muatUlang() {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _koreksi(AntreanItem item, String aksi) async {
    final hasil = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => KoreksiDialog(aksi: aksi, item: item),
    );
    if (hasil == null) return;
    try {
      await _repo.koreksi(
        item.idRekomendasi,
        aksi,
        tingkat: hasil['tingkat'] as String?,
        saran: hasil['saran'] as List<String>?,
        catatan: hasil['catatan'] as String?,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(aksi == 'tolak'
            ? 'Rekomendasi ditolak.'
            : 'Koreksi terkirim ke petani.'),
      ));
      _muatUlang();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _temaUngu(context),
      child: DefaultTabController(
      length: 3,
      child: Scaffold(
      appBar: AppBar(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
        title: const Text('Penyuluh'),
        bottom: const TabBar(tabs: [
          Tab(text: 'Antrean'),
          Tab(text: 'Laporan'),
          Tab(text: 'Monitoring'),
        ]),
        actions: [
          IconButton(
            tooltip: 'Edit profil',
            icon: const Icon(Icons.manage_accounts_outlined),
            onPressed: () => ubahProfilFlow(context),
          ),
          IconButton(
            tooltip: 'Keluar',
            icon: const Icon(Icons.logout),
            onPressed: _keLogin,
          ),
        ],
      ),
      body: TabBarView(children: [
      FutureBuilder<List<AntreanItem>>(
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
          final daftar = snap.data!;
          return RefreshIndicator(
            onRefresh: () async => _muatUlang(),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: daftar.isEmpty
                    ? ListView(children: const [
                        Padding(
                          padding: EdgeInsets.all(32),
                          child: Text(
                            'Tidak ada rekomendasi yang menunggu validasi.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ])
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: daftar.length,
                        itemBuilder: (context, i) => _kartu(i + 1, daftar[i]),
                      ),
              ),
            ),
          );
        },
      ),
      const LaporanTab(),
      const MonitoringTab(),
    ]),
    )));
  }

  Widget _kartu(int urutan, AntreanItem a) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Text('#$urutan  ${a.nama}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              TingkatChip(a.tingkat),
            ]),
            Text('${a.namaLahan} • ${a.pemilik}'),
            const SizedBox(height: 4),
            Row(children: [
              if (a.mendesak) ...[
                const Icon(Icons.priority_high, color: Colors.red, size: 18),
                const Text('Mendesak  ',
                    style: TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold)),
              ],
              Flexible(
                child: Text('Fase ${a.fase} • sisa ${a.sisaWaktu}',
                    overflow: TextOverflow.ellipsis),
              ),
            ]),
            const Divider(height: 24),
            Bullets(a.alasan),
            if (a.saran.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Saran diajukan:',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              Bullets(a.saran),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.grass, size: 18),
                  label: const Text('Lahan'),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DetailLahanScreen(
                          idLahan: a.idLahan, namaLahan: a.namaLahan),
                    ),
                  ),
                ),
                TextButton(
                    onPressed: () => _koreksi(a, 'tolak'),
                    child: const Text('Tolak')),
                OutlinedButton(
                    onPressed: () => _koreksi(a, 'ubah'),
                    child: const Text('Ubah')),
                FilledButton(
                    onPressed: () => _koreksi(a, 'setujui'),
                    child: const Text('Setujui')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Dialog untuk setujui / ubah / tolak. Hasilnya Map berisi tingkat, saran, catatan
class KoreksiDialog extends StatefulWidget {
  final String aksi;
  final AntreanItem item;

  const KoreksiDialog({super.key, required this.aksi, required this.item});

  @override
  State<KoreksiDialog> createState() => _KoreksiDialogState();
}

class _KoreksiDialogState extends State<KoreksiDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _saran =
      TextEditingController(text: widget.item.saran.join('\n'));
  final _catatan = TextEditingController();
  late String _tingkat = widget.item.tingkat;

  @override
  void dispose() {
    _saran.dispose();
    _catatan.dispose();
    super.dispose();
  }

  void _kirim() {
    if (!_formKey.currentState!.validate()) return;
    final hasil = <String, dynamic>{'catatan': _catatan.text.trim()};
    if (widget.aksi == 'ubah') {
      hasil['tingkat'] = _tingkat;
      hasil['saran'] = _saran.text
          .split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    Navigator.pop(context, hasil);
  }

  @override
  Widget build(BuildContext context) {
    final ubah = widget.aksi == 'ubah';
    final judul = switch (widget.aksi) {
      'setujui' => 'Setujui ${widget.item.nama}?',
      'ubah' => 'Ubah ${widget.item.nama}',
      _ => 'Tolak ${widget.item.nama}?',
    };
    return AlertDialog(
      title: Text(judul),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (ubah) ...[
                DropdownButtonFormField<String>(
                  initialValue: _tingkat,
                  decoration: const InputDecoration(labelText: 'Tingkat baru'),
                  items: const ['rendah', 'sedang', 'tinggi']
                      .map((t) => DropdownMenuItem(value: t, child: Text(cap(t))))
                      .toList(),
                  onChanged: (v) => setState(() => _tingkat = v ?? _tingkat),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _saran,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Saran (satu per baris)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Saran baru wajib diisi'
                      : null,
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _catatan,
                maxLength: 120,
                decoration: const InputDecoration(
                  labelText: 'Catatan (opsional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal')),
        FilledButton(onPressed: _kirim, child: const Text('Kirim')),
      ],
    );
  }
}

// Penyuluh memakai aksen ungu supaya jelas berbeda dari petani
ThemeData _temaUngu(BuildContext context) {
  final dasar = Theme.of(context);
  final skema = ColorScheme.fromSeed(seedColor: Warna.ungu);
  return dasar.copyWith(
    colorScheme: skema,
    appBarTheme: dasar.appBarTheme.copyWith(
      backgroundColor: skema.primary,
      foregroundColor: Colors.white,
      titleTextStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white70,
      indicatorColor: Colors.white,
      dividerColor: Colors.transparent,
    ),
  );
}
