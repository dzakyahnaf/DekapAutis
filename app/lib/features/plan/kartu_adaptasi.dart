import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/theme/tokens.dart';
import '../../data/providers.dart';
import '../../data/repositories/adaptasi_repository.dart';
import '../../domain/adaptasi/adaptation_engine.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/states.dart';

/// Why the plan looks the way it does, read out of `adaptasi_log` (KF-06).
///
/// This is the difference between a plan that adapts and a black box that
/// changes. Every row names the rule that fired and the real numbers behind it,
/// and every row can be overridden by the caregiver - who knows things the
/// notes do not contain.
///
/// Rows from rule D never appear here. They are written for the report and the
/// professional's inbox; telling a parent "your child is declining" helps
/// nobody and is not this app's place to say. The filter lives in
/// `penjelasanAdaptasiProvider`.
class DaftarPenjelasanAdaptasi extends ConsumerWidget {
  const DaftarPenjelasanAdaptasi({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final penjelasan = ref.watch(penjelasanAdaptasiProvider);

    return penjelasan.maybeWhen(
      data: (daftar) => daftar.isEmpty
          ? const SizedBox.shrink()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mengapa rencana ini berubah',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: DekapSpace.cardGap),
                for (final b in daftar.take(5)) ...[
                  KartuAdaptasi(key: ValueKey(b.id), baris: b),
                  const SizedBox(height: DekapSpace.cardGap),
                ],
              ],
            ),
      orElse: () => const SizedBox.shrink(),
    );
  }
}

/// Public so a widget test can build one without reaching a backend.
class KartuAdaptasi extends ConsumerStatefulWidget {
  const KartuAdaptasi({required this.baris, super.key});

  final BarisLogTersimpan baris;

  @override
  ConsumerState<KartuAdaptasi> createState() => _KartuAdaptasiState();
}

class _KartuAdaptasiState extends ConsumerState<KartuAdaptasi> {
  bool _sibuk = false;
  String? _kabar;

  @override
  Widget build(BuildContext context) {
    final b = widget.baris;
    final text = Theme.of(context).textTheme;
    final manual = b.dikoreksiManual;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DekapSpace.cardPadding),
      decoration: BoxDecoration(
        // Cream when the caregiver decided it, purple when the rules did. The
        // two paths are never confused for one another anywhere in this app.
        color: manual ? DekapColors.cream50 : DekapColors.purple100,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                manual ? Symbols.edit_rounded : Symbols.auto_awesome_rounded,
                size: DekapSpace.iconSize,
                color: manual ? DekapColors.cream700 : DekapColors.purple700,
              ),
              const SizedBox(width: DekapSpace.cardGap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Named, not only coloured: which of the two decided this
                    // is the first thing a caregiver needs to know.
                    Text(
                      manual ? 'Koreksi Anda' : _labelAturan(b.aturanId),
                      style: text.labelSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(b.alasan, style: text.bodyMedium),
                  ],
                ),
              ),
            ],
          ),

          if (_kabar != null) ...[
            const SizedBox(height: DekapSpace.cardGap),
            Text(_kabar!, style: text.bodySmall),
          ],

          // A rule's decision can be overridden. A caregiver's own correction
          // has nothing to override.
          if (!manual && b.kategori != null) ...[
            const SizedBox(height: DekapSpace.cardGap),
            Align(
              alignment: Alignment.centerLeft,
              child: SecondaryButton(
                label: _sibuk ? 'Menyimpan…' : 'Saya koreksi sendiri',
                expand: false,
                onPressed: _sibuk ? null : _koreksi,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _labelAturan(String id) => switch (id) {
    'A_naik' => 'Tingkat aktivitas naik',
    'B_turun' => 'Tingkat aktivitas diturunkan',
    'C_porsi' => 'Porsi sesi disesuaikan',
    'E_jadwal' => 'Waktu sesi dipindahkan',
    'F_profesional' => 'Saran tenaga profesional',
    _ => 'Penyesuaian rencana',
  };

  Future<void> _koreksi() async {
    final kategori = widget.baris.kategori;
    if (kategori == null) return;

    final alasan = await _tanyaAlasan(kategori);
    if (alasan == null || !mounted) return;

    setState(() {
      _sibuk = true;
      _kabar = null;
    });

    try {
      // The timeout guards a real hazard, not a slow network: this provider
      // chains up to daftarAnakProvider, which watches the auth stream. An
      // emission mid-await discards the future we are holding and it never
      // completes, leaving the button reading "Menyimpan..." for good.
      final rencanaId = await ref
          .read(rencanaAktifIdProvider.future)
          .timeout(const Duration(seconds: 12));
      if (rencanaId == null) {
        if (!mounted) return;
        setState(() {
          _sibuk = false;
          _kabar = 'Belum ada rencana aktif untuk dikoreksi.';
        });
        return;
      }

      await ref
          .read(adaptasiRepositoryProvider)
          .koreksiManual(
            rencanaId: rencanaId,
            kategori: kategori,
            alasan: alasan,
          );
      if (!mounted) return;
      // Clearing this matters even though the list is about to rebuild: the
      // card is keyed, so this State survives the rebuild rather than being
      // discarded along with the flag.
      setState(() => _sibuk = false);
      ref.invalidate(penjelasanAdaptasiProvider);
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _sibuk = false;
        _kabar = pesanKesalahan(e);
      });
    }
  }

  /// Four ready sentences plus a free-text box.
  ///
  /// The ready ones exist because a caregiver correcting the plan at eleven at
  /// night should not also have to compose a paragraph, and because a reason
  /// left blank is a reason nobody can read back in a month.
  Future<String?> _tanyaAlasan(Kategori kategori) {
    final bebas = TextEditingController();
    final pilihan = <String>[
      'Terlalu berat untuk anak saya minggu ini.',
      'Terlalu mudah, anak saya sudah terbiasa.',
      'Waktunya tidak cocok dengan rutinitas kami.',
      'Ada hal lain di rumah yang sedang kami dahulukan.',
    ];

    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: DekapColors.surface,
      builder: (sheet) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheet).viewInsets.bottom,
        ),
        child: SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(DekapSpace.screenPadding),
            children: [
              Text(
                'Koreksi ${kategori.label.toLowerCase()}',
                style: Theme.of(sheet).textTheme.titleMedium,
              ),
              const SizedBox(height: DekapSpace.cardGap / 2),
              Text(
                'Penyesuaian otomatis untuk kategori ini berhenti sampai '
                'periode berikutnya. Alasan Anda tersimpan di riwayat rencana.',
                style: Theme.of(sheet).textTheme.bodySmall,
              ),
              const SizedBox(height: DekapSpace.cardGap),
              for (final p in pilihan)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  minTileHeight: DekapSpace.minTouch,
                  title: Text(p),
                  onTap: () => Navigator.of(sheet).pop(p),
                ),
              const SizedBox(height: DekapSpace.cardGap),
              TextField(
                controller: bebas,
                decoration: const InputDecoration(
                  hintText: 'Atau tuliskan alasan Anda sendiri',
                ),
              ),
              const SizedBox(height: DekapSpace.cardPadding),
              PrimaryButton(
                label: 'Simpan koreksi',
                onPressed: () {
                  final teks = bebas.text.trim();
                  if (teks.isEmpty) return;
                  Navigator.of(sheet).pop(teks);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
