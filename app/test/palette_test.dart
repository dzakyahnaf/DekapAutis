import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Stops palette drift, which is the kind of bug the eye cannot catch.
///
/// docs/02 makes token references a contract: no widget declares a colour of
/// its own. Only `tokens.dart` may hold literal colour values, and only the two
/// permitted families may appear there.
void main() {
  final libDir = Directory('lib');

  /// Files allowed to contain literal colour values.
  const allowed = {'lib/core/theme/tokens.dart'};

  test('no literal Color() outside tokens.dart', () {
    final literal = RegExp(r'Color\(0x[0-9A-Fa-f]{8}\)');
    final offenders = <String>[];

    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path.replaceAll(r'\', '/');
      if (allowed.contains(path)) continue;

      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (literal.hasMatch(lines[i])) {
          offenders.add('$path:${i + 1}  ${lines[i].trim()}');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'Colours belong in tokens.dart:\n${offenders.join('\n')}',
    );
  });

  test('no Colors.* shorthand outside the transparent escape hatch', () {
    // Colors.transparent is permitted: it disables Material's surface tint,
    // which is how elevation is switched off. Any other Colors.* constant would
    // introduce a hue from outside the two families.
    final shorthand = RegExp(r'\bColors\.(?!transparent\b)\w+');
    final offenders = <String>[];

    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path.replaceAll(r'\', '/');
      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (shorthand.hasMatch(lines[i])) {
          offenders.add('$path:${i + 1}  ${lines[i].trim()}');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Material colours are outside the palette:\n'
          '${offenders.join('\n')}',
    );
  });
}
