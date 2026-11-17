import 'package:flutter_test/flutter_test.dart';
import 'package:umkm_app/models/api_response.dart';
import 'package:umkm_app/models/umkm.dart';

void main() {
  test('parse list response dari API CI4', () {
    final json = {
      'success': true,
      'message': 'Data UMKM berhasil diambil',
      'data': [
        {
          'id': '1',
          'nama_umkm': 'Kopi Nusantara',
          'pemilik': 'Rafi A',
          'alamat': 'Jl. A. Yani No. 10, Banjarbaru',
          'kategori': 'Kuliner',
          'kontak': '08123456xxx',
          'created_at': '2026-11-17 06:31:07',
        }
      ],
      'meta': {'page': 1, 'per_page': 10, 'total': 1, 'total_pages': 1},
    };

    final res = ApiResponse<List<Umkm>>.fromJson(
        json,
        (d) => (d as List)
            .map((e) => Umkm.fromJson(e as Map<String, dynamic>))
            .toList());

    expect(res.success, isTrue);
    expect(res.data!.single.id, 1);
    expect(res.data!.single.namaUmkm, 'Kopi Nusantara');
    expect(res.meta!.hasNext, isFalse);
  });

  test('parse error response', () {
    final res = ApiResponse<Umkm>.fromJson({
      'success': false,
      'message': 'Gagal menambahkan data UMKM',
      'errors': {'nama_umkm': 'Nama UMKM wajib diisi'},
    }, null);
    expect(res.success, isFalse);
    expect(res.errors['nama_umkm'], 'Nama UMKM wajib diisi');
  });
}
