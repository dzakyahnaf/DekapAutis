import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/strings.dart';
import '../../core/theme/tokens.dart';
import '../../data/models/direktori.dart';
import '../../data/providers.dart';
import '../../domain/direktori/jarak.dart';
import '../../domain/direktori/kota.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/states.dart';

/// Where the caregiver is searching from.
///
/// A typed city rather than a device GPS fix. Asking for location permission to
/// sort a list of five clinics is a poor trade, and a caregiver looking for a
/// practice near their mother's house is not helped by where they are standing.
final lokasiPencarianProvider = StateProvider<String>((ref) => '');

final filterLayananProvider = StateProvider<JenisLayanan>(
  (ref) => JenisLayanan.semua,
);

/// L.9 - the professional directory.
class DirektoriScreen extends ConsumerWidget {
  const DirektoriScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daftar = ref.watch(daftarProfesionalProvider);
    final lokasi = ref.watch(lokasiPencarianProvider);
    final filter = ref.watch(filterLayananProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(S.titleDirektori)),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            const JelajahTabs(current: JelajahTab.direktori),
            Expanded(
              child: daftar.when(
                loading: () => const LoadingText(),
                error: (e, _) => ErrorState(
                  message: pesanKesalahan(e),
                  onRetry: () => ref.invalidate(daftarProfesionalProvider),
                ),
                data: (semua) =>
                    _Hasil(semua: semua, lokasi: lokasi, filter: filter),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Hasil extends ConsumerWidget {
  const _Hasil({
    required this.semua,
    required this.lokasi,
    required this.filter,
  });

  final List<Profesional> semua;
  final String lokasi;
  final JenisLayanan filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dariMana = koordinatKota(lokasi);
    final cocok = semua.where((p) => filter.cocok(p.spesialisasi)).toList();
    final urut = urutkanTerdekat(cocok, dariMana, (p) => p.posisi);
    final text = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        DekapSpace.screenPadding,
        0,
        DekapSpace.screenPadding,
        DekapSpace.screenPadding,
      ),
      children: [
        TextField(
          onChanged: (v) =>
              ref.read(lokasiPencarianProvider.notifier).state = v,
          decoration: const InputDecoration(
            hintText: 'Kota, misalnya Surabaya',
            prefixIcon: Icon(Symbols.location_on_rounded),
          ),
        ),
        const SizedBox(height: DekapSpace.cardGap),

        _FilterLayanan(terpilih: filter),
        const SizedBox(height: DekapSpace.cardGap),

        // The count is the real length of the list, not a figure from a mockup.
        Text(
          urut.isEmpty
              ? 'Tidak ada profesional yang cocok'
              : '${urut.length} profesional terverifikasi',
          style: text.bodySmall,
        ),
        if (lokasi.trim().isNotEmpty && dariMana == null)
          Padding(
            padding: const EdgeInsets.only(top: DekapSpace.cardGap / 2),
            child: Text(
              'Kota "$lokasi" belum ada di daftar kami, jadi urutannya belum '
              'berdasarkan jarak.',
              style: text.bodySmall,
            ),
          ),
        const SizedBox(height: DekapSpace.cardGap),

        if (urut.isEmpty)
          const EmptyState(
            message:
                'Belum ada profesional yang cocok dengan pilihan ini. Coba '
                'ubah jenis layanan atau kosongkan kolom kota.',
          )
        else
          for (final p in urut) ...[
            KartuProfesional(profesional: p, dariMana: dariMana),
            const SizedBox(height: DekapSpace.cardGap),
          ],
      ],
    );
  }
}

class _FilterLayanan extends ConsumerWidget {
  const _FilterLayanan({required this.terpilih});

  final JenisLayanan terpilih;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Wrap(
    spacing: DekapSpace.cardGap / 1.5,
    runSpacing: DekapSpace.cardGap / 1.5,
    children: [
      for (final jenis in JenisLayanan.values)
        ChoiceChip(
          label: Text(jenis.label),
          selected: jenis == terpilih,
          showCheckmark: false,
          backgroundColor: DekapColors.surface,
          selectedColor: DekapColors.purple100,
          side: BorderSide(
            color: jenis == terpilih
                ? DekapColors.purple700
                : DekapColors.border,
            width: DekapSpace.borderWidth,
          ),
          labelStyle: Theme.of(context).textTheme.labelSmall,
          padding: const EdgeInsets.symmetric(
            horizontal: DekapSpace.cardGap,
            vertical: DekapSpace.cardGap,
          ),
          onSelected: (_) =>
              ref.read(filterLayananProvider.notifier).state = jenis,
        ),
    ],
  );
}

/// One listing. Also used by the search results, so it lives here rather than
/// inside the list builder.
class KartuProfesional extends StatelessWidget {
  const KartuProfesional({required this.profesional, this.dariMana, super.key});

  final Profesional profesional;
  final Koordinat? dariMana;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final posisi = profesional.posisi;
    final jarak = dariMana != null && posisi != null
        ? jarakTampil(jarakKm(dariMana!, posisi))
        : null;

    return Card(
      child: InkWell(
        onTap: () => context.go('/direktori/${profesional.id}'),
        borderRadius: BorderRadius.circular(DekapSpace.radiusCard),
        child: Padding(
          padding: const EdgeInsets.all(DekapSpace.cardPadding),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Inisial(inisial: profesional.inisial),
              const SizedBox(width: DekapSpace.cardGap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(profesional.namaDenganGelar, style: text.titleMedium),
                    Text(profesional.spesialisasi, style: text.bodySmall),
                    const SizedBox(height: DekapSpace.cardGap / 2),
                    Wrap(
                      spacing: DekapSpace.cardGap,
                      runSpacing: 4,
                      children: [
                        if (jarak != null)
                          _Keterangan(
                            icon: Symbols.near_me_rounded,
                            teks: jarak,
                          ),
                        if (profesional.kota != null)
                          _Keterangan(
                            icon: Symbols.location_city_rounded,
                            teks: profesional.kota!,
                          ),
                        if (profesional.jadwalPraktik.isNotEmpty)
                          _Keterangan(
                            icon: Symbols.calendar_month_rounded,
                            teks: profesional.jadwalPraktik
                                .map((j) => j.hari)
                                .take(3)
                                .join(', '),
                          ),
                      ],
                    ),
                    if (profesional.terverifikasi) ...[
                      const SizedBox(height: DekapSpace.cardGap / 2),
                      const LencanaTerverifikasi(),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Inisial extends StatelessWidget {
  const _Inisial({required this.inisial});

  final String inisial;

  @override
  Widget build(BuildContext context) => Container(
    width: DekapSpace.minTouch,
    height: DekapSpace.minTouch,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: DekapColors.purple100,
      borderRadius: BorderRadius.circular(DekapSpace.radiusControl),
    ),
    // Excluded from semantics: the initials are decoration next to the name,
    // and TalkBack reading "S H" before the name is noise.
    child: ExcludeSemantics(
      child: Text(inisial, style: Theme.of(context).textTheme.labelLarge),
    ),
  );
}

/// KF-12. Icon *and* word: a badge that is only a tick is a badge half the
/// users will not understand.
class LencanaTerverifikasi extends StatelessWidget {
  const LencanaTerverifikasi({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: DekapSpace.cardGap,
      vertical: 4,
    ),
    decoration: BoxDecoration(
      color: DekapColors.purple100,
      borderRadius: BorderRadius.circular(DekapSpace.radiusControl),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Symbols.verified_rounded,
          size: DekapSpace.iconSize - 6,
          color: DekapColors.purple700,
        ),
        const SizedBox(width: 4),
        Text('Terverifikasi', style: Theme.of(context).textTheme.labelSmall),
      ],
    ),
  );
}

class _Keterangan extends StatelessWidget {
  const _Keterangan({required this.icon, required this.teks});

  final IconData icon;
  final String teks;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(
        icon,
        size: DekapSpace.iconSize - 8,
        color: DekapColors.textSecondary,
      ),
      const SizedBox(width: 4),
      Text(teks, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}
