import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

/// Four-segment progress bar for onboarding (L.1).
///
/// Static by requirement, not by omission. There is no AnimatedContainer, no
/// implicit animation and no controller anywhere in this widget: a bar that
/// slides or fills on every step is a small repeating movement, and repeating
/// movement is the one pattern this product will not ship. `flutter analyze`
/// cannot catch a stray animation, so `step_indicator_test.dart` does.
///
/// Segments are also distinguishable without colour - the completed ones are
/// taller as well as darker - and the whole row carries a spoken label, because
/// a bare row of boxes tells a screen reader nothing.
class StepIndicator extends StatelessWidget {
  const StepIndicator({
    required this.langkahSaatIni,
    this.totalLangkah = 4,
    super.key,
  });

  /// 1-based.
  final int langkahSaatIni;

  final int totalLangkah;

  static const _tinggiSelesai = 8.0;
  static const _tinggiBelum = 5.0;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Langkah $langkahSaatIni dari $totalLangkah',
    excludeSemantics: true,
    child: Row(
      children: [
        for (var i = 1; i <= totalLangkah; i++) ...[
          Expanded(
            child: Container(
              height: i <= langkahSaatIni ? _tinggiSelesai : _tinggiBelum,
              decoration: BoxDecoration(
                color: i <= langkahSaatIni
                    ? DekapColors.purple700
                    : DekapColors.purple100,
                borderRadius: BorderRadius.circular(_tinggiSelesai / 2),
              ),
            ),
          ),
          if (i != totalLangkah) const SizedBox(width: DekapSpace.cardGap / 2),
        ],
      ],
    ),
  );
}
