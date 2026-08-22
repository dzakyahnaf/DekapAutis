import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/strings.dart';
import '../../core/theme/tokens.dart';
import '../../data/models/pustaka.dart';
import '../../data/providers.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/states.dart';

final pencarianProvider = StateProvider<String>((ref) => '');

/// L.12 - the education library.
///
/// Every document here is a real, openable source. There are no invented
/// articles in this corpus, and the count at the top is a COUNT(*), not the
/// "148 dokumen" printed on the mockup.
class PustakaScreen extends ConsumerWidget {
  const PustakaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kata = ref.watch(pencarianProvider);
    final hasil = kata.trim().isEmpty
        ? ref.watch(pustakaTerbaruProvider)
        : ref.watch(pencarianPustakaProvider(kata));
    final jumlah = ref.watch(jumlahDokumenProvider);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text(S.titlePustaka)),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            const JelajahTabs(current: JelajahTab.pustaka),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  DekapSpace.screenPadding,
                  0,
                  DekapSpace.screenPadding,
                  DekapSpace.screenPadding,
                ),
                children: [
                  TextField(
                    onChanged: (v) =>
                        ref.read(pencarianProvider.notifier).state = v,
                    decoration: const InputDecoration(
                      hintText: 'Cari judul atau penerbit',
                      prefixIcon: Icon(Symbols.search_rounded),
                    ),
                  ),
                  const SizedBox(height: DekapSpace.cardGap),

                  // Counted from the database. If the corpus holds 60
                  // documents this says 60.
                  jumlah.when(
                    loading: () =>
                        Text('Menghitung dokumen…', style: text.bodySmall),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (n) => Text(
                      '$n dokumen dalam basis pengetahuan',
                      style: text.bodySmall,
                    ),
                  ),

                  const SizedBox(height: DekapSpace.screenPadding),
                  Text('Kategori', style: text.titleMedium),
                  const SizedBox(height: DekapSpace.cardGap),
                  Wrap(
                    spacing: DekapSpace.cardGap,
                    runSpacing: DekapSpace.cardGap,
                    children: [
                      for (final k in KategoriPustaka.values)
                        _KartuKategori(
                          kategori: k,
                          onTap: () =>
                              ref.read(pencarianProvider.notifier).state =
                                  k.label,
                        ),
                    ],
                  ),

                  const SizedBox(height: DekapSpace.screenPadding),
                  Text(
                    kata.trim().isEmpty
                        ? 'Terbaru ditinjau'
                        : 'Hasil pencarian',
                    style: text.titleMedium,
                  ),
                  const SizedBox(height: DekapSpace.cardGap),

                  hasil.when(
                    loading: () => const LoadingText(),
                    error: (e, _) => ErrorState(
                      message: pesanKesalahan(e),
                      onRetry: () {
                        ref.invalidate(pustakaTerbaruProvider);
                        ref.invalidate(pencarianPustakaProvider(kata));
                      },
                    ),
                    data: (dokumen) => dokumen.isEmpty
                        ? EmptyState(
                            message: kata.trim().isEmpty
                                ? 'Pustaka belum terisi. Dokumen akan muncul '
                                      'di sini setelah ditinjau.'
                                : 'Tidak ada dokumen yang cocok dengan '
                                      '"$kata". Coba kata lain.',
                            actionLabel: kata.trim().isEmpty
                                ? null
                                : 'Kosongkan pencarian',
                            onAction: kata.trim().isEmpty
                                ? null
                                : () =>
                                      ref
                                              .read(pencarianProvider.notifier)
                                              .state =
                                          '',
                          )
                        : Column(
                            children: [
                              for (final d in dokumen) ...[
                                KartuDokumen(dokumen: d),
                                const SizedBox(height: DekapSpace.cardGap),
                              ],
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KartuKategori extends StatelessWidget {
  const _KartuKategori({required this.kategori, required this.onTap});

  final KategoriPustaka kategori;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 160,
    child: Material(
      color: DekapColors.surface,
      borderRadius: BorderRadius.circular(DekapSpace.radiusCard),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DekapSpace.radiusCard),
        child: Container(
          constraints: const BoxConstraints(minHeight: DekapSpace.minTouch),
          padding: const EdgeInsets.all(DekapSpace.cardPadding),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(DekapSpace.radiusCard),
            border: Border.all(
              color: DekapColors.border,
              width: DekapSpace.borderWidth,
            ),
          ),
          child: Text(
            kategori.label,
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
      ),
    ),
  );
}

class KartuDokumen extends StatelessWidget {
  const KartuDokumen({required this.dokumen, super.key});

  final DokumenPustaka dokumen;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Card(
      child: InkWell(
        onTap: () => context.go('/pustaka/${dokumen.id}'),
        borderRadius: BorderRadius.circular(DekapSpace.radiusCard),
        child: Padding(
          padding: const EdgeInsets.all(DekapSpace.cardPadding),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Symbols.article_rounded, color: DekapColors.purple700),
              const SizedBox(width: DekapSpace.cardGap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(dokumen.judul, style: text.titleMedium),
                    const SizedBox(height: 4),
                    Text(dokumen.sumberRingkas, style: text.bodySmall),
                    const SizedBox(height: DekapSpace.cardGap / 2),
                    KepingTinjauan(status: dokumen.status),
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

/// Review status, always as a word. A caregiver deciding how much weight to
/// give a document has to be told, not hinted at with a colour.
class KepingTinjauan extends StatelessWidget {
  const KepingTinjauan({required this.status, super.key});

  final StatusTinjauan status;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: DekapSpace.cardGap,
      vertical: 4,
    ),
    decoration: BoxDecoration(
      color: status == StatusTinjauan.ditinjau
          ? DekapColors.purple100
          : DekapColors.background,
      borderRadius: BorderRadius.circular(DekapSpace.radiusControl),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          status == StatusTinjauan.ditinjau
              ? Symbols.verified_rounded
              : Symbols.schedule_rounded,
          size: DekapSpace.iconSize - 8,
          color: DekapColors.textSecondary,
        ),
        const SizedBox(width: 4),
        Text(status.label, style: Theme.of(context).textTheme.labelSmall),
      ],
    ),
  );
}
