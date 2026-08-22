import 'package:flutter/material.dart';

import '../../core/theme/calm.dart';
import '../../core/theme/tokens.dart';

/// Category marker: tinted field, icon, and label.
///
/// Colour is never the only carrier of meaning. The icon and the text label are
/// always present, which is also why the contrast audit does not need to treat
/// the category hues as information-bearing graphics.
class CategoryPill extends StatelessWidget {
  const CategoryPill({required this.category, this.compact = false, super.key});

  final DekapCategory category;

  /// Drops the label to the icon plus a semantics label. Only for places where
  /// the category name is already written next to it in full.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    // Effect 2, read off the theme rather than re-derived from the provider.
    final fill = DekapCalm.of(context).categorySurface(category);

    return Semantics(
      label: 'Kategori ${category.label}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: DekapSpace.cardGap,
          vertical: DekapSpace.cardGap / 2,
        ),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(DekapSpace.radiusControl),
          border: Border.all(
            color: DekapColors.border,
            width: DekapSpace.borderWidth,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              category.icon,
              size: DekapSpace.iconSize - 4,
              color: DekapColors.textPrimary,
            ),
            if (!compact) ...[
              const SizedBox(width: DekapSpace.cardGap / 2),
              Flexible(
                child: Text(
                  category.label,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The 4px bar down the left edge of a routine card. Purely decorative: the
/// [CategoryPill] next to it carries the meaning.
class CategoryBar extends StatelessWidget {
  const CategoryBar({required this.category, super.key});

  final DekapCategory category;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: 4,
      decoration: BoxDecoration(
        color: category.base,
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );
}
