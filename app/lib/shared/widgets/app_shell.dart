import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/accessibility/accessibility_prefs.dart';
import '../../core/strings.dart';
import '../../core/theme/tokens.dart';

/// Bottom navigation shell. Five destinations, every icon always paired with
/// its label - an icon on its own is not an accessible destination.
///
/// Deviation from docs/05: the fourth destination is "Jelajah" rather than
/// "Komunitas", and it hosts the directory, the library and the community.
/// Recorded in docs/DEVIATIONS.md.
class AppShell extends ConsumerWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  static const _destinations = <_Destination>[
    _Destination(S.navBeranda, Symbols.home_rounded),
    _Destination(S.navRencana, Symbols.calendar_month_rounded),
    _Destination(S.navTanya, Symbols.chat_bubble_rounded),
    _Destination(S.navJelajah, Symbols.explore_rounded),
    _Destination(S.navProfil, Symbols.person_rounded),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reduced = ref.watch(motionSuppressedProvider);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(
              color: DekapColors.border,
              width: DekapSpace.borderWidth,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: _go,
          animationDuration: DekapMotion.transition(reduced: reduced),
          backgroundColor: DekapColors.surface,
          indicatorColor: DekapColors.purple100,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            for (final d in _destinations)
              NavigationDestination(
                icon: Icon(d.icon),
                label: d.label,
                tooltip: d.label,
              ),
          ],
        ),
      ),
    );
  }

  void _go(int index) => navigationShell.goBranch(
    index,
    // Tapping the active tab returns it to its root, the behaviour users
    // already expect from every other app they use.
    initialLocation: index == navigationShell.currentIndex,
  );
}

class _Destination {
  const _Destination(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// Segmented switch across the three surfaces inside the Jelajah tab.
class JelajahTabs extends StatelessWidget {
  const JelajahTabs({required this.current, super.key});

  final JelajahTab current;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: DekapSpace.screenPadding,
      vertical: DekapSpace.cardGap,
    ),
    child: Row(
      children: [
        for (final tab in JelajahTab.values) ...[
          Expanded(
            child: Semantics(
              button: true,
              selected: tab == current,
              label: tab.label,
              excludeSemantics: true,
              child: Material(
                color: tab == current
                    ? DekapColors.purple700
                    : DekapColors.surface,
                borderRadius: BorderRadius.circular(DekapSpace.radiusControl),
                child: InkWell(
                  onTap: () => context.go(tab.path),
                  borderRadius: BorderRadius.circular(DekapSpace.radiusControl),
                  child: Container(
                    constraints: const BoxConstraints(
                      minHeight: DekapSpace.minTouch,
                    ),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        DekapSpace.radiusControl,
                      ),
                      border: Border.all(
                        color: tab == current
                            ? DekapColors.purple700
                            : DekapColors.border,
                        width: DekapSpace.borderWidth,
                      ),
                    ),
                    child: Text(
                      tab.label,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: tab == current
                            ? DekapColors.surface
                            : DekapColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (tab != JelajahTab.values.last)
            const SizedBox(width: DekapSpace.cardGap / 1.5),
        ],
      ],
    ),
  );
}

enum JelajahTab {
  direktori('Profesional', '/direktori'),
  pustaka('Pustaka', '/pustaka'),
  komunitas('Komunitas', '/komunitas');

  const JelajahTab(this.label, this.path);

  final String label;
  final String path;
}
