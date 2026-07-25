import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_context_pill.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_gap.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_icon.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_tappable.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_text.dart';

/// The Card Editor's two pieces of chrome (WBS 5.3.2A): the deck-context
/// pill above the form and the sticky-footer create-another toggle.
///
/// Split out of the screen because the screen grew past the file-length
/// guard once the advanced-options disclosure landed. They stay in the
/// feature layer rather than `shared/` — both name Card Editor copy.

/// Kit `flashcard-editor/deck-context`: the shared context pill,
/// start-aligned like the kit (never stretched).
class CardDeckContextPill extends StatelessWidget {
  const CardDeckContextPill({super.key, required this.deckName});

  final String deckName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Row(
      children: [
        Flexible(
          child: MxContextPill(
            icon: Symbols.folder_rounded,
            label: l10n.deckContextLabel,
            value: deckName,
          ),
        ),
      ],
    );
  }
}

/// Kit sticky-footer toggle: create another card after saving.
class CardCreateAnotherToggle extends StatelessWidget {
  const CardCreateAnotherToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final onChanged = this.onChanged;

    return MxTappable(
      onTap: onChanged == null ? null : () => onChanged(!value),
      semanticLabel: l10n.createAnotherLabel,
      child: Row(
        children: [
          const MxGap.s1(),
          MxIcon(
            icon: value
                ? Symbols.check_box_rounded
                : Symbols.check_box_outline_blank_rounded,
          ),
          const MxGap.s3(),
          Expanded(
            child: MxText(l10n.createAnotherLabel, role: MxTextRole.body),
          ),
        ],
      ),
    );
  }
}
