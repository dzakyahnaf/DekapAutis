import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/strings.dart';
import '../../core/theme/tokens.dart';
import '../../data/models/item_rencana.dart';
import '../../data/models/response_level.dart';
import '../../data/providers.dart';
import '../../shared/widgets/category_pill.dart';
import '../../shared/widgets/states.dart';

/// L.7 - one activity, with the response bar pinned to the bottom.
///
/// The bar does not scroll away. A caregiver reaches for it while the activity
/// is still happening, often one-handed, and hunting for a control they can
/// already see is exactly the friction this screen exists to remove.
class DetailAktivitasScreen extends ConsumerWidget {
  const DetailAktivitasScreen({required this.jadwalId, super.key});

  final String jadwalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final anak = ref.watch(anakAktifProvider).value;
    final item = ref.watch(detailAktivitasProvider(jadwalId));

    return Scaffold(
      appBar: AppBar(title: const Text(S.titleAktivitas)),
      body: item.when(
        loading: () => const LoadingText(),
        error: (_, _) => const ErrorState(message: S.gagalLayanan),
        data: (data) => data == null
            ? const EmptyState(
                message:
                    'Aktivitas ini tidak ada di rencana yang tersimpan di perangkat.',
              )
            : _Isi(item: data, namaAnak: anak?.namaPanggilan ?? 'anak Anda'),
      ),
    );
  }
}

/// One scheduled activity, read from the local cache so it opens offline.
final detailAktivitasProvider = FutureProvider.family<ItemRencana?, String>((
  ref,
  jadwalId,
) async {
  final anak = await ref.watch(anakAktifProvider.future);
  if (anak == null) return null;
  return ref
      .watch(rencanaRepositoryProvider)
      .satu(jadwalId, anak.namaPanggilan);
});

class _Isi extends ConsumerWidget {
  const _Isi({required this.item, required this.namaAnak});

  final ItemRencana item;
  final String namaAnak;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(DekapSpace.screenPadding),
            children: [
              CategoryPill(category: item.kategori),
              const SizedBox(height: DekapSpace.cardGap),
              Text(item.judul, style: text.titleLarge),
              const SizedBox(height: DekapSpace.cardGap),

              Wrap(
                spacing: DekapSpace.cardGap,
                runSpacing: 4,
                children: [
                  _Meta(
                    ikon: Symbols.schedule_rounded,
                    teks: '${item.jadwal.durasiMenit} menit',
                  ),
                  _Meta(
                    ikon: Symbols.calendar_month_rounded,
                    teks: 'Pukul ${item.waktuTampil}',
                  ),
                  // Level is stated as a position in a range, never as a score
                  // for the child: it describes the activity, not the person.
                  _Meta(
                    ikon: Symbols.stairs_rounded,
                    teks: 'Tingkat ${item.jadwal.tingkatDisesuaikan} dari 4',
                  ),
                ],
              ),

              const SizedBox(height: DekapSpace.screenPadding),
              Text('Tujuan', style: text.titleMedium),
              const SizedBox(height: DekapSpace.cardGap / 2),
              Text(item.tujuan, style: text.bodyLarge),

              const SizedBox(height: DekapSpace.screenPadding),
              Text('Yang perlu disiapkan', style: text.titleMedium),
              const SizedBox(height: DekapSpace.cardGap),
              for (final alat in item.alat)
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: DekapSpace.cardGap / 2,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Symbols.check_circle_rounded,
                        size: DekapSpace.iconSize - 6,
                        color: DekapColors.purple700,
                      ),
                      const SizedBox(width: DekapSpace.cardGap),
                      Expanded(child: Text(alat, style: text.bodyMedium)),
                    ],
                  ),
                ),

              const SizedBox(height: DekapSpace.screenPadding),
              Text('Langkah', style: text.titleMedium),
              const SizedBox(height: DekapSpace.cardGap),
              for (var i = 0; i < item.langkah.length; i++)
                _Langkah(nomor: i + 1, teks: item.langkah[i]),

              if (item.saranLingkungan != null) ...[
                const SizedBox(height: DekapSpace.screenPadding),
                _SaranLingkungan(teks: item.saranLingkungan!),
              ],

              const SizedBox(height: DekapSpace.screenPadding),
            ],
          ),
        ),
        _PitaRespons(item: item, namaAnak: namaAnak),
      ],
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.ikon, required this.teks});

  final IconData ikon;
  final String teks;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(
        ikon,
        size: DekapSpace.iconSize - 8,
        color: DekapColors.textSecondary,
      ),
      const SizedBox(width: 4),
      Text(teks, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}

class _Langkah extends StatelessWidget {
  const _Langkah({required this.nomor, required this.teks});

  final int nomor;
  final String teks;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: DekapSpace.cardGap),
    padding: const EdgeInsets.all(DekapSpace.cardPadding),
    decoration: BoxDecoration(
      color: DekapColors.surface,
      borderRadius: BorderRadius.circular(DekapSpace.radiusCard),
      border: Border.all(
        color: DekapColors.border,
        width: DekapSpace.borderWidth,
      ),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$nomor',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontFamily: DekapType.familyMono,
            color: DekapColors.purple700,
          ),
        ),
        const SizedBox(width: DekapSpace.cardPadding),
        Expanded(
          child: Text(teks, style: Theme.of(context).textTheme.bodyLarge),
        ),
      ],
    ),
  );
}

/// Attached when the adaptation engine lowers a level (rule B_turun).
class _SaranLingkungan extends StatelessWidget {
  const _SaranLingkungan({required this.teks});

  final String teks;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(DekapSpace.cardPadding),
    decoration: BoxDecoration(
      color: DekapColors.cream50,
      borderRadius: BorderRadius.circular(DekapSpace.radiusCard),
      border: Border.all(
        color: DekapColors.border,
        width: DekapSpace.borderWidth,
      ),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Symbols.blur_on_rounded,
          size: DekapSpace.iconSize,
          color: DekapColors.cream700,
        ),
        const SizedBox(width: DekapSpace.cardGap),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Jika terasa berat',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 4),
              Text(teks, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    ),
  );
}

/// The sticky response bar (KF-05).
class _PitaRespons extends ConsumerStatefulWidget {
  const _PitaRespons({required this.item, required this.namaAnak});

  final ItemRencana item;
  final String namaAnak;

  @override
  ConsumerState<_PitaRespons> createState() => _PitaResponsState();
}

class _PitaResponsState extends ConsumerState<_PitaRespons> {
  final _catatan = TextEditingController();
  bool _tampilCatatan = false;

  @override
  void initState() {
    super.initState();
    _catatan.text = widget.item.respons?.catatan ?? '';
    _tampilCatatan = _catatan.text.isNotEmpty;
  }

  @override
  void dispose() {
    _catatan.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final terpilih = widget.item.nilai;

    return Container(
      padding: EdgeInsets.fromLTRB(
        DekapSpace.screenPadding,
        DekapSpace.cardPadding,
        DekapSpace.screenPadding,
        DekapSpace.cardPadding + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: DekapColors.surface,
        border: Border(
          top: BorderSide(
            color: DekapColors.border,
            width: DekapSpace.borderWidth,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bagaimana respons ${widget.namaAnak}?',
            style: text.titleMedium,
          ),
          if (widget.item.menungguSinkron) ...[
            const SizedBox(height: 4),
            Text(
              'Tersimpan di perangkat, menunggu sinkronisasi.',
              style: text.bodySmall,
            ),
          ],
          const SizedBox(height: DekapSpace.cardGap),
          Row(
            children: [
              for (final level in ResponseLevel.values) ...[
                Expanded(
                  child: _Tombol(
                    level: level,
                    aktif: terpilih == level,
                    onTap: () => _catat(level),
                  ),
                ),
                if (level != ResponseLevel.values.last)
                  const SizedBox(width: DekapSpace.cardGap / 1.5),
              ],
            ],
          ),
          const SizedBox(height: DekapSpace.cardGap / 2),
          if (!_tampilCatatan)
            TextButton(
              onPressed: () => setState(() => _tampilCatatan = true),
              child: const Text('Tambah catatan (opsional)'),
            )
          else ...[
            const SizedBox(height: DekapSpace.cardGap / 2),
            TextField(
              controller: _catatan,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Apa yang Anda perhatikan hari ini?',
              ),
              onSubmitted: (_) => terpilih == null ? null : _catat(terpilih),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _catat(ResponseLevel nilai) async {
    await ref
        .read(rencanaRepositoryProvider)
        .catatRespons(
          jadwalAktivitasId: widget.item.id,
          nilai: nilai,
          catatan: _catatan.text.trim().isEmpty ? null : _catatan.text.trim(),
        );
    ref
      ..invalidate(detailAktivitasProvider(widget.item.id))
      ..invalidate(agendaHariIniProvider)
      ..invalidate(rencanaMingguanProvider);

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Catatan tersimpan.')));
  }
}

class _Tombol extends StatelessWidget {
  const _Tombol({
    required this.level,
    required this.aktif,
    required this.onTap,
  });

  final ResponseLevel level;
  final bool aktif;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: aktif,
    label: 'Catat respons ${level.label}',
    excludeSemantics: true,
    child: Material(
      color: aktif ? DekapColors.purple700 : DekapColors.surface,
      borderRadius: BorderRadius.circular(DekapSpace.radiusControl),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DekapSpace.radiusControl),
        child: Container(
          constraints: const BoxConstraints(
            minHeight: DekapSpace.buttonHeight,
            minWidth: DekapSpace.minTouch,
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(DekapSpace.radiusControl),
            border: Border.all(
              color: aktif ? DekapColors.purple700 : DekapColors.border,
              width: DekapSpace.borderWidth,
            ),
          ),
          child: Text(
            level.label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: aktif ? DekapColors.surface : DekapColors.textPrimary,
            ),
          ),
        ),
      ),
    ),
  );
}
