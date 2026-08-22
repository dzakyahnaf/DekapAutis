import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';

/// Shared frame for the three administrator screens.
///
/// One switcher rather than three unconnected routes, so an administrator who
/// arrives from a notification can reach the other two queues without going
/// back through a deep link.
class AdminShell extends StatelessWidget {
  const AdminShell({
    required this.current,
    required this.title,
    required this.child,
    super.key,
  });

  final AdminTab current;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: SafeArea(
      top: false,
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: DekapSpace.screenPadding,
              vertical: DekapSpace.cardGap,
            ),
            child: Row(
              children: [
                for (final tab in AdminTab.values) ...[
                  ChoiceChip(
                    label: Text(tab.label),
                    selected: tab == current,
                    showCheckmark: false,
                    backgroundColor: DekapColors.surface,
                    selectedColor: DekapColors.purple100,
                    side: BorderSide(
                      color: tab == current
                          ? DekapColors.purple700
                          : DekapColors.border,
                      width: DekapSpace.borderWidth,
                    ),
                    labelStyle: Theme.of(context).textTheme.labelSmall,
                    padding: const EdgeInsets.symmetric(
                      horizontal: DekapSpace.cardGap,
                      vertical: DekapSpace.cardGap,
                    ),
                    onSelected: (_) => context.go(tab.path),
                  ),
                  const SizedBox(width: DekapSpace.cardGap / 1.5),
                ],
              ],
            ),
          ),
          Expanded(child: child),
        ],
      ),
    ),
  );
}

enum AdminTab {
  verifikasi('Verifikasi', '/admin/verifikasi'),
  pengetahuan('Basis pengetahuan', '/admin/pengetahuan'),
  moderasi('Moderasi', '/admin/moderasi');

  const AdminTab(this.label, this.path);

  final String label;
  final String path;
}
