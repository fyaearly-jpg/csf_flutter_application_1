import 'package:flutter/material.dart';
import '../models/notifikasi.dart';
import '../repositories/notifikasi_repository.dart';
import '../services/api_client.dart';
import '../utils/warna.dart';
import '../widgets/common.dart';

class NotifikasiScreen extends StatefulWidget {
  const NotifikasiScreen({super.key});

  @override
  State<NotifikasiScreen> createState() => _NotifikasiScreenState();
}

class _NotifikasiScreenState extends State<NotifikasiScreen> {
  final _repo = NotifikasiRepository();
  late Future<List<Notifikasi>> _future = _repo.list();

  void _muatUlang() {
    setState(() {
      _future = _repo.list();
    });
  }

  Future<void> _baca(Notifikasi n) async {
    if (n.dibaca) return;
    try {
      await _repo.baca(n.id);
      if (!mounted) return;
      setState(() {
        n.dibaca = true;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifikasi')),
      body: FutureBuilder<List<Notifikasi>>(
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
                          child: Text('Belum ada notifikasi.',
                              textAlign: TextAlign.center),
                        ),
                      ])
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: daftar.length,
                        itemBuilder: (context, i) {
                          final n = daftar[i];
                          return Card(
                            child: ListTile(
                              leading: Icon(
                                n.tahap == 'saran'
                                    ? Icons.lightbulb_rounded
                                    : Icons.warning_rounded,
                                size: 34,
                                color: n.tahap == 'saran'
                                    ? Warna.kuningTua
                                    : Warna.merah,
                              ),
                              title: Text(
                                n.pesan,
                                style: TextStyle(
                                  fontWeight: n.dibaca
                                      ? FontWeight.normal
                                      : FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(tgl(n.tanggal)),
                              trailing: n.dibaca
                                  ? null
                                  : const Icon(Icons.circle,
                                      size: 10, color: Colors.red),
                              onTap: () => _baca(n),
                            ),
                          );
                        },
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}
