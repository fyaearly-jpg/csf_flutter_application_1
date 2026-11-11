import 'package:flutter/widgets.dart';
import 'admin_home_screen.dart';
import 'home_screen.dart';
import 'penyuluh_home_screen.dart';

// Halaman utama dipilih dari role
Widget homeFor(String? role) => switch (role) {
      'penyuluh' => const PenyuluhHomeScreen(),
      'admin' => const AdminHomeScreen(),
      _ => const HomeScreen(),
    };
