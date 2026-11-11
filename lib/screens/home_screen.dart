import 'package:flutter/material.dart';
import '../models/cuaca.dart';
import '../models/lahan.dart';
import '../models/user.dart';
import '../repositories/auth_repository.dart';
import '../repositories/lahan_repository.dart';
import '../repositories/notifikasi_repository.dart';
import '../services/api_client.dart';
import '../utils/warna.dart';
import '../widgets/common.dart';
import 'cek_gejala_screen.dart';
import 'detail_lahan_screen.dart';
import 'edit_dialogs.dart';
import 'katalog_screen.dart';
import 'login_screen.dart';
import 'notifikasi_screen.dart';
import 'tambah_lahan_screen.dart';

typedef HomeData = (User, List<Lahan>, int, Cuaca?); // user, lahan, notifikasi belum dibaca, cuaca lahan pertama

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _auth = AuthRepository();
  final _lahanRepo = LahanRepository();
  final _notifRepo = NotifikasiRepository();
  late Future<HomeData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<HomeData> _load() async {
    try {
      final user = await _auth.me();
      final lahan = await _lahanRepo.list();
      final petani = user.role == 'petani';
      final belumDibaca = petani ? await _notifRepo.jumlahBelumDibaca() : 0;
      Cuaca? cuaca;
      if (petani && lahan.isNotEmpty) {
        try {
          cuaca = await _lahanRepo.cuaca(lahan.first.idLahan);
        } on ApiException catch (e) {
          if (e.status == 401) rethrow;
        }
      }
      return (user, lahan, belumDibaca, cuaca);
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

  Future<void> _tambahLahan() async {
    final berhasil = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const TambahLahanScreen()),
    );
    if (berhasil == true) _muatUlang();
  }

  Future<void> _bukaNotifikasi() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotifikasiScreen()),
    );
    if (mounted) _muatUlang(); // segarkan badge lonceng
  }

  Future<void> _bukaDetail(Lahan l, User user) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailLahanScreen(
          idLahan: l.idLahan,
          namaLahan: l.namaLahan,
          bisaAtur: user.role == 'petani',
        ),
      ),
    );
  }

  Future<void> _ubahLahan(Lahan l) async {
    final h = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => EditLahanDialog(lahan: l),
    );
    if (h == null) return;
    try {
      await _lahanRepo.ubah(
        l.idLahan,
        h['nama']!,
        double.parse(h['lat']!.replaceAll(',', '.')),
        double.parse(h['lon']!.replaceAll(',', '.')),
      );
      if (!mounted) return;
      _muatUlang();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _ubahProfil() async {
    final berhasil = await ubahProfilFlow(context);
    if (berhasil && mounted) _muatUlang();
  }

  Future<void> _hapusLahan(Lahan l) async {
    final yakin = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus lahan?'),
        content: Text('Lahan "${l.namaLahan}" akan dihapus.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Hapus')),
        ],
      ),
    );
    if (yakin != true) return;
    try {
      await _lahanRepo.hapus(l.idLahan);
      if (!mounted) return;
      _muatUlang();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<HomeData>(
      future: _future,
      builder: (context, snap) {
        final user = snap.data?.$1;
        return Scaffold(
          appBar: AppBar(
            title: const Text('ClimateSmart Farm'),
            actions: [
              IconButton(
                tooltip: 'Keluar',
                icon: const Icon(Icons.logout),
                onPressed: _keLogin,
              ),
            ],
          ),
          floatingActionButton: user?.role == 'petani'
              ? FloatingActionButton.extended(
                  backgroundColor: Warna.oranye,
                  foregroundColor: Colors.white,
                  onPressed: _tambahLahan,
                  icon: const Icon(Icons.add),
                  label: const Text('Lahan'),
                )
              : null,
          body: _body(snap),
        );
      },
    );
  }

  Widget _body(AsyncSnapshot<HomeData> snap) {
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
              FilledButton(onPressed: _muatUlang, child: const Text('Coba lagi')),
            ],
          ),
        ),
      );
    }

    final (user, lahan, belumDibaca, cuaca) = snap.data!;
    final petani = user.role == 'petani';
    return RefreshIndicator(
      onRefresh: () async => _muatUlang(),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
            children: [
              _hero(user, lahan),
              if (petani) ...[
                const SizedBox(height: 16),
                _cuacaKartu(cuaca),
                _kondisi(cuaca),
                _judul('Akses cepat'),
                Row(children: [
                  Expanded(
                    child: _tile(Icons.menu_book_rounded, 'Katalog', Warna.hijau,
                        () => _buka(const KatalogScreen())),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _tile(Icons.fact_check_rounded, 'Cek gejala', Warna.oranye,
                        () => _buka(const CekGejalaScreen())),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _tile(Icons.notifications_rounded, 'Notifikasi', Warna.biru,
                        _bukaNotifikasi,
                        badge: belumDibaca),
                  ),
                ]),
              ],
              _judul('Lahan saya'),
              if (lahan.isEmpty)
                _kosong()
              else
                for (final l in lahan) _lahanKartu(l, user),
            ],
          ),
        ),
      ),
    );
  }

  void _buka(Widget layar) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => layar));

  Widget _judul(String teks) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 20, 4, 10),
        child: Text(teks,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      );

  Widget _hero(User u, List<Lahan> lahan) {
    Widget chip(IconData ikon, String teks) => Container(
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

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: SizedBox(
        height: 190,
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
              top: 6,
              right: 6,
              child: IconButton(
                tooltip: 'Edit profil',
                style: IconButton.styleFrom(backgroundColor: Colors.black26),
                icon: const Icon(Icons.edit_outlined, color: Colors.white),
                onPressed: _ubahProfil,
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
                  const Text('Halo,',
                      style: TextStyle(color: Colors.white70, fontSize: 14)),
                  Text(u.nama,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 6, children: [
                    chip(Icons.place,
                        lahan.isEmpty ? 'Belum ada lahan' : lahan.first.namaLahan),
                    chip(Icons.badge_outlined, cap(u.role)),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cuacaKartu(Cuaca? c) {
    final suhu = c?.terkini['suhu'];
    final hujan = c?.terkini['curah_hujan'];
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
        child: Row(children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  suhu is num ? '${suhu.round()} °C' : '-',
                  style: const TextStyle(
                      fontSize: 44, fontWeight: FontWeight.w700, height: 1.1),
                ),
                const Text('Cuaca saat ini',
                    style: TextStyle(color: Warna.teksSekunder)),
              ],
            ),
          ),
          SizedBox(
            width: 100,
            height: 76,
            child: Stack(children: [
              const Positioned(
                top: 0,
                right: 10,
                child: Icon(Icons.wb_sunny_rounded, size: 46, color: Warna.oranye),
              ),
              const Positioned(
                bottom: 0,
                left: 0,
                child: Icon(Icons.cloud_rounded, size: 60, color: Warna.biru),
              ),
              if (hujan is num && hujan > 0)
                const Positioned(
                  bottom: 0,
                  right: 18,
                  child: Icon(Icons.water_drop_rounded, size: 20, color: Warna.biru),
                ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _kondisi(Cuaca? c) {
    String v(String k, String unit, {bool persen = false}) {
      final n = c?.terkini[k];
      if (n is! num) return '-';
      return persen ? '${(n * 100).round()} %' : '$n $unit';
    }

    Widget mini(IconData ikon, Color warna, String label, String nilai) => Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: warna.withAlpha(30),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: warna,
                child: Icon(ikon, size: 18, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            fontSize: 11, color: Warna.teksSekunder)),
                    Text(nilai,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ]),
          ),
        );

    return Column(children: [
      Row(children: [
        mini(Icons.water_drop_outlined, Warna.hijau, 'Kelembapan',
            v('kelembapan_udara', '%')),
        const SizedBox(width: 12),
        mini(Icons.grain, Warna.biru, 'Curah hujan', v('curah_hujan', 'mm')),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        mini(Icons.air, Warna.teal, 'Angin', v('kecepatan_angin', 'km/jam')),
        const SizedBox(width: 12),
        mini(Icons.thermostat, Warna.oranye, 'Suhu tanah', v('suhu_tanah', '°C')),
      ]),
    ]);
  }

  Widget _tile(IconData ikon, String teks, Color warna, VoidCallback onTap,
      {int badge = 0}) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(children: [
            Badge(
              isLabelVisible: badge > 0,
              label: Text('$badge'),
              child: CircleAvatar(
                radius: 24,
                backgroundColor: warna.withAlpha(35),
                child: Icon(ikon, color: warna),
              ),
            ),
            const SizedBox(height: 8),
            Text(teks,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    );
  }

  Widget _lahanKartu(Lahan l, User user) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _bukaDetail(l, user),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/images/lahan_thumb.jpg',
                width: 64,
                height: 64,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.namaLahan,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    '${cap(l.komoditas)} • ${l.lat.toStringAsFixed(4)}, ${l.lon.toStringAsFixed(4)}',
                    style: const TextStyle(
                        fontSize: 12, color: Warna.teksSekunder),
                  ),
                ],
              ),
            ),
            if (user.role == 'petani')
              PopupMenuButton<String>(
                tooltip: 'Menu lahan',
                onSelected: (v) => v == 'edit' ? _ubahLahan(l) : _hapusLahan(l),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'hapus', child: Text('Hapus')),
                ],
              )
            else
              const Icon(Icons.chevron_right),
          ]),
        ),
      ),
    );
  }

  Widget _kosong() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(children: [
          Icon(Icons.grass, size: 40, color: Warna.hijau),
          SizedBox(height: 8),
          Text('Belum ada lahan. Tekan "Lahan" untuk menambah.',
              textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}
