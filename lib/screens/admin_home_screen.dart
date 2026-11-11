import 'package:flutter/material.dart';
import '../models/user.dart';
import '../repositories/admin_repository.dart';
import '../services/api_client.dart';
import '../utils/validators.dart';
import '../utils/warna.dart';
import '../widgets/common.dart';
import '../widgets/muat_daftar.dart';
import 'edit_dialogs.dart';
import 'session.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final _repo = AdminRepository();
  final _kunciMenunggu = GlobalKey<MuatDaftarState<User>>();
  final _kunciSemua = GlobalKey<MuatDaftarState<User>>();

  void _pesan(String teks) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(teks)));

  void _segarkan() {
    _kunciMenunggu.currentState?.muatUlang();
    _kunciSemua.currentState?.muatUlang();
  }

  Future<bool> _konfirmasi(String judul, String isi, String tombol) async {
    final r = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(judul),
        content: Text(isi),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tombol)),
        ],
      ),
    );
    return r == true;
  }

  Future<void> _jalankan(Future<void> Function() aksi, String sukses) async {
    try {
      await aksi();
      if (!mounted) return;
      _pesan(sukses);
      _segarkan();
    } on ApiException catch (e) {
      if (mounted) _pesan(e.message);
    }
  }

  Future<void> _putuskan(User u, String keputusan) async {
    final setuju = keputusan == 'setujui';
    final yakin = await _konfirmasi(
      setuju ? 'Setujui ${u.nama}?' : 'Tolak ${u.nama}?',
      setuju
          ? 'Akun ini akan aktif dan bisa masuk sebagai ${u.role}.'
          : 'Pendaftaran akun ini akan ditolak.',
      setuju ? 'Setujui' : 'Tolak',
    );
    if (!yakin) return;
    await _jalankan(() => _repo.putuskan(u.idUser, keputusan),
        setuju ? 'Akun disetujui.' : 'Akun ditolak.');
  }

  Future<void> _ubahStatus(User u) async {
    final aktif = u.statusAkun == 'aktif';
    final yakin = await _konfirmasi(
      aktif ? 'Nonaktifkan ${u.nama}?' : 'Aktifkan ${u.nama}?',
      aktif ? 'Akun ini tidak bisa masuk sampai diaktifkan lagi.' : 'Akun ini bisa masuk kembali.',
      aktif ? 'Nonaktifkan' : 'Aktifkan',
    );
    if (!yakin) return;
    await _jalankan(() => _repo.ubahStatus(u.idUser, aktif ? 'nonaktif' : 'aktif'),
        aktif ? 'Akun dinonaktifkan.' : 'Akun diaktifkan.');
  }

  Future<void> _hapus(User u) async {
    final yakin = await _konfirmasi(
        'Hapus ${u.nama}?', 'Akun dan data lahannya akan dihapus permanen.', 'Hapus');
    if (!yakin) return;
    await _jalankan(() => _repo.hapus(u.idUser), 'Pengguna dihapus.');
  }

  Future<void> _tambah() async {
    final h = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => const TambahPenggunaDialog(),
    );
    if (h == null) return;
    await _jalankan(
      () => _repo.tambah(
        nama: h['nama']!,
        username: h['username']!,
        email: h['email']!,
        password: h['password']!,
        noWhatsapp: h['wa']!,
        role: h['role']!,
      ),
      'Pengguna ditambahkan.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin'),
          bottom: const TabBar(tabs: [Tab(text: 'Kelola Pengguna'), Tab(text: 'Penyuluh Baru')]),
          actions: [
            IconButton(
              tooltip: 'Tambah pengguna',
              icon: const Icon(Icons.person_add_alt_1_outlined),
              onPressed: _tambah,
            ),
            IconButton(
              tooltip: 'Edit profil',
              icon: const Icon(Icons.manage_accounts_outlined),
              onPressed: () => ubahProfilFlow(context),
            ),
            IconButton(
              tooltip: 'Keluar',
              icon: const Icon(Icons.logout),
              onPressed: () => keluarKeLogin(context),
            ),
          ],
        ),
        body: TabBarView(children: [
          MuatDaftar<User>(
            key: _kunciSemua,
            muat: _repo.semua,
            kosong: 'Belum ada pengguna.',
            bangun: (context, u, muatUlang) => _kartuPengguna(u),
          ),
          MuatDaftar<User>(
            key: _kunciMenunggu,
            muat: _repo.menunggu,
            kosong: 'Tidak ada akun yang menunggu persetujuan.',
            bangun: (context, u, muatUlang) => _kartuMenunggu(u),
          ),
        ]),
      ),
    );
  }

  Widget _kartuMenunggu(User u) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: Warna.hijau.withAlpha(60),
                child: const Icon(Icons.person, size: 36, color: Warna.hijau),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(u.nama,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600)),
                    Text(u.username ?? '-',
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                    Text(u.email ?? '-',
                        style: const TextStyle(color: Warna.teksSekunder)),
                    Text(u.noWhatsapp ?? '-',
                        style: const TextStyle(color: Warna.teksSekunder)),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Warna.krem,
                    foregroundColor: Warna.merah,
                  ),
                  onPressed: () => _putuskan(u, 'tolak'),
                  child: const Text('Tolak'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: Warna.hijau),
                  onPressed: () => _putuskan(u, 'setujui'),
                  child: const Text('Setujui'),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _kartuPengguna(User u) {
    final bisaToggle = u.statusAkun == 'aktif' || u.statusAkun == 'nonaktif';
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(switch (u.role) {
            'admin' => Icons.admin_panel_settings_outlined,
            'penyuluh' => Icons.school_outlined,
            _ => Icons.agriculture_outlined,
          }),
        ),
        title: Text(u.nama),
        subtitle: Text('${cap(u.role)} • ${u.username ?? '-'} • ${u.statusAkun}'),
        trailing: PopupMenuButton<String>(
          onSelected: (v) => v == 'status' ? _ubahStatus(u) : _hapus(u),
          itemBuilder: (_) => [
            if (bisaToggle)
              PopupMenuItem(
                value: 'status',
                child: Text(u.statusAkun == 'aktif' ? 'Nonaktifkan' : 'Aktifkan'),
              ),
            const PopupMenuItem(value: 'hapus', child: Text('Hapus')),
          ],
        ),
      ),
    );
  }
}

class TambahPenggunaDialog extends StatefulWidget {
  const TambahPenggunaDialog({super.key});

  @override
  State<TambahPenggunaDialog> createState() => _TambahPenggunaDialogState();
}

class _TambahPenggunaDialogState extends State<TambahPenggunaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nama = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _wa = TextEditingController();
  String _role = 'penyuluh';

  @override
  void dispose() {
    for (final c in [_nama, _username, _email, _password, _wa]) {
      c.dispose();
    }
    super.dispose();
  }

  Widget _isian(TextEditingController c, String label, String? Function(String?) v,
      {TextInputType? type, bool obscure = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        keyboardType: type,
        obscureText: obscure,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        validator: v,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tambah pengguna'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _role,
                decoration: const InputDecoration(
                    labelText: 'Peran', border: OutlineInputBorder()),
                items: const ['petani', 'penyuluh', 'admin']
                    .map((r) => DropdownMenuItem(value: r, child: Text(cap(r))))
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    _role = v ?? _role;
                  });
                },
              ),
              const SizedBox(height: 12),
              _isian(_nama, 'Nama lengkap', Validators.nama),
              _isian(_username, 'Username', Validators.username),
              _isian(_email, 'Email', Validators.email, type: TextInputType.emailAddress),
              _isian(_password, 'Kata sandi', Validators.password, obscure: true),
              _isian(_wa, 'No. WhatsApp', Validators.whatsapp, type: TextInputType.phone),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(context, {
              'role': _role,
              'nama': _nama.text.trim(),
              'username': _username.text.trim(),
              'email': _email.text.trim(),
              'password': _password.text,
              'wa': _wa.text.trim(),
            });
          },
          child: const Text('Tambah'),
        ),
      ],
    );
  }
}
