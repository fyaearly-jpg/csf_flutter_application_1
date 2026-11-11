import 'package:flutter/material.dart';
import '../screens/session.dart';
import '../services/api_client.dart';

// Daftar yang dimuat dari API: loading, error + coba lagi, kosong, tarik untuk refresh.
// Sesi habis (401) otomatis kembali ke login.
class MuatDaftar<T> extends StatefulWidget {
  final Future<List<T>> Function() muat;
  final Widget Function(BuildContext context, T item, VoidCallback muatUlang) bangun;
  final String kosong;

  const MuatDaftar({
    super.key,
    required this.muat,
    required this.bangun,
    required this.kosong,
  });

  @override
  State<MuatDaftar<T>> createState() => MuatDaftarState<T>();
}

class MuatDaftarState<T> extends State<MuatDaftar<T>> {
  late Future<List<T>> _future = _muat();

  Future<List<T>> _muat() async {
    try {
      return await widget.muat();
    } on ApiException catch (e) {
      if (e.status == 401 && mounted) await keluarKeLogin(context);
      rethrow;
    }
  }

  void muatUlang() {
    setState(() {
      _future = _muat();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<T>>(
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
                      onPressed: muatUlang, child: const Text('Coba lagi')),
                ],
              ),
            ),
          );
        }
        final daftar = snap.data!;
        return RefreshIndicator(
          onRefresh: () async => muatUlang(),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: daftar.isEmpty
                  ? ListView(children: [
                      Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(widget.kosong, textAlign: TextAlign.center),
                      ),
                    ])
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: daftar.length,
                      itemBuilder: (context, i) =>
                          widget.bangun(context, daftar[i], muatUlang),
                    ),
            ),
          ),
        );
      },
    );
  }
}
