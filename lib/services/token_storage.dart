import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static const _kAccess = 'access_token';
  static const _kRefresh = 'refresh_token';
  static const _kRole = 'role';

  Future<String?> get accessToken async =>
      (await SharedPreferences.getInstance()).getString(_kAccess);

  Future<String?> get refreshToken async =>
      (await SharedPreferences.getInstance()).getString(_kRefresh);

  Future<String?> get role async =>
      (await SharedPreferences.getInstance()).getString(_kRole);

  Future<void> saveRole(String role) async =>
      (await SharedPreferences.getInstance()).setString(_kRole, role);

  Future<void> saveAccess(String access) async =>
      (await SharedPreferences.getInstance()).setString(_kAccess, access);

  Future<void> saveTokens(String access, String refresh) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kAccess, access);
    await p.setString(_kRefresh, refresh);
  }

  Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kAccess);
    await p.remove(_kRefresh);
    await p.remove(_kRole);
  }
}
