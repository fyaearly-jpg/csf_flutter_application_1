import 'package:flutter/material.dart';
import '../repositories/lahan_repository.dart';
import '../services/api_client.dart';
import '../utils/validators.dart';

class TambahLahanScreen extends StatefulWidget {
  const TambahLahanScreen({super.key});

  @override
  State<TambahLahanScreen> createState() => _TambahLahanScreenState();
}

class _TambahLahanScreenState extends State<TambahLahanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nama = TextEditingController();
  final _lat = TextEditingController();
  final _lon = TextEditingController();
  final _repo = LahanRepository();
  bool _loading = false;

  @override
  void dispose() {
    _nama.dispose();
    _lat.dispose();
    _lon.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _repo.tambah(
        _nama.text.trim(),
        Validators.toDouble(_lat.text),
        Validators.toDouble(_lon.text),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const koordinat = TextInputType.numberWithOptions(decimal: true, signed: true);
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Lahan')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                TextFormField(
                  controller: _nama,
                  decoration: const InputDecoration(
                    labelText: 'Nama lahan',
                    border: OutlineInputBorder(),
                  ),
                  validator: Validators.namaLahan,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _lat,
                  keyboardType: koordinat,
                  decoration: const InputDecoration(
                    labelText: 'Latitude',
                    hintText: '-7.6298',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => Validators.koordinat(v, lat: true),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _lon,
                  keyboardType: koordinat,
                  decoration: const InputDecoration(
                    labelText: 'Longitude',
                    hintText: '111.5239',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => Validators.koordinat(v, lat: false),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Simpan'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
