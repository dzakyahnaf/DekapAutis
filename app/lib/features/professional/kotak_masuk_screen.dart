import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/strings.dart';
import '../../core/theme/tokens.dart';
import '../../data/models/profesional_admin.dart';
import '../../data/providers.dart';
import '../../domain/adaptasi/kategori.dart';
import '../../shared/widgets/states.dart';

/// The professional's inbox.
///
/// Ordered by who is waiting, not by what is newest: flagged and unanswered
/// first, then unanswered, then everything already responded to. A professional
/// opening this between appointments should see the report somebody needs an
/// answer on without reading the whole list.
class KotakMasukScreen extends ConsumerWidget {
  const KotakMasukScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final masuk = ref.watch(kotakMasukProvider);
    final verifikasi = ref.watch(statusVerifikasiProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(S.titleKotakMasuk),
        actions: [
          IconButton(
            onPressed: () => context.go('/profesional/profil'),
            icon: const Icon(Symbols.person_rounded),
            tooltip: 'Profil praktik',
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            verifikasi.maybeWhen(
              data: (s) => s == StatusVerifikasi.disetujui
                  ? const SizedBox.shrink()
                  : _PitaVerifikasi(status: s),
              orElse: () => const SizedBox.shrink(),
            ),
            Expanded(
              child: masuk.when(
                loading: () => const LoadingText(),
                error: (e, _) => ErrorState(
                  message: pesanKesalahan(e),
                  onRetry: () => ref.invalidate(kotakMasukProvider),
                ),
                data: (daftar) => daftar.isEmpty
                    ? const EmptyState(
                        message:
                            'Belum ada laporan yang dibagikan kepada Anda. '
                            'Laporan muncul di sini setelah pengasuh memberi '
                            'izin berbagi.',
                      )
                    : RefreshIndicator(
                        onRefresh: () async =>
                            ref.invalidate(kotakMasukProvider),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(
                            DekapSpace.screenPadding,
                          ),
                          itemCount: daftar.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: DekapSpace.cardGap),
                          itemBuilder: (_, i) =>
                              _KartuLaporan(laporan: daftar[i]),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Until a practice is verified it can still read what was shared with it, but
/// it is told plainly where it stands rather than left guessing.
class _PitaVerifikasi extends StatelessWidget {
  const _PitaVerifikasi({required this.status});

  final StatusVerifikasi status;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(DekapSpace.cardPadding),
    color: DekapColors.cream200,
    child: Text(switch (status) {
      StatusVerifikasi.menunggu =>
        'Profil praktik Anda sedang ditinjau administrator. Anda belum '
            'tampil di direktori sampai peninjauan selesai.',
      StatusVerifikasi.ditolak =>
        'Profil praktik Anda belum lolos peninjauan. Buka Profil praktik '
            'untuk melihat alasannya dan mengirim ulang.',
      StatusVerifikasi.disetujui => '',
    }, style: Theme.of(context).textTheme.bodySmall),
  );
}

class _KartuLaporan extends StatelessWidget {
  const _KartuLaporan({required this.laporan});

  final LaporanMasuk laporan;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final format = DateFormat('d MMM y', 'id_ID');

    return Card(
      child: InkWell(
        onTap: () => context.go('/profesional/laporan/${laporan.id}'),
        borderRadius: BorderRadius.circular(DekapSpace.radiusCard),
        child: Padding(
          padding: const EdgeInsets.all(DekapSpace.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      laporan.namaAnak == null
                          ? 'Laporan perkembangan'
                          : 'Laporan ${laporan.namaAnak}'
                                '${laporan.usiaAnak == null ? '' : ', ${laporan.usiaAnak} tahun'}',
                      style: text.titleMedium,
                    ),
                  ),
                  if (laporan.sudahDitanggapi)
                    const _Keping(
                      teks: 'Sudah ditanggapi',
                      icon: Symbols.check_rounded,
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${format.format(laporan.periodeMulai)} - '
                '${format.format(laporan.periodeSelesai)}',
                style: text.bodySmall,
              ),

              if (laporan.perluPerhatian) ...[
                const SizedBox(height: DekapSpace.cardGap),
                _PenandaPerhatian(kategori: laporan.kategoriPerhatian),
              ],

              const SizedBox(height: DekapSpace.cardGap),
              Text(
                laporan.ringkasan,
                style: text.bodySmall,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// What rule D flagged. Named, not just coloured - and phrased as something to
/// look at rather than as a verdict on the child.
class _PenandaPerhatian extends StatelessWidget {
  const _PenandaPerhatian({required this.kategori});

  final List<Kategori> kategori;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(DekapSpace.cardGap),
    decoration: BoxDecoration(
      color: DekapColors.purple100,
      borderRadius: BorderRadius.circular(DekapSpace.radiusControl),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Symbols.flag_rounded,
          size: DekapSpace.iconSize - 6,
          color: DekapColors.purple700,
        ),
        const SizedBox(width: DekapSpace.cardGap / 1.5),
        Expanded(
          child: Text(
            'Perlu diperhatikan: '
            '${kategori.map((k) => k.label).join(', ')}',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ),
      ],
    ),
  );
}

class _Keping extends StatelessWidget {
  const _Keping({required this.teks, required this.icon});

  final String teks;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: DekapSpace.cardGap,
      vertical: 4,
    ),
    decoration: BoxDecoration(
      color: DekapColors.background,
      borderRadius: BorderRadius.circular(DekapSpace.radiusControl),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: DekapSpace.iconSize - 8),
        const SizedBox(width: 4),
        Text(teks, style: Theme.of(context).textTheme.labelSmall),
      ],
    ),
  );
}
