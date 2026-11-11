import 'package:flutter/material.dart';
import '../models/cuaca.dart';
import '../models/prediksi.dart';
import '../repositories/interaksi_repository.dart';
import '../repositories/katalog_repository.dart';
import '../repositories/lahan_repository.dart';
import '../services/api_client.dart';
import '../utils/warna.dart';
import '../widgets/common.dart';
import '../widgets/cuaca_widgets.dart';
import 'dialog_interaksi.dart';
import 'musim_tanam_screen.dart';
import 'simulasi_screen.dart';

class DetailLahanScreen extends StatefulWidget {
  final int idLahan;
  final String namaLahan;
  final bool bisaAtur; // true untuk petani pemilik: boleh mulai musim tanam

  const DetailLahanScreen({
    super.key,
    required this.idLahan,
    required this.namaLahan,
    this.bisaAtur = false,
  });

  @override
  State<DetailLahanScreen> createState() => _DetailLahanScreenState();
}

class _DetailLahanScreenState extends State<DetailLahanScreen> {
  final _repo = LahanRepository();
  late Future<(Cuaca, Prediksi)> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<(Cuaca, Prediksi)> _load() async {
    final r = await Future.wait<Object>([
      _repo.cuaca(widget.idLahan),
      _repo.prediksi(widget.idLahan),
    ]);
    return (r[0] as Cuaca, r[1] as Prediksi);
  }

  void _muatUlang() {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _mulaiMusim() async {
    final hasil = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => const MusimTanamDialog(),
    );
    if (hasil == null) return;
    try {
      await _repo.mulaiMusim(
          widget.idLahan, hasil['tanggal']!, hasil['varietas']!);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Musim tanam dimulai.')));
      _muatUlang();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  final _interaksi = InteraksiRepository();
  final Map<int, String> _tindakan = {}; // id rekomendasi -> sudah | tunda (hanya di layar ini)

  void _pesan(String teks) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(teks)));

  Future<void> _beriTindakan(int idRek) async {
    final h = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => const TindakanDialog(),
    );
    if (h == null) return;
    try {
      await _interaksi.tindakan(idRek, h['status']!, h['catatan']!);
      if (!mounted) return;
      setState(() {
        _tindakan[idRek] = h['status']!;
      });
      _pesan('Tindak lanjut tersimpan.');
    } on ApiException catch (e) {
      if (mounted) _pesan(e.message);
    }
  }

  Future<void> _lapor() async {
    try {
      final katalog = await KatalogRepository().opt();
      if (!mounted) return;
      if (katalog.isEmpty) {
        _pesan('Katalog hama dan penyakit belum tersedia.');
        return;
      }
      final h = await showDialog<Map<String, String>>(
        context: context,
        builder: (_) => LaporanSeranganDialog(katalog: katalog),
      );
      if (h == null) return;
      await _interaksi.kirimLaporan(
          widget.idLahan, h['kode']!, h['tingkat']!, h['catatan']!);
      if (!mounted) return;
      _pesan('Laporan terkirim ke penyuluh.');
    } on ApiException catch (e) {
      if (mounted) _pesan(e.message);
    }
  }

  Future<void> _bukaRiwayatMusim() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            MusimTanamScreen(idLahan: widget.idLahan, namaLahan: widget.namaLahan),
      ),
    );
    if (mounted) _muatUlang();
  }

  Widget _tombolTindak(int id) => _tindakan.containsKey(id)
      ? Chip(
          label: Text(_tindakan[id] == 'sudah' ? 'Sudah ditangani' : 'Ditunda'),
          visualDensity: VisualDensity.compact,
        )
      : TextButton.icon(
          icon: const Icon(Icons.task_alt_outlined, size: 18),
          label: const Text('Tindak lanjut'),
          onPressed: () => _beriTindakan(id),
        );

  Widget _ikonTindak(int id) => _tindakan.containsKey(id)
      ? const Icon(Icons.check_circle, color: Colors.green)
      : IconButton(
          tooltip: 'Tindak lanjut',
          icon: const Icon(Icons.task_alt_outlined),
          onPressed: () => _beriTindakan(id),
        );


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.namaLahan)),
      body: FutureBuilder<(Cuaca, Prediksi)>(
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
          final (cuaca, p) = snap.data!;
          return RefreshIndicator(
            onRefresh: () async => _muatUlang(),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                  children: [
                    _hero(p),
                    if (widget.bisaAtur) ...[
                      _judul('Aksi cepat'),
                      _aksiBaris(),
                    ],
                    _judul('Cuaca saat ini'),
                    KartuCuaca(cuaca),
                    KondisiCuaca(cuaca),
                    if (cuaca.prakiraan.isNotEmpty) ...[
                      _judul('Prakiraan 7 hari'),
                      GrafikPrakiraan(cuaca.prakiraan),
                    ],
                    _judul('Fase tanam'),
                    _faseKartu(p),
                    if (p.risiko != null) ...[
                      _judul('Risiko cuaca'),
                      _risikoKartu(p.risiko!),
                    ],
                    if (p.jadwal.isNotEmpty) ...[
                      _judul('Jadwal kegiatan'),
                      for (final j in p.jadwal) _jadwalKartu(j),
                    ],
                    if (p.penyakit.isNotEmpty) ...[
                      _judul('Penyakit'),
                      for (final o in p.penyakit) _optCard(o),
                    ],
                    if (p.hama.isNotEmpty) ...[
                      _judul('Hama'),
                      for (final o in p.hama) _optCard(o),
                    ],
                    if (p.musiman.isNotEmpty) ...[
                      _judul('Kewaspadaan musiman'),
                      for (final m in p.musiman)
                        Card(
                          color: Warna.kuning.withAlpha(45),
                          child: ListTile(
                            leading: const Icon(Icons.warning_amber_rounded,
                                color: Warna.kuningTua),
                            title: Text(m.nama,
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(m.pesan),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _judul(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 20, 4, 10),
        child: Text(t,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      );

  Widget _chipFoto(IconData ikon, String teks) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.black38,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(ikon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(teks, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ]),
      );

  Widget _hero(Prediksi p) {
    final f = p.fase;
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: SizedBox(
        height: 170,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset('assets/images/hero_sawah.jpg', fit: BoxFit.cover),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xCC000000)],
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.namaLahan,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 6, children: [
                    _chipFoto(
                        Icons.eco,
                        f == null
                            ? 'Belum ada musim tanam'
                            : 'Fase ${cap(f.fase)} • ${f.hst} HST'),
                    if (p.risiko != null)
                      _chipFoto(Icons.shield_outlined, 'Risiko ${p.risiko!.tingkat}'),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _aksi(IconData ikon, String teks, Color warna, VoidCallback onTap) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: warna.withAlpha(35),
              child: Icon(ikon, color: warna),
            ),
            const SizedBox(height: 8),
            Text(teks,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    );
  }

  Widget _aksiBaris() {
    return Row(children: [
      Expanded(
        child: _aksi(
          Icons.science_rounded,
          'Simulasi',
          Warna.biru,
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SimulasiScreen(
                  idLahan: widget.idLahan, namaLahan: widget.namaLahan),
            ),
          ),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(child: _aksi(Icons.edit_calendar_rounded, 'Musim baru', Warna.hijau, _mulaiMusim)),
      const SizedBox(width: 8),
      Expanded(child: _aksi(Icons.history_rounded, 'Riwayat', Warna.ungu, _bukaRiwayatMusim)),
      const SizedBox(width: 8),
      Expanded(child: _aksi(Icons.report_rounded, 'Lapor', Warna.merah, _lapor)),
    ]);
  }

  Widget _faseKartu(Prediksi p) {
    final f = p.fase;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: f == null
            ? const Text('Belum ada musim tanam aktif.')
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(f.varietas,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Warna.hijau.withAlpha(35),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(cap(f.fase),
                          style: const TextStyle(
                              color: Warna.hijau, fontWeight: FontWeight.w600)),
                    ),
                  ]),
                  const SizedBox(height: 2),
                  Text('Tanam ${f.tanggalTanam}',
                      style: const TextStyle(color: Warna.teksSekunder)),
                  const SizedBox(height: 14),
                  LinearProgressIndicator(
                    value: (f.hst / 110).clamp(0, 1).toDouble(),
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(8),
                    color: Warna.hijau,
                    backgroundColor: Warna.hijau.withAlpha(40),
                  ),
                  const SizedBox(height: 6),
                  Text('${f.hst} HST dari ±110 hari',
                      style: const TextStyle(
                          fontSize: 12, color: Warna.teksSekunder)),
                ],
              ),
      ),
    );
  }

  Widget _risikoKartu(Risiko r) {
    const urut = ['rendah', 'sedang', 'tinggi'];
    const lampu = [Warna.hijau, Warna.kuning, Warna.merah];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(children: [
              for (var i = 2; i >= 0; i--)
                Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: urut[i] == r.tingkat ? lampu[i] : lampu[i].withAlpha(45),
                    shape: BoxShape.circle,
                  ),
                ),
            ]),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Risiko ${cap(r.tingkat)}',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: warnaTingkat(r.tingkat))),
                  const SizedBox(height: 4),
                  Bullets(r.alasan),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _jadwalKartu(Jadwal j) {
    final (ikon, warna) = switch (j.status) {
      'direkomendasikan' => (Icons.check_rounded, Warna.hijau),
      'ditunda' => (Icons.pause_rounded, Warna.oranye),
      _ => (Icons.visibility_rounded, Warna.biru),
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: warna.withAlpha(35),
              child: Icon(ikon, color: warna),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${cap(j.aktivitas)} • ${tgl(j.tanggal)}',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                  Text(cap(j.status),
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600, color: warna)),
                  if (j.alasan.isNotEmpty)
                    Text(j.alasan.join('\n'),
                        style: const TextStyle(
                            fontSize: 12, color: Warna.teksSekunder)),
                ],
              ),
            ),
            if (widget.bisaAtur && j.idRekomendasi != 0)
              _ikonTindak(j.idRekomendasi),
          ],
        ),
      ),
    );
  }

  Widget _saranBox(Opt o) {
    if (o.saranTersedia) {
      final valid = o.saranLabel == 'tervalidasi';
      final w = valid ? Warna.hijau : Warna.biru;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: w.withAlpha(28),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(valid ? Icons.verified_rounded : Icons.lightbulb_rounded,
                  size: 18, color: w),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  valid ? 'Saran tervalidasi penyuluh' : 'Saran (belum divalidasi)',
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600, color: w),
                ),
              ),
            ]),
            const SizedBox(height: 4),
            Bullets(o.saran),
            if (o.catatan != null) ...[
              const SizedBox(height: 4),
              Text('Catatan penyuluh: ${o.catatan}',
                  style: const TextStyle(fontSize: 12)),
            ],
          ],
        ),
      );
    }
    if (o.statusValidasi == 'menunggu') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFEFEAE2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Text('Saran menunggu validasi penyuluh.',
            style: TextStyle(fontSize: 12, color: Warna.teksSekunder)),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _optCard(Opt o) {
    final w = warnaTingkat(o.tingkat);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 6, color: w),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(o.nama,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                      TingkatChip(o.tingkat),
                    ]),
                    const SizedBox(height: 4),
                    Bullets(o.alasan),
                    if (o.pesanWaspada != null) ...[
                      const SizedBox(height: 8),
                      Text(o.pesanWaspada!,
                          style: const TextStyle(fontStyle: FontStyle.italic)),
                    ],
                    const SizedBox(height: 10),
                    _saranBox(o),
                    if (widget.bisaAtur && o.idRekomendasi != 0)
                      Align(
                        alignment: Alignment.centerRight,
                        child: _tombolTindak(o.idRekomendasi),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Dialog mulai musim tanam: pilih tanggal tanam + isi varietas
class MusimTanamDialog extends StatefulWidget {
  final DateTime? tanggalAwal;
  final String? varietasAwal;
  final String judul;

  const MusimTanamDialog({
    super.key,
    this.tanggalAwal,
    this.varietasAwal,
    this.judul = 'Mulai musim tanam',
  });

  @override
  State<MusimTanamDialog> createState() => _MusimTanamDialogState();
}

class _MusimTanamDialogState extends State<MusimTanamDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _varietas =
      TextEditingController(text: widget.varietasAwal ?? '');
  late DateTime _tanggal = widget.tanggalAwal ?? DateTime.now();

  @override
  void dispose() {
    _varietas.dispose();
    super.dispose();
  }

  String get _iso =>
      '${_tanggal.year}-${_tanggal.month.toString().padLeft(2, '0')}-${_tanggal.day.toString().padLeft(2, '0')}';

  Future<void> _pilihTanggal() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _tanggal,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
    );
    if (d != null) {
      setState(() {
        _tanggal = d;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.judul),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.calendar_today, size: 18),
              label: Text('Tanggal tanam: $_iso'),
              onPressed: _pilihTanggal,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _varietas,
              decoration: const InputDecoration(
                labelText: 'Varietas',
                hintText: 'Inpari 32',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                final s = v?.trim() ?? '';
                return (s.length < 2 || s.length > 60)
                    ? 'Varietas 2 sampai 60 karakter'
                    : null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal')),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(context, {
              'tanggal': _iso,
              'varietas': _varietas.text.trim(),
            });
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
