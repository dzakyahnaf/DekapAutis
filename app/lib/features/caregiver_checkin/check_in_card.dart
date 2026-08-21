import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../data/providers.dart';

/// Caregiver check-in on the home screen (KF-13).
///
/// On the cream path, not the purple one. The colour coding says the app looks
/// after two people: purple is the system and the child's plan, cream is the
/// caregiver. That distinction is the reason this card exists at all.
///
/// It asks how the *caregiver* is, never how the child is. Bab 4.2 forbids
/// producing a single score of a child's ability, and a five-point scale on the
/// home screen is exactly the shape such a score would take.
class CheckInCard extends ConsumerWidget {
  const CheckInCard({super.key});

  static const tingkat = <int, String>{
    1: 'Berat',
    2: 'Lelah',
    3: 'Biasa',
    4: 'Cukup baik',
    5: 'Baik',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final terpilih = ref.watch(checkInHariIniProvider).value;
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(DekapSpace.cardPadding),
      decoration: BoxDecoration(
        color: DekapColors.cream200,
        borderRadius: BorderRadius.circular(DekapSpace.radiusCard),
        border: Border.all(
          color: DekapColors.border,
          width: DekapSpace.borderWidth,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bagaimana kondisi Anda hari ini?', style: text.titleMedium),
          const SizedBox(height: DekapSpace.cardGap),
          Row(
            children: [
              for (final entri in tingkat.entries) ...[
                Expanded(
                  child: _Pilihan(
                    label: entri.value,
                    aktif: terpilih == entri.key,
                    onTap: () async {
                      await ref
                          .read(rencanaRepositoryProvider)
                          .catatCheckIn(entri.key);
                      ref.invalidate(checkInHariIniProvider);
                    },
                  ),
                ),
                if (entri.key != tingkat.length)
                  const SizedBox(width: DekapSpace.cardGap / 2),
              ],
            ],
          ),
          const SizedBox(height: DekapSpace.cardGap),
          Text('Hanya untuk Anda, tidak dibagikan.', style: text.bodySmall),
        ],
      ),
    );
  }
}

class _Pilihan extends StatelessWidget {
  const _Pilihan({
    required this.label,
    required this.aktif,
    required this.onTap,
  });

  final String label;
  final bool aktif;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: aktif,
    label: 'Kondisi $label',
    excludeSemantics: true,
    child: Material(
      color: aktif ? DekapColors.cream700 : DekapColors.surface,
      borderRadius: BorderRadius.circular(DekapSpace.radiusControl),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DekapSpace.radiusControl),
        child: Container(
          constraints: const BoxConstraints(minHeight: DekapSpace.minTouch),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(DekapSpace.radiusControl),
            border: Border.all(
              color: aktif ? DekapColors.cream700 : DekapColors.border,
              width: DekapSpace.borderWidth,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: aktif ? DekapColors.surface : DekapColors.textPrimary,
            ),
          ),
        ),
      ),
    ),
  );
}
