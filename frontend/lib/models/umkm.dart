/// Model class untuk satu data UMKM.
/// Parsing JSON -> object via [Umkm.fromJson], object -> JSON via [toJson].
class Umkm {
  final int? id;
  final String namaUmkm;
  final String pemilik;
  final String alamat;
  final String kategori;
  final String kontak;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Umkm({
    this.id,
    required this.namaUmkm,
    required this.pemilik,
    required this.alamat,
    required this.kategori,
    required this.kontak,
    this.createdAt,
    this.updatedAt,
  });

  static const List<String> kategoriList = [
    'Kuliner',
    'Fashion',
    'Kerajinan',
    'Jasa',
    'Pertanian',
    'Lainnya',
  ];

  factory Umkm.fromJson(Map<String, dynamic> json) {
    return Umkm(
      // id bisa datang sebagai int atau String tergantung driver DB
      id: json['id'] == null ? null : int.tryParse(json['id'].toString()),
      namaUmkm: json['nama_umkm'] as String? ?? '',
      pemilik: json['pemilik'] as String? ?? '',
      alamat: json['alamat'] as String? ?? '',
      kategori: json['kategori'] as String? ?? '',
      kontak: json['kontak'] as String? ?? '',
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  /// Body untuk POST / PUT (tanpa id & timestamp).
  Map<String, dynamic> toJson() => {
        'nama_umkm': namaUmkm,
        'pemilik': pemilik,
        'alamat': alamat,
        'kategori': kategori,
        'kontak': kontak,
      };

  static DateTime? _parseDate(dynamic value) =>
      value == null ? null : DateTime.tryParse(value.toString());
}
