import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/theme/calm.dart';
import '../../core/theme/tokens.dart';
import '../../data/models/response_level.dart';
import 'category_pill.dart';

/// The routine card, with a fixed anatomy that is identical on the home screen
/// and on the weekly plan screen.
///
/// Predictability over novelty is the first design principle, and this widget
/// is where it is most visible: position number, time and duration, category
/// bar down the left edge, icon and title, category label, then three
/// equal-width response buttons. Same order, same shapes, everywhere.
class RoutineCard extends StatelessWidget {
  const RoutineCard({
    required this.position,
    required this.total,
    required this.time,
    required this.durationMinutes,
    required this.category,
    required this.title,
    required this.onRespond,
    this.selected,
    this.onOpen,
    super.key,
  });

  /// 1-based position within the day, shown as "1 dari 5".
  final int position;
  final int total;

  /// Already formatted for display, e.g. "08.00".
  final String time;

  final int durationMinutes;
  final DekapCategory category;
  final String title;

  /// Response already recorded, if any. Renders the matching button as active
  /// and adds a check mark.
  final ResponseLevel? selected;

  final ValueChanged<ResponseLevel> onRespond;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    // Effect 3, resolved once on the theme.
    final gap = DekapCalm.of(context).gap();

    return Semantics(
      container: true,
      label:
          'Aktivitas $position dari $total, $title, kategori '
          '${category.label}, pukul $time, $durationMinutes menit',
      child: Container(
        decoration: BoxDecoration(
          color: DekapColors.surface,
          borderRadius: BorderRadius.circular(DekapSpace.radiusCard),
          border: Border.all(
            color: DekapColors.border,
            width: DekapSpace.borderWidth,
          ),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(DekapSpace.cardGap),
                child: CategoryBar(category: category),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    0,
                    DekapSpace.cardPadding,
                    DekapSpace.cardPadding,
                    DekapSpace.cardPadding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ExcludeSemantics(
                        child: Wrap(
                          spacing: DekapSpace.cardGap,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              '$position dari $total',
                              style: text.bodySmall,
                            ),
                            Text(
                              '$time - $durationMinutes menit',
                              style: text.bodySmall,
                            ),
                            if (selected != null)
                              const Icon(
                                Symbols.check_circle_rounded,
                                size: 16,
                                color: DekapColors.purple700,
                              ),
                          ],
                        ),
                      ),
                      SizedBox(height: gap / 2),
                      ExcludeSemantics(
                        child: Text(title, style: text.titleMedium),
                      ),
                      SizedBox(height: gap / 2),
                      ExcludeSemantics(child: CategoryPill(category: category)),
                      SizedBox(height: gap),
                      _ResponseRow(selected: selected, onRespond: onRespond),
                      if (onOpen != null) ...[
                        SizedBox(height: gap / 2),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: onOpen,
                            child: const Text('Lihat panduan langkah'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Three equal-width response buttons: Mudah / Pas / Sulit (KF-05).
class _ResponseRow extends StatelessWidget {
  const _ResponseRow({required this.selected, required this.onRespond});

  final ResponseLevel? selected;
  final ValueChanged<ResponseLevel> onRespond;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (final level in ResponseLevel.values) ...[
        Expanded(
          child: Semantics(
            button: true,
            selected: selected == level,
            label: 'Catat respons ${level.label}',
            excludeSemantics: true,
            child: _ResponseButton(
              level: level,
              active: selected == level,
              onTap: () => onRespond(level),
            ),
          ),
        ),
        if (level != ResponseLevel.values.last)
          const SizedBox(width: DekapSpace.cardGap / 1.5),
      ],
    ],
  );
}

class _ResponseButton extends StatelessWidget {
  const _ResponseButton({
    required this.level,
    required this.active,
    required this.onTap,
  });

  final ResponseLevel level;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: active ? DekapColors.purple700 : DekapColors.surface,
    borderRadius: BorderRadius.circular(DekapSpace.radiusControl),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DekapSpace.radiusControl),
      child: Container(
        constraints: const BoxConstraints(
          minHeight: DekapSpace.minTouch,
          minWidth: DekapSpace.minTouch,
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(DekapSpace.radiusControl),
          border: Border.all(
            color: active ? DekapColors.purple700 : DekapColors.border,
            width: DekapSpace.borderWidth,
          ),
        ),
        child: Text(
          level.label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: active ? DekapColors.surface : DekapColors.textPrimary,
          ),
        ),
      ),
    ),
  );
}
