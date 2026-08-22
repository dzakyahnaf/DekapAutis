import 'package:dekapautis/core/router/app_router.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';
import 'support/rute.dart';

/// Every meaningful icon has a label (CLAUDE.md rule 5, docs/02 section 7).
///
/// This walks the semantics tree rather than the widget tree, because the
/// semantics tree is what TalkBack actually reads. A `Semantics` label on an
/// ancestor, an `IconButton` tooltip and an `Icon(semanticLabel:)` all end up
/// in the same place once the tree is merged, so this cannot be satisfied by
/// the wrong one of the three.
///
/// It does not replace running TalkBack on a real handset - it cannot tell
/// whether a label reads naturally aloud, only whether one exists. It catches
/// the unlabelled icon that ships silently, which is the failure that actually
/// happens.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final rute = kumpulkanRute(appRouter.configuration.routes);

  for (final path in rute) {
    testWidgets('$path is readable aloud', (tester) async {
      // Disposed inside the body, not in a tearDown: the framework's
      // "SemanticsHandle still active" check runs before tearDowns do.
      final semantics = tester.ensureSemantics();

      appRouter.go(path);
      await tester.pumpWidget(aplikasiUji());
      await tester.pumpAndSettle(const Duration(milliseconds: 100));

      final bisu = <String>[];
      _telusuri(_akar(tester), bisu);
      semantics.dispose();

      expect(
        bisu,
        isEmpty,
        reason:
            'On $path these are reachable by TalkBack but announce nothing:\n'
            '${bisu.join('\n')}',
      );
    });
  }
}

/// The root of the semantics tree, wherever the binding is keeping it.
SemanticsNode? _akar(WidgetTester tester) {
  SemanticsNode? hasil;
  void cari(PipelineOwner owner) {
    hasil ??= owner.semanticsOwner?.rootSemanticsNode;
    owner.visitChildren(cari);
  }

  cari(tester.binding.rootPipelineOwner);
  return hasil;
}

/// Collects nodes a screen reader can land on that would say nothing.
///
/// A control with no label is worse than a missing control: the user knows
/// something is there, focuses it, and hears silence.
void _telusuri(SemanticsNode? node, List<String> bisu) {
  if (node == null) return;

  final data = node.getSemanticsData();
  final berlabel =
      data.label.trim().isNotEmpty ||
      data.tooltip.trim().isNotEmpty ||
      data.value.trim().isNotEmpty;

  final bendera = data.flagsCollection;
  final bisaDitekan = data.hasAction(SemanticsAction.tap) || bendera.isButton;
  final gambar = bendera.isImage;

  // A text field announces its hint through the decoration rather than a
  // label, and is legitimately empty before the user types into it.
  final kolomTeks = bendera.isTextField;

  if ((bisaDitekan || gambar) && !berlabel && !kolomTeks) {
    bisu.add('  ${gambar ? 'image' : 'control'} at ${node.rect}');
  }

  node.visitChildren((anak) {
    _telusuri(anak, bisu);
    return true;
  });
}
