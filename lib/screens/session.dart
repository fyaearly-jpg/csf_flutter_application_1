import 'package:flutter/material.dart';
import '../repositories/auth_repository.dart';
import 'login_screen.dart';

// Hapus sesi lalu kembali ke halaman login
Future<void> keluarKeLogin(BuildContext context) async {
  await AuthRepository().logout();
  if (!context.mounted) return;
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (_) => const LoginScreen()),
    (_) => false,
  );
}
