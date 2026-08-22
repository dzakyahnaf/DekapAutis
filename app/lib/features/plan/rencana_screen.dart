import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/strings.dart';
import '../../core/theme/tokens.dart';
import '../../data/models/item_rencana.dart';
import '../../data/providers.dart';
import '../../data/repositories/auth_repository.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/routine_card.dart';
import '../../shared/widgets/states.dart';

/// L.6 - the weekly plan.
class RencanaScreen extends ConsumerStatefulWidget {
  const RencanaScreen({super.key});

  @override
  ConsumerState<RencanaScreen> createState() => _RencanaScreenState();
}

class _RencanaScreenState extends ConsumerState<RencanaScreen> {
  bool _menyusun = false;
  String? _alasanTerakhir;
  String? _kesalahan;

  @override
  Widget build(BuildContext context) {
    final mingguan = ref.watch(rencanaMingguanProvider);
    final terpilih = ref.watch(hariTerpilihProvider);
    final anak = ref.watch(anakAktifProvider).value;
    final awal = awalMinggu(terpilih);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text(S.titleRencana)),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                DekapSpace.screenPadding,
                0,
                DekapSpace.screenPadding,
                DekapSpace.cardGap,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${DateFormat('d MMM', 'id_ID').format(awal)} - '
                    '${DateFormat('d MMM y', 'id_ID').format(awal.add(const Duration(days: 6)))}',
                    style: text.bodySmall,
                  ),
                  const SizedBox(height: DekapSpace.cardGap),
                  _PemilihHari(awal: awal, terpilih: terpilih),
                ],
              ),
            ),
            Expanded(
              child: mingguan.when(
                loading: () => const LoadingText(message: S.memuatRencana),
                error: (_, _) => const ErrorState(message: S.gagalLayanan),
                data: (semua) {
                  final harian = semua
                      .where(
                        (i) =>
                            i.jadwal.tanggal.year == terpilih.year &&
                            i.jadwal.tanggal.month == terpilih.month &&
                            i.jadwal.tanggal.day == terpilih.day,
                      )
                      .toList();

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(
                      DekapSpace.screenPadding,
                      0,
                      DekapSpace.screenPadding,
                      DekapSpace.screenPadding,
                    ),
                    children: [
                      if (_alasanTerakhir != null) ...[
                        _KartuPenjelasan(alasan: _alasanTerakhir!),
                        const SizedBox(height: DekapSpace.cardPadding),
                      ],
                      if (_kesalahan != null) ...[
                        Text(
                          _kesalahan!,
                          style: text.bodyMedium?.copyWith(
                            color: DekapColors.boundary,
                          ),
                        ),
                        const SizedBox(height: DekapSpace.cardGap),
                      ],
                      if (semua.isEmpty)
                        EmptyState(
                          message: anak == null
                              ? 'Belum ada profil anak. Tambahkan satu untuk mulai menyusun rencana.'
                              : 'Belum ada rencana untuk minggu ini. Susun sekarang, dan Anda tetap bisa mengubahnya.',
                        )
                      else if (harian.isEmpty)
                        const EmptyState(
                          message:
                              'Tidak ada aktivitas terjadwal pada hari ini. Pilih hari lain, atau nikmati harinya.',
                        )
                      else
                        for (var i = 0; i < harian.length; i++) ...[
                          _Kartu(
                            item: harian[i],
                            posisi: i + 1,
                            total: harian.length,
                          ),
                          if (i != harian.length - 1)
                            const SizedBox(height: DekapSpace.cardGap),
                        ],
                      if (anak != null) ...[
                        const SizedBox(height: DekapSpace.screenPadding),
                        SecondaryButton(
                          label: _menyusun
                              ? 'Menyusun rencana…'
                              : semua.isEmpty
                              ? 'Susun rencana minggu ini'
                              : 'Susun ulang rencana minggu ini',
                          icon: Symbols.auto_awesome_rounded,
                          onPressed: _menyusun ? null : () => _susun(anak.id),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _susun(String profilAnakId) async {
    setState(() {
      _menyusun = true;
      _kesalahan = null;
    });
    try {
      final alasan = await ref
          .read(rencanaRepositoryProvider)
          .buatRencana(profilAnakId);
      if (!mounted) return;
      setState(() {
        _menyusun = false;
        _alasanTerakhir = alasan.isEmpty ? null : alasan;
      });
      ref
        ..invalidate(rencanaMingguanProvider)
        ..invalidate(agendaHariIniProvider);
    } on KesalahanAuth catch (e) {
      if (!mounted) return;
      setState(() {
        _menyusun = false;
        _kesalahan = e.pesan;
      });
    }
  }
}

/// Seven columns, the selected day filled purple. Static: no sliding indicator.
class _PemilihHari extends ConsumerWidget {
  const _PemilihHari({required this.awal, required this.terpilih});

  final DateTime awal;
  final DateTime terpilih;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Row(
    children: [
      for (var i = 0; i < 7; i++) ...[
        Expanded(
          child: _Hari(
            tanggal: awal.add(Duration(days: i)),
            terpilih: terpilih,
          ),
        ),
        if (i != 6) const SizedBox(width: DekapSpace.cardGap / 3),
      ],
    ],
  );
}

class _Hari extends ConsumerWidget {
  const _Hari({required this.tanggal, required this.terpilih});

  final DateTime tanggal;
  final DateTime terpilih;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aktif =
        tanggal.year == terpilih.year &&
        tanggal.month == terpilih.month &&
        tanggal.day == terpilih.day;

    return Semantics(
      button: true,
      selected: aktif,
      label: DateFormat('EEEE d MMMM', 'id_ID').format(tanggal),
      excludeSemantics: true,
      child: Material(
        color: aktif ? DekapColors.purple700 : DekapColors.surface,
        borderRadius: BorderRadius.circular(DekapSpace.radiusControl),
        child: InkWell(
          onTap: () => ref.read(hariTerpilihProvider.notifier).state = tanggal,
          borderRadius: BorderRadius.circular(DekapSpace.radiusControl),
          child: Container(
            constraints: const BoxConstraints(minHeight: DekapSpace.minTouch),
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(DekapSpace.radiusControl),
              border: Border.all(
                color: aktif ? DekapColors.purple700 : DekapColors.border,
                width: DekapSpace.borderWidth,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('E', 'id_ID').format(tanggal).substring(0, 3),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: aktif
                        ? DekapColors.surface
                        : DekapColors.textSecondary,
                  ),
                ),
                Text(
                  '${tanggal.day}',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: aktif
                        ? DekapColors.surface
                        : DekapColors.textPrimary,
                    fontFamily: DekapType.familyMono,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Why the plan looks the way it does, in the caregiver's own language.
///
/// From F4 this also carries the adaptation reasons out of adaptasi_log. It is
/// the difference between a plan that adjusts and a black box that changes.
class _KartuPenjelasan extends StatelessWidget {
  const _KartuPenjelasan({required this.alasan});

  final String alasan;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(DekapSpace.cardPadding),
    decoration: BoxDecoration(
      color: DekapColors.purple100,
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
          Symbols.auto_awesome_rounded,
          size: DekapSpace.iconSize,
          color: DekapColors.purple700,
        ),
        const SizedBox(width: DekapSpace.cardGap),
        Expanded(
          child: Text(alasan, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    ),
  );
}

class _Kartu extends ConsumerWidget {
  const _Kartu({required this.item, required this.posisi, required this.total});

  final ItemRencana item;
  final int posisi;
  final int total;

  @override
  Widget build(BuildContext context, WidgetRef ref) => RoutineCard(
    position: posisi,
    total: total,
    time: item.waktuTampil,
    durationMinutes: item.jadwal.durasiMenit,
    category: item.kategori,
    title: item.judul,
    selected: item.nilai,
    onOpen: () => context.go('/rencana/aktivitas/${item.id}'),
    onRespond: (nilai) async {
      await ref
          .read(rencanaRepositoryProvider)
          .catatRespons(jadwalAktivitasId: item.id, nilai: nilai);
      ref
        ..invalidate(rencanaMingguanProvider)
        ..invalidate(agendaHariIniProvider);
    },
  );
}
