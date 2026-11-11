import 'package:flutter/material.dart';
import '../models/lahan.dart';
import '../models/user.dart';
import '../repositories/auth_repository.dart';
import '../services/api_client.dart';
import '../utils/validators.dart';

const _angka = TextInputType.numberWithOptions(decimal: true, signed: true);

InputDecoration _dekor(String label, {String? hint}) =>
    InputDecoration(labelText: label, hintText: hint, border: const OutlineInputBorder());

Widget _jarak(Widget w) => Padding(padding: const EdgeInsets.only(bottom: 12), child: w);

// ---------------------------------------------------------------- Edit profil
class EditProfilDialog extends StatefulWidget {
  final User user;

  const EditProfilDialog({super.key, required this.user});

  @override
  State<EditProfilDialog> createState() => _EditProfilDialogState();
}

class _EditProfilDialogState extends State<EditProfilDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _nama = TextEditingController(text: widget.user.nama);
  late final _email = TextEditingController(text: widget.user.email ?? '');
  late final _wa = TextEditingController(text: widget.user.noWhatsapp ?? '');
  final _lama = TextEditingController();
  final _baru = TextEditingController();

  @override
  void dispose() {
    for (final c in [_nama, _email, _wa, _lama, _baru]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit profil'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _jarak(TextFormField(
                  controller: _nama, decoration: _dekor('Nama'), validator: Validators.nama)),
              _jarak(TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _dekor('Email'),
                  validator: Validators.email)),
              _jarak(TextFormField(
                  controller: _wa,
                  keyboardType: TextInputType.phone,
                  decoration: _dekor('No. WhatsApp'),
                  validator: Validators.whatsapp)),
              const Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text('Ganti kata sandi (kosongkan jika tidak)',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              _jarak(TextFormField(
                controller: _lama,
                obscureText: true,
                decoration: _dekor('Kata sandi lama'),
                validator: (v) => (_baru.text.isNotEmpty && (v == null || v.isEmpty))
                    ? 'Isi kata sandi lama'
                    : null,
              )),
              TextFormField(
                controller: _baru,
                obscureText: true,
                decoration: _dekor('Kata sandi baru'),
                validator: (v) =>
                    (v == null || v.isEmpty) ? null : Validators.password(v),
              ),
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
              'nama': _nama.text.trim(),
              'email': _email.text.trim(),
              'wa': _wa.text.trim(),
              'lama': _lama.text,
              'baru': _baru.text,
            });
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}

// Ambil profil terbaru, tampilkan dialog, simpan. true jika berhasil diubah.
Future<bool> ubahProfilFlow(BuildContext context) async {
  final repo = AuthRepository();
  try {
    final user = await repo.me();
    if (!context.mounted) return false;
    final h = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => EditProfilDialog(user: user),
    );
    if (h == null) return false;
    await repo.ubahProfil(
      nama: h['nama']!,
      email: h['email']!,
      noWhatsapp: h['wa']!,
      passwordLama: h['lama'],
      passwordBaru: h['baru'],
    );
    if (!context.mounted) return false;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Profil diperbarui.')));
    return true;
  } on ApiException catch (e) {
    if (!context.mounted) return false;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    return false;
  }
}

// ---------------------------------------------------------------- Edit lahan
class EditLahanDialog extends StatefulWidget {
  final Lahan lahan;

  const EditLahanDialog({super.key, required this.lahan});

  @override
  State<EditLahanDialog> createState() => _EditLahanDialogState();
}

class _EditLahanDialogState extends State<EditLahanDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _nama = TextEditingController(text: widget.lahan.namaLahan);
  late final _lat = TextEditingController(text: '${widget.lahan.lat}');
  late final _lon = TextEditingController(text: '${widget.lahan.lon}');

  @override
  void dispose() {
    _nama.dispose();
    _lat.dispose();
    _lon.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit lahan'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _jarak(TextFormField(
                  controller: _nama,
                  decoration: _dekor('Nama lahan'),
                  validator: Validators.namaLahan)),
              _jarak(TextFormField(
                  controller: _lat,
                  keyboardType: _angka,
                  decoration: _dekor('Latitude'),
                  validator: (v) => Validators.koordinat(v, lat: true))),
              TextFormField(
                  controller: _lon,
                  keyboardType: _angka,
                  decoration: _dekor('Longitude'),
                  validator: (v) => Validators.koordinat(v, lat: false)),
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
              'nama': _nama.text.trim(),
              'lat': _lat.text,
              'lon': _lon.text,
            });
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
