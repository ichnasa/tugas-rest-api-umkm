import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/api_response.dart';
import '../models/umkm.dart';

/// Error dari API (validasi 400, 404, 500) atau jaringan.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, String> errors;

  ApiException(this.message, {this.statusCode, this.errors = const {}});

  @override
  String toString() => message;
}

/// Service yang membungkus semua endpoint /api/umkm memakai package `http`.
class UmkmService {
  UmkmService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('${ApiConfig.baseUrl}$path').replace(queryParameters: query);

  /// GET /umkm?page=&per_page=&search=&kategori=
  Future<ApiResponse<List<Umkm>>> fetchAll({
    int page = 1,
    int perPage = 10,
    String? search,
    String? kategori,
  }) {
    final query = <String, String>{
      'page': '$page',
      'per_page': '$perPage',
      if (search != null && search.isNotEmpty) 'search': search,
      if (kategori != null && kategori.isNotEmpty) 'kategori': kategori,
    };
    return _send(
      () => _client.get(_uri('/umkm', query), headers: _headers),
      (data) => (data as List)
          .map((e) => Umkm.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// GET /umkm/{id}
  Future<ApiResponse<Umkm>> fetchById(int id) => _send(
        () => _client.get(_uri('/umkm/$id'), headers: _headers),
        (data) => Umkm.fromJson(data as Map<String, dynamic>),
      );

  /// POST /umkm
  Future<ApiResponse<Umkm>> create(Umkm umkm) => _send(
        () => _client.post(_uri('/umkm'),
            headers: _headers, body: jsonEncode(umkm.toJson())),
        (data) => Umkm.fromJson(data as Map<String, dynamic>),
      );

  /// PUT /umkm/{id}
  Future<ApiResponse<Umkm>> update(int id, Umkm umkm) => _send(
        () => _client.put(_uri('/umkm/$id'),
            headers: _headers, body: jsonEncode(umkm.toJson())),
        (data) => Umkm.fromJson(data as Map<String, dynamic>),
      );

  /// DELETE /umkm/{id}
  Future<ApiResponse<Map<String, dynamic>>> delete(int id) => _send(
        () => _client.delete(_uri('/umkm/$id'), headers: _headers),
        (data) => Map<String, dynamic>.from(data as Map),
      );

  /// Kirim request, decode JSON, lempar [ApiException] bila gagal.
  Future<ApiResponse<T>> _send<T>(
    Future<http.Response> Function() request,
    T Function(dynamic data) parse,
  ) async {
    final http.Response res;
    try {
      res = await request().timeout(ApiConfig.timeout);
    } on TimeoutException {
      throw ApiException('Server tidak merespons (timeout). Coba lagi.');
    } catch (_) {
      throw ApiException(
          'Tidak dapat terhubung ke server ${ApiConfig.baseUrl}. '
          'Pastikan backend CI4 sudah berjalan.');
    }

    final Map<String, dynamic> body;
    try {
      body = jsonDecode(res.body) as Map<String, dynamic>;
    } on FormatException {
      throw ApiException('Response bukan JSON valid (HTTP ${res.statusCode}).',
          statusCode: res.statusCode);
    }

    final parsed = ApiResponse<T>.fromJson(body, parse);
    if (res.statusCode >= 400 || !parsed.success) {
      throw ApiException(parsed.message,
          statusCode: res.statusCode, errors: parsed.errors);
    }
    return parsed;
  }
}
