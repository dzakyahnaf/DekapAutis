import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/strings.dart';
import '../../core/theme/tokens.dart';

/// The privacy strip that sits above the submit button on L.1.
///
/// It is placed where the decision is made rather than in a settings screen
/// nobody opens: the moment a caregiver is about to hand over their child's
/// details is the moment the promise is worth reading.
class PrivacyStrip extends StatelessWidget {
  const PrivacyStrip({this.pesan = S.pitaPrivasi, super.key});

  final String pesan;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(DekapSpace.cardGap),
    decoration: BoxDecoration(
      color: DekapColors.cream50,
      borderRadius: BorderRadius.circular(DekapSpace.radiusControl),
      border: Border.all(
        color: DekapColors.border,
        width: DekapSpace.borderWidth,
      ),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Symbols.lock_rounded,
          size: DekapSpace.iconSize - 4,
          color: DekapColors.cream700,
        ),
        const SizedBox(width: DekapSpace.cardGap),
        Expanded(
          child: Text(pesan, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    ),
  );
}

/// Single-select option row. Used for communication ability on L.1 and for text
/// size on L.15.
class OptionTile extends StatelessWidget {
  const OptionTile({
    required this.label,
    required this.terpilih,
    required this.onTap,
    this.keterangan,
    super.key,
  });

  final String label;
  final String? keterangan;
  final bool terpilih;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    selected: terpilih,
    button: true,
    excludeSemantics: true,
    child: Material(
      color: terpilih ? DekapColors.purple100 : DekapColors.surface,
      borderRadius: BorderRadius.circular(DekapSpace.radiusControl),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DekapSpace.radiusControl),
        child: Container(
          constraints: const BoxConstraints(minHeight: DekapSpace.minTouch),
          padding: const EdgeInsets.all(DekapSpace.cardPadding),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(DekapSpace.radiusControl),
            border: Border.all(
              color: terpilih ? DekapColors.purple700 : DekapColors.border,
              width: terpilih ? DekapSpace.focusWidth : DekapSpace.borderWidth,
            ),
          ),
          child: Row(
            children: [
              // Selection is never carried by colour alone.
              Icon(
                terpilih
                    ? Symbols.radio_button_checked_rounded
                    : Symbols.radio_button_unchecked_rounded,
                size: DekapSpace.iconSize,
                color: terpilih
                    ? DekapColors.purple700
                    : DekapColors.textSecondary,
              ),
              const SizedBox(width: DekapSpace.cardGap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: Theme.of(context).textTheme.bodyLarge),
                    if (keterangan != null)
                      Text(
                        keterangan!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Multi-select chip. Used for sensory sensitivity and development focus.
class MultiOptionChip extends StatelessWidget {
  const MultiOptionChip({
    required this.label,
    required this.terpilih,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool terpilih;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    selected: terpilih,
    button: true,
    excludeSemantics: true,
    child: Material(
      color: terpilih ? DekapColors.purple100 : DekapColors.surface,
      borderRadius: BorderRadius.circular(DekapSpace.radiusControl),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DekapSpace.radiusControl),
        child: Container(
          constraints: const BoxConstraints(minHeight: DekapSpace.minTouch),
          padding: const EdgeInsets.symmetric(
            horizontal: DekapSpace.cardPadding,
            vertical: DekapSpace.cardGap,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(DekapSpace.radiusControl),
            border: Border.all(
              color: terpilih ? DekapColors.purple700 : DekapColors.border,
              width: terpilih ? DekapSpace.focusWidth : DekapSpace.borderWidth,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                terpilih
                    ? Symbols.check_box_rounded
                    : Symbols.check_box_outline_blank_rounded,
                size: DekapSpace.iconSize - 4,
                color: terpilih
                    ? DekapColors.purple700
                    : DekapColors.textSecondary,
              ),
              const SizedBox(width: DekapSpace.cardGap / 1.5),
              Flexible(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
