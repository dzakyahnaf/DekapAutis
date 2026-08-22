import 'package:flutter/material.dart';

import '../../core/strings.dart';
import '../../core/theme/tokens.dart';
import 'calm_mode_switch.dart';

/// Temporary body for a route whose screen has not been built yet.
///
/// Exists only so the full route tree is navigable from F0 onwards. Every use
/// of this widget is removed as its phase lands; `flutter analyze` will point
/// at the last one left when the file is finally deleted.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    required this.title,
    required this.route,
    this.phase,
    super.key,
  });

  final String title;
  final String route;

  /// Which phase of PLAN.md fills this in, e.g. 'F5'.
  final String? phase;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: DekapSpace.screenPadding),
            child: Center(child: CalmModePill()),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(DekapSpace.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(S.belumDibangun, style: text.bodyLarge),
            const SizedBox(height: DekapSpace.cardGap),
            Text(
              phase == null ? route : '$route  -  $phase',
              style: text.bodySmall?.copyWith(fontFamily: DekapType.familyMono),
            ),
          ],
        ),
      ),
    );
  }
}
