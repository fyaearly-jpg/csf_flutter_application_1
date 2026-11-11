import 'package:flutter/material.dart';
import 'repositories/auth_repository.dart';
import 'screens/home_router.dart';
import 'screens/login_screen.dart';
import 'utils/warna.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ClimateSmart Farm',
      debugShowCheckedModeBanner: false,
      theme: _tema(),
      home: const AuthGate(),
    );
  }
}

// Cek token tersimpan: belum ada -> Login, ada -> Home sesuai role
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<Widget> _start() async {
    final repo = AuthRepository();
    if (!await repo.isLoggedIn()) return const LoginScreen();
    return homeFor(await repo.savedRole());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _start(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return snap.data!;
      },
    );
  }
}

ThemeData _tema() {
  final skema = ColorScheme.fromSeed(seedColor: Warna.biru).copyWith(
    primary: Warna.biru,
    onPrimary: Colors.white,
    secondary: Warna.oranye,
    tertiary: Warna.hijau,
    error: Warna.merah,
    surface: Colors.white,
  );
  OutlineInputBorder garis(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: c, width: w),
      );
  const teksTombol = TextStyle(
      fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w600);

  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Poppins',
    colorScheme: skema,
    scaffoldBackgroundColor: Warna.krem,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Warna.teksUtama,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Warna.teksUtama,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shadowColor: const Color(0x22000000),
      surfaceTintColor: Colors.transparent,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      enabledBorder: garis(const Color(0xFFD9D2C7)),
      focusedBorder: garis(skema.primary, 2),
      errorBorder: garis(Warna.merah),
      focusedErrorBorder: garis(Warna.merah, 2),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 52),
        shape: const StadiumBorder(),
        textStyle: teksTombol,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 52),
        shape: const StadiumBorder(),
        textStyle: teksTombol,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(textStyle: teksTombol),
    ),
    chipTheme: ChipThemeData(
      shape: const StadiumBorder(),
      side: BorderSide.none,
      backgroundColor: Colors.white,
      selectedColor: skema.primary.withAlpha(40),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}
