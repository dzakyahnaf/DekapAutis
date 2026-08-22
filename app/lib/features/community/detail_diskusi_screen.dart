import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/theme/tokens.dart';
import '../../data/models/komunitas.dart';
import '../../data/providers.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/states.dart';
import 'komunitas_screen.dart';

/// One discussion and its replies.
class DetailDiskusiScreen extends ConsumerWidget {
  const DetailDiskusiScreen({required this.id, super.key});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postingan = ref.watch(postinganSatuProvider(id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diskusi'),
        actions: [
          IconButton(
            onPressed: () => _laporkan(context, ref, postinganId: id),
            icon: const Icon(Symbols.flag_rounded),
            tooltip: 'Laporkan tulisan ini',
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: postingan.when(
          loading: () => const LoadingText(),
          error: (e, _) => ErrorState(
            message: pesanKesalahan(e),
            onRetry: () => ref.invalidate(postinganSatuProvider(id)),
          ),
          data: (p) => p == null
              ? EmptyState(
                  message:
                      'Diskusi ini sudah tidak tersedia. Mungkin sedang '
                      'ditinjau moderator.',
                  actionLabel: 'Kembali ke komunitas',
                  onAction: () => context.go('/komunitas'),
                )
              : _Isi(postingan: p),
        ),
      ),
    );
  }
}

class _Isi extends ConsumerWidget {
  const _Isi({required this.postingan});

  final Postingan postingan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final balasan = ref.watch(balasanProvider(postingan.id));

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(DekapSpace.screenPadding),
            children: [
              Text(postingan.judul, style: text.titleLarge),
              const SizedBox(height: DekapSpace.cardGap / 2),
              Row(
                children: [
                  KepingPenulis(postingan: postingan),
                  const SizedBox(width: DekapSpace.cardGap),
                  if (postingan.dibuatPada != null)
                    Text(
                      waktuRelatif(postingan.dibuatPada!),
                      style: text.bodySmall,
                    ),
                ],
              ),
              const SizedBox(height: DekapSpace.cardGap),
              Text(postingan.isi, style: text.bodyMedium),

              const SizedBox(height: DekapSpace.screenPadding),
              Text(
                '${postingan.jumlahBalasan} balasan',
                style: text.titleMedium,
              ),
              const SizedBox(height: DekapSpace.cardGap),

              balasan.when(
                loading: () => const LoadingText(),
                error: (e, _) => ErrorState(
                  message: pesanKesalahan(e),
                  onRetry: () => ref.invalidate(balasanProvider(postingan.id)),
                ),
                data: (daftar) => daftar.isEmpty
                    ? const EmptyState(
                        message:
                            'Belum ada balasan. Satu kalimat dukungan pun '
                            'berarti bagi yang menulis.',
                      )
                    : Column(
                        children: [
                          for (final b in daftar) ...[
                            _KartuBalasan(balasan: b),
                            const SizedBox(height: DekapSpace.cardGap),
                          ],
                        ],
                      ),
              ),
            ],
          ),
        ),
        _KolomBalas(postinganId: postingan.id),
      ],
    );
  }
}

class _KartuBalasan extends ConsumerWidget {
  const _KartuBalasan({required this.balasan});

  final Balasan balasan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DekapSpace.cardPadding),
      decoration: BoxDecoration(
        color: DekapColors.cream50,
        borderRadius: BorderRadius.circular(DekapSpace.radiusCard),
        border: Border.all(
          color: DekapColors.border,
          width: DekapSpace.borderWidth,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(balasan.penulisTampil, style: text.labelSmall),
              const SizedBox(width: DekapSpace.cardGap),
              if (balasan.dibuatPada != null)
                Text(waktuRelatif(balasan.dibuatPada!), style: text.bodySmall),
              const Spacer(),
              IconButton(
                onPressed: () => _laporkan(context, ref, balasanId: balasan.id),
                icon: const Icon(Symbols.flag_rounded, size: 18),
                tooltip: 'Laporkan balasan ini',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: DekapSpace.cardGap / 2),
          Text(balasan.isi, style: text.bodyMedium),
        ],
      ),
    );
  }
}

class _KolomBalas extends ConsumerStatefulWidget {
  const _KolomBalas({required this.postinganId});

  final String postinganId;

  @override
  ConsumerState<_KolomBalas> createState() => _KolomBalasState();
}

class _KolomBalasState extends ConsumerState<_KolomBalas> {
  final _isi = TextEditingController();
  bool _anonim = false;
  bool _sibuk = false;

  @override
  void dispose() {
    _isi.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(DekapSpace.cardPadding),
    decoration: const BoxDecoration(
      color: DekapColors.surface,
      border: Border(
        top: BorderSide(
          color: DekapColors.border,
          width: DekapSpace.borderWidth,
        ),
      ),
    ),
    child: SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _isi,
            maxLines: 3,
            minLines: 1,
            decoration: const InputDecoration(hintText: 'Tulis balasan'),
          ),
          const SizedBox(height: DekapSpace.cardGap),
          Row(
            children: [
              Expanded(
                child: MergeSemantics(
                  child: Row(
                    children: [
                      Switch(
                        value: _anonim,
                        onChanged: (v) => setState(() => _anonim = v),
                      ),
                      Flexible(
                        child: Text(
                          'Anonim',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: DekapSpace.cardGap),
              PrimaryButton(
                label: _sibuk ? 'Menyimpan…' : 'Kirim balasan',
                expand: false,
                onPressed: _sibuk ? null : _kirim,
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Future<void> _kirim() async {
    if (_isi.text.trim().isEmpty) return;
    setState(() => _sibuk = true);

    try {
      final hasil = await ref
          .read(komunitasRepositoryProvider)
          .balas(
            postinganId: widget.postinganId,
            isi: _isi.text.trim(),
            anonim: _anonim,
          );
      if (!mounted) return;

      if (hasil.perluDitinjau) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(hasil.pesan)));
      } else {
        _isi.clear();
        ref.invalidate(balasanProvider(widget.postinganId));
        ref.invalidate(postinganSatuProvider(widget.postinganId));
      }
    } on Object catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(pesanKesalahan(e))));
    } finally {
      if (mounted) setState(() => _sibuk = false);
    }
  }
}

/// The report sheet, shared by the post header and every reply.
Future<void> _laporkan(
  BuildContext context,
  WidgetRef ref, {
  String? postinganId,
  String? balasanId,
}) async {
  final alasan = await showModalBottomSheet<AlasanLaporan>(
    context: context,
    backgroundColor: DekapColors.surface,
    builder: (sheet) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(DekapSpace.screenPadding),
        children: [
          Text(
            'Laporkan tulisan',
            style: Theme.of(sheet).textTheme.titleMedium,
          ),
          const SizedBox(height: DekapSpace.cardGap / 2),
          Text(
            'Laporan Anda hanya dibaca moderator. Penulisnya tidak diberi tahu '
            'siapa yang melapor.',
            style: Theme.of(sheet).textTheme.bodySmall,
          ),
          const SizedBox(height: DekapSpace.cardGap),
          for (final a in AlasanLaporan.values)
            ListTile(
              contentPadding: EdgeInsets.zero,
              minTileHeight: DekapSpace.minTouch,
              title: Text(a.label),
              onTap: () => Navigator.of(sheet).pop(a),
            ),
        ],
      ),
    ),
  );

  if (alasan == null || !context.mounted) return;

  try {
    await ref
        .read(komunitasRepositoryProvider)
        .laporkan(
          alasan: alasan,
          postinganId: postinganId,
          balasanId: balasanId,
        );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Laporan terkirim. Moderator akan meninjaunya.'),
      ),
    );
  } on Object catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(pesanKesalahan(e))));
  }
}
