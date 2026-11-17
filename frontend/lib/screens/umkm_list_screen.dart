import 'dart:async';

import 'package:flutter/material.dart';

import '../models/api_response.dart';
import '../models/umkm.dart';
import '../services/umkm_service.dart';
import '../widgets/kategori_style.dart';
import 'umkm_detail_screen.dart';
import 'umkm_form_screen.dart';

class UmkmListScreen extends StatefulWidget {
  const UmkmListScreen({super.key});

  @override
  State<UmkmListScreen> createState() => _UmkmListScreenState();
}

class _UmkmListScreenState extends State<UmkmListScreen> {
  final _service = UmkmService();
  final _scroll = ScrollController();
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  final List<Umkm> _items = [];
  PaginationMeta? _meta;
  String? _kategori;
  bool _loading = false;
  bool _loadingMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 200) {
        _loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _service.fetchAll(
          page: 1, search: _searchCtrl.text.trim(), kategori: _kategori);
      setState(() {
        _items
          ..clear()
          ..addAll(res.data ?? []);
        _meta = res.meta;
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    final meta = _meta;
    if (_loading || _loadingMore || meta == null || !meta.hasNext) return;
    setState(() => _loadingMore = true);
    try {
      final res = await _service.fetchAll(
          page: meta.page + 1,
          search: _searchCtrl.text.trim(),
          kategori: _kategori);
      setState(() {
        _items.addAll(res.data ?? []);
        _meta = res.meta;
      });
    } on ApiException catch (e) {
      _toast(e.message, error: true);
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _load);
  }

  void _toast(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? Theme.of(context).colorScheme.error : null,
      ));
  }

  Future<void> _openForm([Umkm? umkm]) async {
    final msg = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => UmkmFormScreen(umkm: umkm)),
    );
    if (msg != null) {
      _toast(msg);
      _load();
    }
  }

  Future<void> _openDetail(Umkm umkm) async {
    final changed = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => UmkmDetailScreen(id: umkm.id!)),
    );
    if (changed != null) {
      _toast(changed);
      _load();
    }
  }

  Future<void> _confirmDelete(Umkm umkm) async {
    final ok = await confirmDeleteDialog(context, umkm.namaUmkm);
    if (ok != true) return;
    try {
      final res = await _service.delete(umkm.id!);
      _toast(res.message);
      _load();
    } on ApiException catch (e) {
      _toast(e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add_business_rounded),
        label: const Text('Tambah UMKM'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar.large(
              title: const Text('Direktori UMKM'),
              actions: [
                IconButton(
                    tooltip: 'Muat ulang',
                    onPressed: _load,
                    icon: const Icon(Icons.refresh_rounded)),
              ],
            ),
            SliverToBoxAdapter(child: _buildHeader(scheme)),
            ..._buildBody(),
            const SliverToBoxAdapter(child: SizedBox(height: 96)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          _meta == null
              ? 'Data UMKM dari REST API CodeIgniter 4'
              : '${_meta!.total} UMKM terdaftar',
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _searchCtrl,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Cari nama, pemilik, atau alamat…',
            prefixIcon: const Icon(Icons.search_rounded),
            isDense: true,
            suffixIcon: _searchCtrl.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      _searchCtrl.clear();
                      _load();
                    }),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _chip(null, 'Semua'),
              for (final k in Umkm.kategoriList) _chip(k, k),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _chip(String? value, String label) {
    final selected = _kategori == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        avatar: value == null
            ? null
            : Icon(KategoriStyle.of(value).icon,
                size: 16, color: KategoriStyle.of(value).color),
        showCheckmark: false,
        onSelected: (_) {
          setState(() => _kategori = value);
          _load();
        },
      ),
    );
  }

  List<Widget> _buildBody() {
    if (_loading && _items.isEmpty) {
      return const [
        SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator())),
      ];
    }
    if (_error != null) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _StateMessage(
            icon: Icons.cloud_off_rounded,
            title: 'Gagal memuat data',
            message: _error!,
            action: FilledButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Coba lagi')),
          ),
        ),
      ];
    }
    if (_items.isEmpty) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _StateMessage(
              icon: Icons.storefront_outlined,
              title: 'Belum ada UMKM',
              message: 'Tekan "Tambah UMKM" untuk menambahkan data.'),
        ),
      ];
    }
    return [
      if (_loading) const SliverToBoxAdapter(child: LinearProgressIndicator()),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverList.separated(
          itemCount: _items.length + (_loadingMore ? 1 : 0),
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            if (i >= _items.length) {
              return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()));
            }
            final u = _items[i];
            return _UmkmCard(
              umkm: u,
              onTap: () => _openDetail(u),
              onEdit: () => _openForm(u),
              onDelete: () => _confirmDelete(u),
            );
          },
        ),
      ),
    ];
  }
}

class _UmkmCard extends StatelessWidget {
  const _UmkmCard({
    required this.umkm,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final Umkm umkm;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final style = KategoriStyle.of(umkm.kategori);
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: scheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 4, 14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: style.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(style.icon, color: style.color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(umkm.namaUmkm,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    _line(context, Icons.person_outline_rounded, umkm.pemilik),
                    _line(context, Icons.place_outlined, umkm.alamat),
                    const SizedBox(height: 8),
                    KategoriBadge(umkm.kategori),
                  ]),
            ),
            PopupMenuButton<String>(
              onSelected: (v) => v == 'edit' ? onEdit() : onDelete(),
              itemBuilder: (_) => const [
                PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                        leading: Icon(Icons.edit_outlined),
                        title: Text('Edit'),
                        contentPadding: EdgeInsets.zero)),
                PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                        leading: Icon(Icons.delete_outline_rounded),
                        title: Text('Hapus'),
                        contentPadding: EdgeInsets.zero)),
              ],
            ),
          ]),
        ),
      ),
    );
  }

  Widget _line(BuildContext context, IconData icon, String text) {
    final c = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(children: [
        Icon(icon, size: 15, color: c),
        const SizedBox(width: 4),
        Expanded(
            child: Text(text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: c, fontSize: 13))),
      ]),
    );
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage(
      {required this.icon,
      required this.title,
      required this.message,
      this.action});

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 56, color: scheme.outline),
        const SizedBox(height: 12),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(message,
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.onSurfaceVariant)),
        if (action != null) ...[const SizedBox(height: 16), action!],
      ]),
    );
  }
}

Future<bool?> confirmDeleteDialog(BuildContext context, String nama) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: const Icon(Icons.delete_forever_rounded),
      title: const Text('Hapus UMKM?'),
      content: Text('Data "$nama" akan dihapus permanen.'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal')),
        FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus')),
      ],
    ),
  );
}
