import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/strings.dart';
import '../../core/theme/tokens.dart';
import '../../data/models/direktori.dart';
import '../../data/providers.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/states.dart';
import 'admin_shell.dart';

/// Admin: the professional verification queue.
///
/// Plain on purpose. What matters is that approving really lights the badge and
/// rejecting really puts it out - both proved in `test_lingkaran_penuh.sql` -
/// and that a rejection cannot be sent without a reason.
class VerifikasiScreen extends ConsumerWidget {
  const VerifikasiScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final antrean = ref.watch(antreanVerifikasiProvider);

    return AdminShell(
      current: AdminTab.verifikasi,
      title: S.titleVerifikasi,
      child: antrean.when(
        loading: () => const LoadingText(),
        error: (e, _) => ErrorState(
          message: pesanKesalahan(e),
          onRetry: () => ref.invalidate(antreanVerifikasiProvider),
        ),
        data: (daftar) => daftar.isEmpty
            ? const EmptyState(
                message:
                    'Tidak ada praktik yang menunggu peninjauan. Pengajuan '
                    'baru muncul di sini begitu profil praktik dikirim.',
              )
            : ListView.separated(
                padding: const EdgeInsets.all(DekapSpace.screenPadding),
                itemCount: daftar.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: DekapSpace.cardGap),
                itemBuilder: (_, i) => _KartuPengajuan(profesional: daftar[i]),
              ),
      ),
    );
  }
}

class _KartuPengajuan extends ConsumerStatefulWidget {
  const _KartuPengajuan({required this.profesional});

  final Profesional profesional;

  @override
  ConsumerState<_KartuPengajuan> createState() => _KartuPengajuanState();
}

class _KartuPengajuanState extends ConsumerState<_KartuPengajuan> {
  bool _sibuk = false;
  bool _menolak = false;
  final _alasan = TextEditingController();
  String? _kabar;

  @override
  void dispose() {
    _alasan.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.profesional;
    final text = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(DekapSpace.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(p.namaDenganGelar, style: text.titleMedium),
            Text(p.spesialisasi, style: text.bodySmall),
            if (p.kota != null) Text(p.kota!, style: text.bodySmall),

            if (p.tentang != null && p.tentang!.isNotEmpty) ...[
              const SizedBox(height: DekapSpace.cardGap),
              Text(p.tentang!, style: text.bodySmall),
            ],

            const SizedBox(height: DekapSpace.cardGap),
            Text(
              'Bukti kredensial: '
              '${p.buktiKredensial ?? 'belum dilampirkan'}',
              style: text.bodySmall,
            ),

            if (_menolak) ...[
              const SizedBox(height: DekapSpace.cardGap),
              TextField(
                controller: _alasan,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText:
                      'Alasan penolakan, supaya praktik tahu apa yang '
                      'perlu diperbaiki',
                ),
              ),
            ],

            if (_kabar != null) ...[
              const SizedBox(height: DekapSpace.cardGap),
              Text(_kabar!, style: text.bodyMedium),
            ],

            const SizedBox(height: DekapSpace.cardPadding),
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    label: 'Setujui',
                    onPressed: _sibuk ? null : _setujui,
                  ),
                ),
                const SizedBox(width: DekapSpace.cardGap),
                Expanded(
                  child: SecondaryButton(
                    label: _menolak ? 'Kirim penolakan' : 'Tolak',
                    onPressed: _sibuk ? null : _tolak,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setujui() => _jalankan(
    () => ref
        .read(adminRepositoryProvider)
        .setujuiProfesional(widget.profesional.id),
  );

  Future<void> _tolak() async {
    // First press opens the reason box. A rejection with no reason is not a
    // decision the practice can act on, and the database refuses it anyway.
    if (!_menolak) {
      setState(() => _menolak = true);
      return;
    }
    await _jalankan(
      () => ref
          .read(adminRepositoryProvider)
          .tolakProfesional(widget.profesional.id, _alasan.text),
    );
  }

  Future<void> _jalankan(Future<void> Function() aksi) async {
    setState(() {
      _sibuk = true;
      _kabar = null;
    });
    try {
      await aksi();
      if (!mounted) return;
      ref.invalidate(antreanVerifikasiProvider);
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _sibuk = false;
        _kabar = pesanKesalahan(e);
      });
    }
  }
}
