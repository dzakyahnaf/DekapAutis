import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/strings.dart';
import '../../core/theme/tokens.dart';

/// Header strip shown while the offline write queue is not empty.
///
/// It reports a fact and a count, not a failure: recording a response with no
/// network is a supported path (KNF-02), not an error the user caused.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({required this.pendingCount, super.key});

  /// Rows waiting to sync. Zero renders nothing.
  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    if (pendingCount <= 0) return const SizedBox.shrink();

    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: DekapSpace.screenPadding,
          vertical: DekapSpace.cardGap,
        ),
        color: DekapColors.cream200,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Symbols.cloud_off_rounded,
              size: DekapSpace.iconSize - 4,
              color: DekapColors.cream700,
            ),
            const SizedBox(width: DekapSpace.cardGap),
            Expanded(
              child: Text(
                S.luringMenunggu(pendingCount),
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
