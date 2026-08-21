import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

/// The one primary action on a screen. There are never more than three primary
/// actions on any screen, and usually one.
///
/// Labels name their result ("Simpan catatan"), never the mechanism ("Kirim").
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = true,
    super.key,
  });

  final String label;

  /// Null disables the button. Disabled still meets the touch-target minimum so
  /// screen readers can find and announce it.
  final VoidCallback? onPressed;

  final IconData? icon;

  /// Fills the available width. Off for buttons that sit side by side.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final child = FilledButton(
      onPressed: onPressed,
      style: expand
          ? null
          : FilledButton.styleFrom(
              minimumSize: const Size(
                DekapSpace.minTouch,
                DekapSpace.buttonHeight,
              ),
            ),
      child: _ButtonContent(label: label, icon: icon),
    );
    return expand ? SizedBox(width: double.infinity, child: child) : child;
  }
}

/// Supporting action. Outlined rather than filled, so the primary action stays
/// unambiguous at a glance.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = true,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final child = OutlinedButton(
      onPressed: onPressed,
      style: expand
          ? null
          : OutlinedButton.styleFrom(
              minimumSize: const Size(
                DekapSpace.minTouch,
                DekapSpace.buttonHeight,
              ),
            ),
      child: _ButtonContent(label: label, icon: icon),
    );
    return expand ? SizedBox(width: double.infinity, child: child) : child;
  }
}

/// Wraps rather than truncates, so a label still reads at 200% text scale.
class _ButtonContent extends StatelessWidget {
  const _ButtonContent({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final text = Flexible(child: Text(label, textAlign: TextAlign.center));
    if (icon == null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [text],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Decorative: the adjacent label already carries the meaning.
        Icon(icon, size: DekapSpace.iconSize),
        const SizedBox(width: DekapSpace.cardGap / 1.5),
        text,
      ],
    );
  }
}
