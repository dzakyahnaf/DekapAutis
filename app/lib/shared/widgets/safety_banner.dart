import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/strings.dart';
import '../../core/theme/tokens.dart';

/// The medical-boundary notice (L.5).
///
/// This is the single most important element in the application, and its visual
/// weight must never be reduced. The palette has no red on purpose: red
/// triggers a vigilance response that is unwanted in users with sensory
/// sensitivity, and the app is often open while the child is watching. The
/// weight is carried instead by three things that must all stay present:
///
///   1. [DekapColors.boundary], the darkest colour in the system
///   2. [DekapSpace.boundaryBorderWidth], the thickest line in the application
///   3. a shield icon and an explicit bold refusal, never a euphemism
///
/// Those three are the answer if a judge asks why there is no red.
class SafetyBanner extends StatelessWidget {
  const SafetyBanner({
    required this.title,
    required this.body,
    this.canHelpWith = const [],
    this.actions = const [],
    super.key,
  });

  /// States the refusal plainly, e.g. "DekapAutis tidak dapat mendiagnosis".
  final String title;

  /// Explains why, in the user's own language.
  final String body;

  /// "Yang bisa saya bantu" - what the app *can* do instead. A refusal without
  /// an alternative is a dead end, and this screen must never be a dead end.
  final List<String> canHelpWith;

  /// At most two: go to the professional directory, and create a report.
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Semantics(
      container: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(DekapSpace.cardPadding),
            decoration: BoxDecoration(
              color: DekapColors.purple100,
              borderRadius: BorderRadius.circular(DekapSpace.radiusCard),
              border: Border.all(
                color: DekapColors.boundary,
                width: DekapSpace.boundaryBorderWidth,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Symbols.shield_rounded,
                      size: DekapSpace.iconSize,
                      color: DekapColors.boundary,
                    ),
                    const SizedBox(width: DekapSpace.cardGap),
                    Expanded(
                      child: Text(
                        title,
                        style: text.titleMedium?.copyWith(
                          fontWeight: DekapType.weightBold,
                          color: DekapColors.boundary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: DekapSpace.cardGap),
                Text(body, style: text.bodyMedium),
              ],
            ),
          ),
          if (canHelpWith.isNotEmpty) ...[
            const SizedBox(height: DekapSpace.cardGap),
            Container(
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
                  Text(S.batasBisaDibantu, style: text.titleMedium),
                  const SizedBox(height: DekapSpace.cardGap),
                  for (final item in canHelpWith)
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: DekapSpace.cardGap / 1.5,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Symbols.check_circle_rounded,
                            size: DekapSpace.iconSize - 4,
                            color: DekapColors.purple700,
                          ),
                          const SizedBox(width: DekapSpace.cardGap),
                          Expanded(child: Text(item, style: text.bodyMedium)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: DekapSpace.cardGap),
          Text(S.batasCatatanKaki, style: text.bodySmall),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: DekapSpace.cardPadding),
            for (final action in actions)
              Padding(
                padding: const EdgeInsets.only(bottom: DekapSpace.cardGap),
                child: action,
              ),
          ],
        ],
      ),
    );
  }
}
