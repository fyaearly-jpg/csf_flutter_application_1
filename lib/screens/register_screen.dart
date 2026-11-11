import 'package:flutter/material.dart';
import '../repositories/auth_repository.dart';
import '../services/api_client.dart';
import '../utils/validators.dart';

class RegisterScreen extends StatefulWidget {
  final bool penyuluh; // true: daftar penyuluh (tanpa lahan, menunggu admin)

  const RegisterScreen({super.key, this.penyuluh = false});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nama = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _wa = TextEditingController();
  final _namaLahan = TextEditingController();
  final _lat = TextEditingController();
  final _lon = TextEditingController();
  final _repo = AuthRepository();
  bool _loading = false;

  @override
  void dispose() {
    for (final c in [_nama, _username, _email, _password, _wa, _namaLahan, _lat, _lon]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      if (widget.penyuluh) {
        await _repo.registerPenyuluh(
          nama: _nama.text.trim(),
          username: _username.text.trim(),
          email: _email.text.trim(),
          password: _password.text,
          noWhatsapp: _wa.text.trim(),
        );
      } else {
        await _repo.register(
          nama: _nama.text.trim(),
          username: _username.text.trim(),
          email: _email.text.trim(),
          password: _password.text,
          noWhatsapp: _wa.text.trim(),
          namaLahan: _namaLahan.text.trim(),
          lat: Validators.toDouble(_lat.text),
          lon: Validators.toDouble(_lon.text),
        );
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _field(
    TextEditingController c,
    String label,
    String? Function(String?) validator, {
    TextInputType? type,
    bool obscure = false,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: c,
        keyboardType: type,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
        validator: validator,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const koordinat = TextInputType.numberWithOptions(decimal: true, signed: true);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.penyuluh ? 'Daftar Penyuluh' : 'Daftar Petani'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const Text('Data akun',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _field(_nama, 'Nama lengkap', Validators.nama),
                _field(_username, 'Username', Validators.username),
                _field(_email, 'Email', Validators.email,
                    type: TextInputType.emailAddress),
                _field(_password, 'Kata sandi', Validators.password, obscure: true),
                _field(_wa, 'No. WhatsApp', Validators.whatsapp,
                    type: TextInputType.phone, hint: '081234567890'),
                if (widget.penyuluh)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Text('Akun penyuluh aktif setelah disetujui admin.'),
                  )
                else ...[
                  const SizedBox(height: 8),
                  const Text('Lahan pertama',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _field(_namaLahan, 'Nama lahan', Validators.namaLahan),
                  _field(_lat, 'Latitude', (v) => Validators.koordinat(v, lat: true),
                      type: koordinat, hint: '-7.6298'),
                  _field(_lon, 'Longitude', (v) => Validators.koordinat(v, lat: false),
                      type: koordinat, hint: '111.5239'),
                ],
                FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Daftar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
