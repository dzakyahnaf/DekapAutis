import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/strings.dart';
import '../../core/theme/tokens.dart';
import '../../data/repositories/auth_repository.dart';
import 'buttons.dart';

/// Loading. Static text, never a shimmer.
///
/// Repeating movement is a sensory-load trigger, and this app is often open
/// while the child is also looking at the screen. That is the whole reason
/// there is no skeleton anywhere in this codebase.
class LoadingText extends StatelessWidget {
  const LoadingText({this.message = S.memuat, super.key});

  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(DekapSpace.screenPadding),
    child: Text(
      message,
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(color: DekapColors.textSecondary),
    ),
  );
}

/// Turns whatever an async provider failed with into a sentence we wrote.
///
/// CLAUDE.md rule 7: a raw English exception or a stack trace never reaches the
/// screen. The repositories already wrap their failures in [KesalahanAuth];
/// this is the net under anything that slipped past one, so a screen can pass
/// an error straight to [ErrorState] without having to remember.
String pesanKesalahan(Object? error) =>
    error is KesalahanAuth ? error.pesan : S.gagalLayanan;

/// Lets a block of text scroll when the space it was handed is too small, and
/// stays out of the way when the parent already scrolls.
///
/// Text scaling is the whole reason this exists. A message that sits on one
/// line at 100% wraps to four at 200%, and the button underneath it then falls
/// off the bottom of a fixed-height box - which is exactly what
/// `text_scale_test.dart` caught on L.3 and L.16. An unbounded parent (a
/// ListView, say) is left alone, because a scroll view inside a scroll view
/// with no height throws.
class ScrollIfCramped extends StatelessWidget {
  const ScrollIfCramped({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => constraints.hasBoundedHeight
        ? SingleChildScrollView(child: child)
        : child,
  );
}

/// Empty state. An invitation, never an apology.
class EmptyState extends StatelessWidget {
  const EmptyState({
    this.message = S.kosongUmum,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => ScrollIfCramped(
    child: Padding(
      padding: const EdgeInsets.all(DekapSpace.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, style: Theme.of(context).textTheme.bodyLarge),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: DekapSpace.cardPadding),
            SecondaryButton(
              label: actionLabel!,
              onPressed: onAction,
              expand: false,
            ),
          ],
        ],
      ),
    ),
  );
}

/// Failure state. Says what happened and what to do next. It does not
/// apologise, does not blame the user, and never shows a raw English message
/// or a stack trace.
class ErrorState extends StatelessWidget {
  const ErrorState({
    required this.message,
    this.onRetry,
    this.retryLabel = S.aksiCobaLagi,
    super.key,
  });

  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) => ScrollIfCramped(
    child: Padding(
      padding: const EdgeInsets.all(DekapSpace.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Symbols.info_rounded,
                size: DekapSpace.iconSize,
                color: DekapColors.textSecondary,
              ),
              const SizedBox(width: DekapSpace.cardGap),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ],
          ),
          if (onRetry != null) ...[
            const SizedBox(height: DekapSpace.cardPadding),
            SecondaryButton(
              label: retryLabel,
              onPressed: onRetry,
              expand: false,
            ),
          ],
        ],
      ),
    ),
  );
}
