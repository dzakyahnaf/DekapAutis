import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/tokens.dart';
import '../../data/models/direktori.dart';
import '../../data/providers.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/states.dart';
import 'direktori_screen.dart';

/// L.10 - one practice, and the two things a caregiver can do with it.
///
/// Both buttons stop at recording an intention. "Ajukan jadwal" writes a
/// request and notifies the practice; "Kirim laporan" opens the existing
/// sharing-permission screen. Neither takes a payment and neither opens a
/// session, because Bab 4.1 rules both out and the schema has nowhere to put
/// them.
class DetailProfesionalScreen extends ConsumerWidget {
  const DetailProfesionalScreen({required this.id, super.key});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profesional = ref.watch(profesionalProvider(id));

    return Scaffold(
      appBar: AppBar(title: const Text('Profil profesional')),
      body: SafeArea(
        top: false,
        child: profesional.when(
          loading: () => const LoadingText(),
          error: (e, _) => ErrorState(
            message: pesanKesalahan(e),
            onRetry: () => ref.invalidate(profesionalProvider(id)),
          ),
          data: (p) => p == null
              ? EmptyState(
                  message:
                      'Profil ini tidak ditemukan. Mungkin sudah tidak '
                      'terdaftar lagi.',
                  actionLabel: 'Kembali ke direktori',
                  onAction: () => context.go('/direktori'),
                )
              : _Isi(profesional: p),
        ),
      ),
    );
  }
}

class _Isi extends ConsumerWidget {
  const _Isi({required this.profesional});

  final Profesional profesional;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final anak = ref.watch(anakAktifProvider).value;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(DekapSpace.screenPadding),
            children: [
              Text(profesional.namaDenganGelar, style: text.titleLarge),
              const SizedBox(height: 4),
              Text(profesional.spesialisasi, style: text.bodyLarge),
              if (profesional.kota != null) ...[
                const SizedBox(height: 4),
                Text(profesional.kota!, style: text.bodySmall),
              ],
              if (profesional.terverifikasi) ...[
                const SizedBox(height: DekapSpace.cardGap),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: LencanaTerverifikasi(),
                ),
              ],

              if (profesional.tentang != null &&
                  profesional.tentang!.isNotEmpty) ...[
                const SizedBox(height: DekapSpace.screenPadding),
                Text('Tentang', style: text.titleMedium),
                const SizedBox(height: DekapSpace.cardGap / 2),
                Text(profesional.tentang!, style: text.bodyMedium),
              ],

              if (profesional.layanan.isNotEmpty) ...[
                const SizedBox(height: DekapSpace.screenPadding),
                Text('Layanan', style: text.titleMedium),
                const SizedBox(height: DekapSpace.cardGap),
                Wrap(
                  spacing: DekapSpace.cardGap / 1.5,
                  runSpacing: DekapSpace.cardGap / 1.5,
                  children: [
                    for (final l in profesional.layanan)
                      _KepingLayanan(teks: l),
                  ],
                ),
              ],

              const SizedBox(height: DekapSpace.screenPadding),
              Text('Jadwal praktik', style: text.titleMedium),
              const SizedBox(height: DekapSpace.cardGap),
              if (profesional.jadwalPraktik.isEmpty)
                Text(
                  'Jadwal praktik belum dicantumkan. Anda tetap bisa mengajukan '
                  'permintaan, dan praktik akan menghubungi Anda.',
                  style: text.bodySmall,
                )
              else
                _TabelJadwal(jadwal: profesional.jadwalPraktik),
            ],
          ),
        ),
        _AksiBawah(profesional: profesional, namaAnak: anak?.namaPanggilan),
      ],
    );
  }
}

class _KepingLayanan extends StatelessWidget {
  const _KepingLayanan({required this.teks});

  final String teks;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: DekapSpace.cardGap,
      vertical: DekapSpace.cardGap / 2,
    ),
    decoration: BoxDecoration(
      color: DekapColors.cream200,
      borderRadius: BorderRadius.circular(DekapSpace.radiusControl),
    ),
    child: Text(teks, style: Theme.of(context).textTheme.labelSmall),
  );
}

class _TabelJadwal extends StatelessWidget {
  const _TabelJadwal({required this.jadwal});

  final List<JamPraktik> jadwal;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: DekapColors.surface,
        borderRadius: BorderRadius.circular(DekapSpace.radiusCard),
        border: Border.all(
          color: DekapColors.border,
          width: DekapSpace.borderWidth,
        ),
      ),
      child: Column(
        children: [
          for (var i = 0; i < jadwal.length; i++)
            Container(
              padding: const EdgeInsets.all(DekapSpace.cardPadding),
              decoration: i == jadwal.length - 1
                  ? null
                  : const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: DekapColors.border,
                          width: DekapSpace.borderWidth,
                        ),
                      ),
                    ),
              child: Row(
                children: [
                  Expanded(child: Text(jadwal[i].hari, style: text.bodyMedium)),
                  Text(jadwal[i].jam, style: text.bodyMedium),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// The two actions, pinned to the bottom. Two, not three - CLAUDE.md caps a
/// screen at three primary actions and the back arrow is the third.
class _AksiBawah extends ConsumerStatefulWidget {
  const _AksiBawah({required this.profesional, this.namaAnak});

  final Profesional profesional;
  final String? namaAnak;

  @override
  ConsumerState<_AksiBawah> createState() => _AksiBawahState();
}

class _AksiBawahState extends ConsumerState<_AksiBawah> {
  bool _sibuk = false;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(DekapSpace.screenPadding),
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
          PrimaryButton(
            label: _sibuk ? 'Mengirim permintaan…' : 'Ajukan jadwal konsultasi',
            icon: Symbols.event_available_rounded,
            onPressed: _sibuk ? null : _ajukan,
          ),
          const SizedBox(height: DekapSpace.cardGap),
          SecondaryButton(
            label: widget.namaAnak == null
                ? 'Kirim laporan anak'
                : 'Kirim laporan ${widget.namaAnak}',
            icon: Symbols.description_rounded,
            onPressed: _sibuk ? null : () => context.go('/profil/izin'),
          ),
        ],
      ),
    ),
  );

  Future<void> _ajukan() async {
    final jadwal = widget.profesional.jadwalPraktik;
    final pilihan = jadwal.isEmpty
        ? const JamPraktik(hari: 'Menyesuaikan', jam: 'Menyesuaikan')
        : await _pilihJadwal(jadwal);
    if (pilihan == null || !mounted) return;

    setState(() => _sibuk = true);
    try {
      await ref
          .read(direktoriRepositoryProvider)
          .ajukan(
            profesionalId: widget.profesional.id,
            hari: pilihan.hari,
            jam: pilihan.jam,
            // Generated here so a retry from the offline queue lands on the
            // same row instead of booking the practice twice.
            klienId: const Uuid().v4(),
            anakId: ref.read(anakAktifProvider).value?.id,
          );
      if (!mounted) return;
      _kabari(
        'Permintaan terkirim. Praktik akan menerima pemberitahuan dan '
        'menghubungi Anda di luar aplikasi.',
      );
    } on Object catch (e) {
      if (!mounted) return;
      _kabari(pesanKesalahan(e));
    } finally {
      if (mounted) setState(() => _sibuk = false);
    }
  }

  Future<JamPraktik?> _pilihJadwal(List<JamPraktik> jadwal) =>
      showModalBottomSheet<JamPraktik>(
        context: context,
        backgroundColor: DekapColors.surface,
        builder: (sheet) => SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(DekapSpace.screenPadding),
            children: [
              Text(
                'Pilih waktu yang Anda inginkan',
                style: Theme.of(sheet).textTheme.titleMedium,
              ),
              const SizedBox(height: DekapSpace.cardGap / 2),
              Text(
                'Ini permintaan, bukan pemesanan. Praktik yang memutuskan dan '
                'menghubungi Anda.',
                style: Theme.of(sheet).textTheme.bodySmall,
              ),
              const SizedBox(height: DekapSpace.cardGap),
              for (final j in jadwal)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  minTileHeight: DekapSpace.minTouch,
                  title: Text('${j.hari}, ${j.jam}'),
                  onTap: () => Navigator.of(sheet).pop(j),
                ),
            ],
          ),
        ),
      );

  void _kabari(String pesan) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(pesan)));
}
