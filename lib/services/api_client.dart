import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import 'token_storage.dart';

class ApiException implements Exception {
  final String code;
  final String message;
  final int? status;
  final Map<String, dynamic> details;

  ApiException(this.code, this.message, {this.status, this.details = const {}});

  @override
  String toString() => message;
}

class ApiClient {
  final TokenStorage storage = TokenStorage();

  Future<dynamic> get(String path, {bool auth = true}) =>
      _send('GET', path, auth: auth);

  Future<dynamic> post(String path, Map<String, dynamic> body,
          {bool auth = true}) =>
      _send('POST', path, body: body, auth: auth);

  Future<dynamic> patch(String path, Map<String, dynamic> body) =>
      _send('PATCH', path, body: body);

  Future<dynamic> delete(String path) => _send('DELETE', path);

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
    bool retry = true,
  }) async {
    final uri = Uri.parse('${AppConfig.baseUrl}$path');
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final token = await storage.accessToken;
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }

    http.Response res;
    try {
      final future = switch (method) {
        'GET' => http.get(uri, headers: headers),
        'DELETE' => http.delete(uri, headers: headers),
        'PATCH' => http.patch(uri, headers: headers, body: jsonEncode(body)),
        _ => http.post(uri, headers: headers, body: jsonEncode(body)),
      };
      res = await future.timeout(AppConfig.timeout);
    } on TimeoutException {
      throw ApiException('TIMEOUT', 'Server tidak merespons. Coba lagi.');
    } catch (_) {
      throw ApiException('TIDAK_ADA_KONEKSI',
          'Tidak bisa terhubung ke server. Cek koneksi dan alamat server.');
    }

    final json = res.body.isEmpty ? null : jsonDecode(utf8.decode(res.bodyBytes));

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return json is Map ? json['data'] : null;
    }

    final err = (json is Map ? json['error'] : null) as Map<String, dynamic>?;
    final code = err?['code'] as String? ?? 'SERVER_ERROR';

    // Access token habis -> refresh sekali, lalu ulangi request
    if (auth && retry && code == 'TOKEN_KEDALUWARSA') {
      if (await _refresh()) {
        return _send(method, path, body: body, auth: auth, retry: false);
      }
      await storage.clear();
      throw ApiException('TIDAK_TERAUTENTIKASI', 'Sesi habis, silakan masuk lagi.',
          status: 401);
    }

    throw ApiException(
      code,
      err?['message'] as String? ?? 'Terjadi kesalahan (${res.statusCode}).',
      status: res.statusCode,
      details: (err?['details'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }

  Future<bool> _refresh() async {
    final rt = await storage.refreshToken;
    if (rt == null) return false;
    try {
      final res = await http
          .post(
            Uri.parse('${AppConfig.baseUrl}/auth/refresh'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refresh_token': rt}),
          )
          .timeout(AppConfig.timeout);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body)['data'];
        await storage.saveAccess(data['access_token'] as String);
        return true;
      }
    } catch (_) {}
    return false;
  }
}
