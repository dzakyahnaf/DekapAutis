import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/strings.dart';
import '../../core/theme/tokens.dart';
import '../../data/models/profil_anak.dart';
import '../../data/repositories/auth_repository.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/privacy_strip.dart';
import '../../shared/widgets/step_indicator.dart';
import '../profile/preferensi_aksesibilitas.dart';
import 'onboarding_controller.dart';

/// L.1 - four steps, one decision per screen.
///
/// The step lives in the route (`/onboarding/:langkah`), so the system back
/// gesture walks backwards through the form the way a caregiver expects, and a
/// half-finished profile can be resumed from a link.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({required this.langkah, super.key});

  final int langkah;

  static const totalLangkah = 4;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  String? _kesalahan;
  bool _menyimpan = false;

  static const _judul = <int, String>{
    1: 'Kenalkan anak Anda',
    2: 'Cara anak berkomunikasi',
    3: 'Fokus tiga bulan ke depan',
    4: 'Kenyamanan membaca',
  };

  static const _subJudul =
      'Jawaban Anda dipakai untuk menyusun rencana harian. Bisa diubah kapan saja.';

  @override
  Widget build(BuildContext context) {
    final langkah = widget.langkah.clamp(1, OnboardingScreen.totalLangkah);
    final draft = ref.watch(onboardingProvider);
    final text = Theme.of(context).textTheme;
    final terakhir = langkah == OnboardingScreen.totalLangkah;

    return Scaffold(
      appBar: AppBar(title: const Text(S.titleOnboarding)),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                DekapSpace.screenPadding,
                0,
                DekapSpace.screenPadding,
                DekapSpace.cardPadding,
              ),
              child: StepIndicator(langkahSaatIni: langkah),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: DekapSpace.screenPadding,
                ),
                children: [
                  Text(_judul[langkah]!, style: text.titleLarge),
                  const SizedBox(height: DekapSpace.cardGap / 2),
                  Text(_subJudul, style: text.bodySmall),
                  const SizedBox(height: DekapSpace.cardPadding),
                  switch (langkah) {
                    1 => _Langkah1(draft: draft),
                    2 => _Langkah2(draft: draft),
                    3 => _Langkah3(draft: draft),
                    _ => const PreferensiAksesibilitasPanel(),
                  },
                  const SizedBox(height: DekapSpace.screenPadding),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(DekapSpace.screenPadding),
              child: Column(
                children: [
                  if (_kesalahan != null) ...[
                    Text(
                      _kesalahan!,
                      style: text.bodyMedium?.copyWith(
                        color: DekapColors.boundary,
                      ),
                    ),
                    const SizedBox(height: DekapSpace.cardGap),
                  ],
                  const PrivacyStrip(),
                  const SizedBox(height: DekapSpace.cardGap),
                  PrimaryButton(
                    label: terakhir ? 'Simpan profil anak' : S.aksiLanjut,
                    onPressed: _menyimpan || !draft.langkahLengkap(langkah)
                        ? null
                        : () => terakhir ? _selesai() : _lanjut(langkah),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _lanjut(int langkah) => context.go('/onboarding/${langkah + 1}');

  Future<void> _selesai() async {
    setState(() {
      _menyimpan = true;
      _kesalahan = null;
    });
    try {
      await ref.read(onboardingProvider.notifier).simpan();
      if (!mounted) return;
      ref.read(onboardingProvider.notifier).mulaiUlang();
      context.go('/beranda');
    } on KesalahanAuth catch (e) {
      if (!mounted) return;
      setState(() {
        _kesalahan = e.pesan;
        _menyimpan = false;
      });
    }
  }
}

class _Langkah1 extends ConsumerWidget {
  const _Langkah1({required this.draft});

  final DraftProfilAnak draft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kontrol = ref.read(onboardingProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Nama panggilan', style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: DekapSpace.cardGap / 2),
        TextFormField(
          initialValue: draft.namaPanggilan,
          onChanged: kontrol.setNama,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'Nama yang biasa Anda pakai di rumah',
          ),
        ),
        const SizedBox(height: DekapSpace.cardPadding),
        Text('Usia', style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: DekapSpace.cardGap / 2),
        TextFormField(
          initialValue: draft.usia?.toString() ?? '',
          onChanged: kontrol.setUsia,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: 'Dalam tahun, 1 sampai 18',
          ),
        ),
      ],
    );
  }
}

class _Langkah2 extends ConsumerWidget {
  const _Langkah2({required this.draft});

  final DraftProfilAnak draft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kontrol = ref.read(onboardingProvider.notifier);
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Framed as how the child communicates today, never as a level. The
        // product does not grade a child.
        Text(
          'Pilih satu yang paling menggambarkan hari ini',
          style: text.bodyMedium,
        ),
        const SizedBox(height: DekapSpace.cardGap),
        for (final k in KemampuanKomunikasi.values) ...[
          OptionTile(
            label: k.label,
            terpilih: draft.kemampuanKomunikasi == k,
            onTap: () => kontrol.setKomunikasi(k),
          ),
          const SizedBox(height: DekapSpace.cardGap / 1.5),
        ],
        const SizedBox(height: DekapSpace.cardPadding),
        Text('Sensitivitas sensorik', style: text.titleMedium),
        const SizedBox(height: DekapSpace.cardGap / 2),
        Text(
          'Pilih semua yang sesuai. Boleh dikosongkan.',
          style: text.bodySmall,
        ),
        const SizedBox(height: DekapSpace.cardGap),
        Wrap(
          spacing: DekapSpace.cardGap / 1.5,
          runSpacing: DekapSpace.cardGap / 1.5,
          children: [
            for (final s in SensitivitasSensorik.values)
              MultiOptionChip(
                label: s.label,
                terpilih: draft.sensitivitasSensorik.contains(s),
                onTap: () => kontrol.toggleSensitivitas(s),
              ),
          ],
        ),
      ],
    );
  }
}

class _Langkah3 extends ConsumerWidget {
  const _Langkah3({required this.draft});

  final DraftProfilAnak draft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kontrol = ref.read(onboardingProvider.notifier);
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Pilih yang ingin Anda dampingi lebih dulu. Ini arah, bukan target '
          'yang harus tercapai.',
          style: text.bodyMedium,
        ),
        const SizedBox(height: DekapSpace.cardGap),
        Wrap(
          spacing: DekapSpace.cardGap / 1.5,
          runSpacing: DekapSpace.cardGap / 1.5,
          children: [
            for (final f in FokusPerkembangan.values)
              MultiOptionChip(
                label: f.label,
                terpilih: draft.fokusPerkembangan.contains(f),
                onTap: () => kontrol.toggleFokus(f),
              ),
          ],
        ),
      ],
    );
  }
}
