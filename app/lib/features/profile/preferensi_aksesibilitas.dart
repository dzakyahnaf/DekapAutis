import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/accessibility/accessibility_prefs.dart';
import '../../core/strings.dart';
import '../../core/theme/tokens.dart';
import '../../shared/widgets/calm_mode_switch.dart';
import '../../shared/widgets/privacy_strip.dart';

/// L.15, as a panel so it can be both its own screen and step 4 of onboarding.
///
/// Accessibility preferences are asked for during onboarding rather than buried
/// in settings, because the person who needs larger text needs it on the very
/// first screen they read, not after they have found their way to a menu.
class PreferensiAksesibilitasPanel extends ConsumerWidget {
  const PreferensiAksesibilitasPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(accessibilityProvider);
    final kontrol = ref.read(accessibilityProvider.notifier);
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const CalmModeSwitch(),
        const SizedBox(height: DekapSpace.cardPadding),

        Text('Ukuran teks', style: text.titleMedium),
        const SizedBox(height: DekapSpace.cardGap),
        for (final skala in DekapTextScale.values) ...[
          OptionTile(
            label: skala.label,
            terpilih: prefs.textScale == skala,
            onTap: () => kontrol.setTextScale(skala),
          ),
          const SizedBox(height: DekapSpace.cardGap / 1.5),
        ],

        const SizedBox(height: DekapSpace.cardGap / 2),
        PratinjauUkuranTeks(skala: prefs.textScale),

        const SizedBox(height: DekapSpace.cardPadding),
        _KartuKurangiGerak(
          aktif: prefs.reduceMotion,
          onUbah: (v) => kontrol.setReduceMotion(enabled: v),
        ),
      ],
    );
  }
}

/// The live preview box.
///
/// It applies the chosen scale to its own subtree only, so the sample really is
/// rendered at that size the moment the choice changes - not after saving, and
/// not as an illustration of what would happen. A preview that does not move is
/// worse than no preview: it teaches the user that the control does nothing.
class PratinjauUkuranTeks extends StatelessWidget {
  const PratinjauUkuranTeks({required this.skala, super.key});

  final DekapTextScale skala;

  /// Test hook, so the assertion measures the sample and nothing else.
  static const kunciContoh = Key('pratinjau-ukuran-teks-contoh');

  static const contoh =
      'Rencana hari ini punya lima aktivitas. Setelah selesai, tandai '
      'responsnya.';

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DekapSpace.cardPadding),
      decoration: BoxDecoration(
        color: DekapColors.surface,
        borderRadius: BorderRadius.circular(DekapSpace.radiusCard),
        border: Border.all(
          color: DekapColors.border,
          width: DekapSpace.borderWidth,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pratinjau', style: text.bodySmall),
          const SizedBox(height: DekapSpace.cardGap / 2),
          MediaQuery.withClampedTextScaling(
            minScaleFactor: skala.factor,
            maxScaleFactor: skala.factor,
            child: Text(contoh, key: kunciContoh, style: text.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _KartuKurangiGerak extends StatelessWidget {
  const _KartuKurangiGerak({required this.aktif, required this.onUbah});

  final bool aktif;
  final ValueChanged<bool> onUbah;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(DekapSpace.cardPadding),
      decoration: BoxDecoration(
        color: DekapColors.surface,
        borderRadius: BorderRadius.circular(DekapSpace.radiusCard),
        border: Border.all(
          color: DekapColors.border,
          width: DekapSpace.borderWidth,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Merged so the switch is announced with its name. On its own a
          // bare Switch reads as "on, switch" with nothing to say what it is.
          MergeSemantics(
            child: Row(
              children: [
                Expanded(
                  child: Text('Kurangi gerakan', style: text.titleMedium),
                ),
                Switch(value: aktif, onChanged: onUbah),
              ],
            ),
          ),
          const SizedBox(height: DekapSpace.cardGap / 2),
          Text('Semua transisi menjadi 0 milidetik.', style: text.bodySmall),
        ],
      ),
    );
  }
}

/// Standalone screen at /profil/aksesibilitas.
class AksesibilitasScreen extends StatelessWidget {
  const AksesibilitasScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text(S.titleAksesibilitas),
      actions: const [
        Padding(
          padding: EdgeInsets.only(right: DekapSpace.screenPadding),
          child: Center(child: CalmModePill()),
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.all(DekapSpace.screenPadding),
      children: const [PreferensiAksesibilitasPanel()],
    ),
  );
}
