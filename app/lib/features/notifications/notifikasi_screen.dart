import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/strings.dart';
import '../../core/theme/tokens.dart';
import '../../data/models/notifikasi.dart';
import '../../data/providers.dart';
import '../../domain/notifikasi/jenis_notifikasi.dart';
import '../../shared/widgets/states.dart';

/// Icon for each kind. Kept in the widget layer so
/// `domain/notifikasi/jenis_notifikasi.dart` stays free of Flutter and can be
/// tested with `package:test`.
IconData ikonNotifikasi(JenisNotifikasi jenis) => switch (jenis) {
  JenisNotifikasi.penyesuaianRencana => Symbols.tune_rounded,
  JenisNotifikasi.persetujuanJadwal => Symbols.event_available_rounded,
  JenisNotifikasi.aktivitasBelumTercatat => Symbols.edit_note_rounded,
  JenisNotifikasi.balasanKomunitas => Symbols.forum_rounded,
  JenisNotifikasi.artikelBaru => Symbols.article_rounded,
};

/// The tinted field the icon sits in. Purple for what the app did, cream for
/// what a person did - the same two paths the rest of the design system uses.
Color bidangNotifikasi(JenisNotifikasi jenis) => switch (jenis) {
  JenisNotifikasi.balasanKomunitas => DekapColors.cream200,
  JenisNotifikasi.persetujuanJadwal => DekapColors.cream200,
  _ => DekapColors.purple100,
};

/// L.17 - notifications, grouped by when they arrived.
class NotifikasiScreen extends ConsumerWidget {
  const NotifikasiScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daftar = ref.watch(daftarNotifikasiProvider);

    return Scaffold(
      // "Tandai dibaca" sits in the body rather than the AppBar. An AppBar has
      // a fixed height, so at 200% text its label and the title fight over a
      // row that cannot grow - which is what text_scale_test.dart caught here.
      appBar: AppBar(title: const Text(S.titleNotifikasi)),
      body: SafeArea(
        top: false,
        child: daftar.when(
          loading: () => const LoadingText(),
          error: (e, _) => ErrorState(
            message: pesanKesalahan(e),
            onRetry: () => ref.invalidate(daftarNotifikasiProvider),
          ),
          data: (semua) => semua.isEmpty
              ? const EmptyState(
                  message:
                      'Belum ada pemberitahuan. Saat rencana disesuaikan atau '
                      'ada balasan di komunitas, kabarnya muncul di sini.',
                )
              : Column(
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: DekapSpace.screenPadding,
                        ),
                        child: TextButton(
                          onPressed: () async {
                            await ref
                                .read(notifikasiRepositoryProvider)
                                .tandaiSemuaDibaca();
                            ref.invalidate(daftarNotifikasiProvider);
                          },
                          child: const Text('Tandai semua dibaca'),
                        ),
                      ),
                    ),
                    Expanded(child: _Kelompok(semua: semua)),
                  ],
                ),
        ),
      ),
    );
  }
}

class _Kelompok extends ConsumerWidget {
  const _Kelompok({required this.semua});

  final List<Notifikasi> semua;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kelompok = kelompokkanSemua(semua, DateTime.now());
    final text = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(DekapSpace.screenPadding),
      children: [
        for (final entry in kelompok.entries) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: DekapSpace.cardGap),
            child: Text(entry.key.label, style: text.titleMedium),
          ),
          for (final n in entry.value) ...[
            _Baris(notifikasi: n),
            const SizedBox(height: DekapSpace.cardGap),
          ],
          const SizedBox(height: DekapSpace.cardGap),
        ],
      ],
    );
  }
}

class _Baris extends ConsumerWidget {
  const _Baris({required this.notifikasi});

  final Notifikasi notifikasi;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final tautan = notifikasi.tautan;

    final isi = Padding(
      padding: const EdgeInsets.all(DekapSpace.cardPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: DekapSpace.minTouch,
            height: DekapSpace.minTouch,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: bidangNotifikasi(notifikasi.jenis),
              borderRadius: BorderRadius.circular(DekapSpace.radiusControl),
            ),
            child: Icon(
              ikonNotifikasi(notifikasi.jenis),
              color: DekapColors.textPrimary,
            ),
          ),
          const SizedBox(width: DekapSpace.cardGap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(notifikasi.judul, style: text.bodyLarge),
                const SizedBox(height: 2),
                // The kind is written out as well as drawn, so the icon is
                // never the only thing carrying it.
                Text(
                  '${notifikasi.jenis.label} · '
                  '${DateFormat('HH.mm', 'id_ID').format(notifikasi.dibuatPada)}',
                  style: text.bodySmall,
                ),
              ],
            ),
          ),
          if (!notifikasi.dibaca)
            Semantics(
              label: 'Belum dibaca',
              child: Container(
                margin: const EdgeInsets.only(left: DekapSpace.cardGap, top: 6),
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: DekapColors.purple700,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );

    // A row with nowhere to go is not made to look tappable.
    if (tautan == null) {
      return Card(child: isi);
    }

    return Card(
      child: InkWell(
        onTap: () async {
          await ref
              .read(notifikasiRepositoryProvider)
              .tandaiDibaca(notifikasi.id);
          ref.invalidate(daftarNotifikasiProvider);
          if (context.mounted) context.go(tautan);
        },
        borderRadius: BorderRadius.circular(DekapSpace.radiusCard),
        child: isi,
      ),
    );
  }
}
