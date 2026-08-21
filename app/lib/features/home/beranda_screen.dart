import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/strings.dart';
import '../../core/theme/tokens.dart';
import '../../data/models/item_rencana.dart';
import '../../data/models/response_level.dart';
import '../../data/providers.dart';
import '../../shared/widgets/calm_mode_switch.dart';
import '../../shared/widgets/offline_banner.dart';
import '../../shared/widgets/routine_card.dart';
import '../../shared/widgets/states.dart';
import '../caregiver_checkin/check_in_card.dart';

/// L.2 - Beranda.
///
/// Three things and no more: how the caregiver is, what is planned today, and a
/// way to record what happened. "Satu layar, satu keputusan" is the design
/// principle, and this is the screen most likely to be opened one-handed in the
/// middle of something else.
class BerandaScreen extends ConsumerStatefulWidget {
  const BerandaScreen({super.key});

  @override
  ConsumerState<BerandaScreen> createState() => _BerandaScreenState();
}

class _BerandaScreenState extends ConsumerState<BerandaScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(syncServiceProvider).mulai();
      unawaitedSegarkan();
    });
  }

  /// Refreshing is best-effort. Failing means the cached plan is what the
  /// caregiver sees, which is exactly the intended offline behaviour, so there
  /// is nothing here worth interrupting them about.
  Future<void> unawaitedSegarkan() async {
    final anak = await ref.read(anakAktifProvider.future);
    if (anak == null || !mounted) return;
    try {
      await ref.read(rencanaRepositoryProvider).segarkan(anak.id);
    } catch (_) {
      return;
    }
    if (!mounted) return;
    ref
      ..invalidate(agendaHariIniProvider)
      ..invalidate(rencanaMingguanProvider);
  }

  @override
  Widget build(BuildContext context) {
    final agenda = ref.watch(agendaHariIniProvider);
    final anak = ref.watch(anakAktifProvider).value;
    final menunggu = ref.watch(menungguSinkronProvider).value ?? 0;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            OfflineBanner(pendingCount: menunggu),
            Expanded(
              child: RefreshIndicator(
                onRefresh: unawaitedSegarkan,
                child: ListView(
                  padding: const EdgeInsets.all(DekapSpace.screenPadding),
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_sapaan(), style: text.titleLarge),
                              Text(_tanggalHariIni(), style: text.bodySmall),
                            ],
                          ),
                        ),
                        const CalmModePill(),
                        IconButton(
                          onPressed: () => context.go('/notifikasi'),
                          icon: const Icon(Symbols.notifications_rounded),
                          tooltip: 'Notifikasi',
                        ),
                      ],
                    ),
                    const SizedBox(height: DekapSpace.screenPadding),

                    const CheckInCard(),
                    const SizedBox(height: DekapSpace.screenPadding),

                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Rencana hari ini',
                            style: text.titleMedium,
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.go('/rencana'),
                          child: const Text(S.aksiLihatSemua),
                        ),
                      ],
                    ),
                    const SizedBox(height: DekapSpace.cardGap),

                    agenda.when(
                      loading: () =>
                          const LoadingText(message: S.memuatRencana),
                      error: (_, _) => ErrorState(
                        message: S.gagalLayanan,
                        onRetry: unawaitedSegarkan,
                      ),
                      data: (daftar) => daftar.isEmpty
                          ? EmptyState(
                              message: anak == null
                                  ? 'Belum ada profil anak. Tambahkan satu untuk mulai menyusun rencana harian.'
                                  : 'Belum ada aktivitas terjadwal hari ini. Susun rencana minggu ini untuk memulai.',
                              actionLabel: anak == null
                                  ? 'Tambah profil anak'
                                  : 'Buka rencana',
                              onAction: () => context.go(
                                anak == null ? '/onboarding/1' : '/rencana',
                              ),
                            )
                          : Column(
                              children: [
                                for (var i = 0; i < daftar.length; i++) ...[
                                  _Kartu(
                                    item: daftar[i],
                                    posisi: i + 1,
                                    total: daftar.length,
                                  ),
                                  if (i != daftar.length - 1)
                                    const SizedBox(height: DekapSpace.cardGap),
                                ],
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _sapaan() {
    final jam = DateTime.now().hour;
    final waktu = jam < 11
        ? 'Selamat pagi'
        : jam < 15
        ? 'Selamat siang'
        : jam < 19
        ? 'Selamat sore'
        : 'Selamat malam';
    return waktu;
  }

  String _tanggalHariIni() =>
      DateFormat('EEEE, d MMMM y', 'id_ID').format(DateTime.now());
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
    onRespond: (nilai) => _catat(ref, nilai),
  );

  Future<void> _catat(WidgetRef ref, ResponseLevel nilai) async {
    await ref
        .read(rencanaRepositoryProvider)
        .catatRespons(jadwalAktivitasId: item.id, nilai: nilai);
    ref
      ..invalidate(agendaHariIniProvider)
      ..invalidate(rencanaMingguanProvider);
  }
}
