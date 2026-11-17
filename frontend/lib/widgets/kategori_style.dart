import 'package:flutter/material.dart';

/// Warna & ikon per kategori UMKM.
class KategoriStyle {
  final Color color;
  final IconData icon;
  const KategoriStyle(this.color, this.icon);

  static KategoriStyle of(String kategori) {
    switch (kategori) {
      case 'Kuliner':
        return const KategoriStyle(Color(0xFFE2711D), Icons.restaurant_rounded);
      case 'Fashion':
        return const KategoriStyle(Color(0xFFB5179E), Icons.checkroom_rounded);
      case 'Kerajinan':
        return const KategoriStyle(Color(0xFF7B5E2A), Icons.handyman_rounded);
      case 'Jasa':
        return const KategoriStyle(Color(0xFF1D6FE2), Icons.miscellaneous_services_rounded);
      case 'Pertanian':
        return const KategoriStyle(Color(0xFF2E8B57), Icons.agriculture_rounded);
      default:
        return const KategoriStyle(Color(0xFF6B7280), Icons.storefront_rounded);
    }
  }
}

class KategoriBadge extends StatelessWidget {
  const KategoriBadge(this.kategori, {super.key});
  final String kategori;

  @override
  Widget build(BuildContext context) {
    final style = KategoriStyle.of(kategori);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: style.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(style.icon, size: 13, color: style.color),
        const SizedBox(width: 4),
        Text(kategori,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: style.color)),
      ]),
    );
  }
}
