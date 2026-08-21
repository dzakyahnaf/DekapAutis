import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

/// Numbered, tappable reference chip that opens the Source Panel (L.4).
///
/// Every assistant answer carries at least one of these. An answer without a
/// source chip is an answer this product is not allowed to show (KNF-07), so
/// this widget is not decoration - it is the visible half of the traceability
/// guarantee.
///
/// The chip reads small but its tap target is padded out to the 48dp minimum.
class SourceChip extends StatelessWidget {
  const SourceChip({required this.number, required this.onOpen, super.key});

  /// 1-based position of the source within the answer.
  final int number;

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Sumber $number, buka rincian',
    excludeSemantics: true,
    child: InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(DekapSpace.radiusControl),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: DekapSpace.minTouch,
          minHeight: DekapSpace.minTouch,
        ),
        child: Center(
          widthFactor: 1,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DekapSpace.cardGap / 1.5,
              vertical: 2,
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
              '$number',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: DekapColors.textPrimary,
                fontFamily: DekapType.familyMono,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
