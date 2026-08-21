import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/accessibility/accessibility_prefs.dart';
import '../../core/strings.dart';
import '../../core/theme/tokens.dart';

/// The Calm Mode switch (L.15).
///
/// Calm Mode is a feature, not a setting. Flipping this changes five things at
/// once, and the state is never hidden: [CalmModePill] surfaces it in the
/// header for as long as it is on.
class CalmModeSwitch extends ConsumerWidget {
  const CalmModeSwitch({super.key});

  static const effects = <String>[
    'Gambar dan ilustrasi disembunyikan, diganti label teks',
    'Warna kategori diturunkan menjadi warna latar lembut',
    'Jarak antar elemen dilonggarkan',
    'Notifikasi yang tidak mendesak dibisukan',
    'Seluruh transisi menjadi 0 milidetik',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(accessibilityProvider);
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
          Row(
            children: [
              Expanded(child: Text(S.modeTenang, style: text.titleMedium)),
              Switch(
                value: prefs.calmMode,
                onChanged: (v) => ref
                    .read(accessibilityProvider.notifier)
                    .setCalmMode(enabled: v),
              ),
            ],
          ),
          const SizedBox(height: DekapSpace.cardGap),
          for (final effect in effects)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(effect, style: text.bodySmall),
            ),
        ],
      ),
    );
  }
}

/// Small pill in the header, so an active Calm Mode is never a hidden state.
class CalmModePill extends ConsumerWidget {
  const CalmModePill({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(calmModeProvider)) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DekapSpace.cardGap,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: DekapColors.purple100,
        borderRadius: BorderRadius.circular(DekapSpace.radiusControl),
        border: Border.all(
          color: DekapColors.purple700,
          width: DekapSpace.borderWidth,
        ),
      ),
      child: Text(
        S.modeTenangAktif,
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }
}
