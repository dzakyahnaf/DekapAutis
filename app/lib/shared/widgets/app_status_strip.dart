import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/accessibility/accessibility_prefs.dart';
import '../../core/strings.dart';
import '../../core/theme/tokens.dart';
import '../../data/providers.dart';
import 'calm_mode_switch.dart';
import 'offline_banner.dart';

/// The two pieces of app state that must never be hidden, mounted once.
///
/// Calm Mode being on, and writes waiting to sync, are both facts about the
/// whole application rather than about whichever screen happens to be in front
/// of the user. Before this they were pasted into individual screens - the
/// offline banner into two of nine, the Calm Mode pill into three - which meant
/// the answer to "am I offline?" depended on which tab you were looking at.
///
/// Mounted in `MaterialApp.builder`, so it sits above every route including
/// ones that have not been written yet, and no screen has to remember it.
class AppStatusStrip extends ConsumerWidget {
  const AppStatusStrip({required this.child, super.key});

  final Widget? child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calm = ref.watch(calmModeProvider);
    final menunggu = ref.watch(menungguSinkronProvider).value ?? 0;

    // Nothing to say: stay out of the tree entirely rather than adding an
    // empty Column that would shift every screen down by a hairline.
    if (!calm && menunggu <= 0) return child ?? const SizedBox.shrink();

    return Material(
      color: DekapColors.background,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            if (calm)
              const Padding(
                padding: EdgeInsets.fromLTRB(
                  DekapSpace.screenPadding,
                  DekapSpace.cardGap / 2,
                  DekapSpace.screenPadding,
                  0,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: CalmModePill(),
                ),
              ),
            OfflineBanner(pendingCount: menunggu),
            Expanded(child: child ?? const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }
}

/// Text form of the same two facts, for the accessibility screen.
String ringkasanStatus({required bool modeTenang, required int menunggu}) {
  final bagian = <String>[
    if (modeTenang) S.modeTenangAktif,
    if (menunggu > 0) S.luringMenunggu(menunggu),
  ];
  return bagian.isEmpty ? S.statusNormal : bagian.join('. ');
}
