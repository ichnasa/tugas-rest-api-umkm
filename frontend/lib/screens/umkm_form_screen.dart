import 'package:flutter/material.dart';

import '../models/umkm.dart';
import '../services/umkm_service.dart';
import '../widgets/kategori_style.dart';

/// Form tambah (POST) / edit (PUT) UMKM.
/// Error validasi dari server (HTTP 400 `errors`) ditampilkan per field.
class UmkmFormScreen extends StatefulWidget {
  const UmkmFormScreen({super.key, this.umkm});
  final Umkm? umkm;

  @override
  State<UmkmFormScreen> createState() => _UmkmFormScreenState();
}

class _UmkmFormScreenState extends State<UmkmFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = UmkmService();
  late final _nama = TextEditingController(text: widget.umkm?.namaUmkm);
  late final _pemilik = TextEditingController(text: widget.umkm?.pemilik);
  late final _alamat = TextEditingController(text: widget.umkm?.alamat);
  late final _kontak = TextEditingController(text: widget.umkm?.kontak);
  late String? _kategori = widget.umkm?.kategori;

  Map<String, String> _serverErrors = {};
  bool _saving = false;

  bool get _isEdit => widget.umkm != null;

  @override
  void dispose() {
    for (final c in [_nama, _pemilik, _alamat, _kontak]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _serverErrors = {});
    if (!_formKey.currentState!.validate()) return;

    final data = Umkm(
      namaUmkm: _nama.text.trim(),
      pemilik: _pemilik.text.trim(),
      alamat: _alamat.text.trim(),
      kategori: _kategori ?? '',
      kontak: _kontak.text.trim(),
    );

    setState(() => _saving = true);
    try {
      final res = _isEdit
          ? await _service.update(widget.umkm!.id!, data)
          : await _service.create(data);
      if (mounted) Navigator.pop(context, res.message);
    } on ApiException catch (e) {
      setState(() => _serverErrors = e.errors);
      _formKey.currentState!.validate();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Validasi lokal + tampilkan error dari server bila ada.
  String? Function(String?) _validator(String field, String label,
      {bool Function(String)? extra, String? extraMsg}) {
    return (v) {
      final value = v?.trim() ?? '';
      if (value.isEmpty) return '$label wajib diisi';
      if (extra != null && !extra(value)) return extraMsg;
      return _serverErrors[field];
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit UMKM' : 'Tambah UMKM')),
      body: Form(
        key: _formKey,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          TextFormField(
            controller: _nama,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
                labelText: 'Nama UMKM',
                prefixIcon: Icon(Icons.storefront_outlined)),
            validator: _validator('nama_umkm', 'Nama UMKM',
                extra: (v) => v.length >= 3,
                extraMsg: 'Nama UMKM minimal 3 karakter'),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _pemilik,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
                labelText: 'Pemilik',
                prefixIcon: Icon(Icons.person_outline_rounded)),
            validator: _validator('pemilik', 'Pemilik'),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _alamat,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
                labelText: 'Alamat',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.place_outlined)),
            validator: _validator('alamat', 'Alamat'),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _kategori,
            decoration: const InputDecoration(
                labelText: 'Kategori',
                prefixIcon: Icon(Icons.category_outlined)),
            items: [
              for (final k in Umkm.kategoriList)
                DropdownMenuItem(
                  value: k,
                  child: Row(children: [
                    Icon(KategoriStyle.of(k).icon,
                        size: 18, color: KategoriStyle.of(k).color),
                    const SizedBox(width: 8),
                    Text(k),
                  ]),
                ),
            ],
            onChanged: (v) => setState(() => _kategori = v),
            validator: (v) => v == null
                ? 'Kategori wajib dipilih'
                : _serverErrors['kategori'],
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _kontak,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
                labelText: 'Kontak (No. HP)',
                hintText: '08xxxxxxxxxx',
                prefixIcon: Icon(Icons.phone_outlined)),
            validator: _validator('kontak', 'Kontak',
                extra: (v) => RegExp(r'^[0-9+]{8,20}$').hasMatch(v),
                extraMsg: 'Kontak harus berupa nomor telepon (8-20 digit)'),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _saving ? null : _submit,
            style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52)),
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.save_outlined),
            label: Text(_isEdit ? 'Simpan Perubahan' : 'Tambah UMKM'),
          ),
        ]),
      ),
    );
  }
}
