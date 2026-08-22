import 'package:flutter/material.dart';

import '../../core/theme/calm.dart';
import '../../core/theme/tokens.dart';

/// An illustration that turns into its own description when Calm Mode is on.
///
/// Effect 1 of the five (docs/02 section 8). Every image in the app goes
/// through this, which is also how docs/02 section 7's "every image has
/// alternative text" stays true: [label] is required, so there is no way to add
/// an illustration without writing the sentence that replaces it.
///
/// It renders the label rather than collapsing to nothing on purpose. A
/// caregiver in Calm Mode should lose the visual load, not the meaning, and a
/// layout that silently loses a block is harder to trust than one that says
/// what used to be there.
class CalmImage extends StatelessWidget {
  const CalmImage({
    required this.label,
    required this.image,
    this.height,
    super.key,
  });

  /// What the picture conveys, as a sentence. Read aloud by TalkBack and shown
  /// in place of the image in Calm Mode.
  final String label;

  /// The illustration itself. A builder, so the asset is never decoded at all
  /// when Calm Mode is on.
  final WidgetBuilder image;

  /// Optional fixed height for the normal-mode image.
  final double? height;

  @override
  Widget build(BuildContext context) {
    if (!DekapCalm.of(context).showsImagery) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(DekapSpace.cardPadding),
        decoration: BoxDecoration(
          color: DekapColors.surface,
          borderRadius: BorderRadius.circular(DekapSpace.radiusCard),
          border: Border.all(
            color: DekapColors.border,
            width: DekapSpace.borderWidth,
          ),
        ),
        child: Text(label, style: Theme.of(context).textTheme.bodySmall),
      );
    }

    return Semantics(
      image: true,
      label: label,
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: image(context),
      ),
    );
  }
}
