import 'package:flutter/material.dart';

import '../models/umkm.dart';
import '../services/umkm_service.dart';
import '../widgets/kategori_style.dart';
import 'umkm_form_screen.dart';
import 'umkm_list_screen.dart' show confirmDeleteDialog;

/// Detail UMKM: memanggil GET /umkm/{id}. Pop dengan pesan bila data berubah.
class UmkmDetailScreen extends StatefulWidget {
  const UmkmDetailScreen({super.key, required this.id});
  final int id;

  @override
  State<UmkmDetailScreen> createState() => _UmkmDetailScreenState();
}

class _UmkmDetailScreenState extends State<UmkmDetailScreen> {
  final _service = UmkmService();
  late Future<Umkm> _future;
  String? _changedMessage;

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  Future<Umkm> _fetch() async => (await _service.fetchById(widget.id)).data!;

  Future<void> _edit(Umkm umkm) async {
    final msg = await Navigator.push<String>(context,
        MaterialPageRoute(builder: (_) => UmkmFormScreen(umkm: umkm)));
    if (msg != null) {
      _changedMessage = msg;
      setState(() => _future = _fetch());
    }
  }

  Future<void> _delete(Umkm umkm) async {
    final ok = await confirmDeleteDialog(context, umkm.namaUmkm);
    if (ok != true || !mounted) return;
    try {
      final res = await _service.delete(umkm.id!);
      if (mounted) Navigator.pop(context, res.message);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _changedMessage);
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Detail UMKM')),
        body: FutureBuilder<Umkm>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Center(child: Text(snap.error.toString()));
            }
            return _content(snap.data!);
          },
        ),
      ),
    );
  }

  Widget _content(Umkm u) {
    final style = KategoriStyle.of(u.kategori);
    final scheme = Theme.of(context).colorScheme;
    return ListView(padding: const EdgeInsets.all(16), children: [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            style.color.withValues(alpha: 0.18),
            style.color.withValues(alpha: 0.05),
          ]),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: style.color,
            child: Icon(style.icon, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(u.namaUmkm,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              KategoriBadge(u.kategori),
            ]),
          ),
        ]),
      ),
      const SizedBox(height: 16),
      Card(
        elevation: 0,
        color: scheme.surfaceContainerLowest,
        child: Column(children: [
          _tile(Icons.tag_rounded, 'ID', '${u.id}'),
          _tile(Icons.person_outline_rounded, 'Pemilik', u.pemilik),
          _tile(Icons.place_outlined, 'Alamat', u.alamat),
          _tile(Icons.phone_outlined, 'Kontak', u.kontak),
          if (u.updatedAt != null)
            _tile(Icons.update_rounded, 'Terakhir diperbarui',
                u.updatedAt!.toString().substring(0, 16)),
        ]),
      ),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(
          child: FilledButton.icon(
              onPressed: () => _edit(u),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit')),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(foregroundColor: scheme.error),
              onPressed: () => _delete(u),
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Hapus')),
        ),
      ]),
    ]);
  }

  Widget _tile(IconData icon, String label, String value) => ListTile(
        leading: Icon(icon),
        title: Text(label,
            style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
        subtitle: Text(value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      );
}
