import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/tokens.dart';
import '../../data/models/pustaka.dart';
import '../../data/providers.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/states.dart';
import 'pustaka_screen.dart';

/// One library document.
///
/// The app does not reproduce the document's text. It shows what the document
/// is, who published it, and a button to open the real thing - because
/// paraphrasing a health source into our own words is how a citation quietly
/// becomes a claim we made.
class DetailArtikelScreen extends ConsumerWidget {
  const DetailArtikelScreen({required this.id, super.key});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dokumen = ref.watch(dokumenPustakaProvider(id));

    return Scaffold(
      appBar: AppBar(title: const Text('Dokumen')),
      body: SafeArea(
        top: false,
        child: dokumen.when(
          loading: () => const LoadingText(),
          error: (e, _) => ErrorState(
            message: pesanKesalahan(e),
            onRetry: () => ref.invalidate(dokumenPustakaProvider(id)),
          ),
          data: (d) => d == null
              ? EmptyState(
                  message: 'Dokumen ini tidak ditemukan.',
                  actionLabel: 'Kembali ke pustaka',
                  onAction: () => context.go('/pustaka'),
                )
              : _Isi(dokumen: d),
        ),
      ),
    );
  }
}

class _Isi extends StatelessWidget {
  const _Isi({required this.dokumen});

  final DokumenPustaka dokumen;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(DekapSpace.screenPadding),
      children: [
        Text(dokumen.judul, style: text.titleLarge),
        const SizedBox(height: DekapSpace.cardGap / 2),
        Text(dokumen.sumberRingkas, style: text.bodyMedium),
        const SizedBox(height: DekapSpace.cardGap),
        Align(
          alignment: Alignment.centerLeft,
          child: KepingTinjauan(status: dokumen.status),
        ),

        const SizedBox(height: DekapSpace.screenPadding),
        Container(
          padding: const EdgeInsets.all(DekapSpace.cardPadding),
          decoration: BoxDecoration(
            color: DekapColors.cream50,
            borderRadius: BorderRadius.circular(DekapSpace.radiusCard),
            border: Border.all(
              color: DekapColors.border,
              width: DekapSpace.borderWidth,
            ),
          ),
          child: Text(
            'DekapAutis tidak menyalin isi dokumen ini. Tombol di bawah '
            'membuka sumber aslinya, supaya yang Anda baca adalah kata-kata '
            'penerbitnya, bukan ringkasan kami.',
            style: text.bodySmall,
          ),
        ),

        const SizedBox(height: DekapSpace.screenPadding),
        PrimaryButton(
          label: 'Buka sumber asli',
          icon: Symbols.open_in_new_rounded,
          onPressed: () => _buka(context, dokumen.url),
        ),
        const SizedBox(height: DekapSpace.cardGap),
        SelectableText(dokumen.url, style: text.bodySmall),
      ],
    );
  }

  Future<void> _buka(BuildContext context, String url) async {
    final tujuan = Uri.tryParse(url);
    final berhasil =
        tujuan != null &&
        await launchUrl(tujuan, mode: LaunchMode.externalApplication);

    if (berhasil || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Tautan tidak dapat dibuka di perangkat ini. Alamatnya tertera di '
          'bawah tombol dan bisa Anda salin.',
        ),
      ),
    );
  }
}
