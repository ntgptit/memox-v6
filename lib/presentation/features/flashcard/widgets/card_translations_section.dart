import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:memox_v6/domain/flashcard/card_translation_draft.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/shared/hooks/mx_text_hooks.dart';
import 'package:memox_v6/presentation/shared/widgets/inputs/mx_text_field.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_gap.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_icon.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_icon_button.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_text.dart';

/// The additional-translations section of the Card Editor's edit mode (WBS 6.4;
/// `manage-card-translations.md`).
///
/// It edits the **parent draft**, not the store. §6 is explicit — "Child edits
/// live in parent Card draft until Save", and "Removing existing translation
/// can be undone by discard parent draft" — and §3 ends the flow at "Save Card
/// atomically". This section used to write each add and remove straight
/// through, so a translation removed by mistake was gone before Save, Discard
/// restored nothing, and the removal did not even mark the editor dirty
/// (`int-99`). The create path had always worked this way; only edit mode did
/// not.
class CardTranslationsSection extends HookWidget {
  const CardTranslationsSection({
    super.key,
    required this.rows,
    required this.languageCode,
    required this.onChanged,
  });

  /// The draft's current translations, in order.
  final List<CardTranslationDraft> rows;

  final String languageCode;

  /// Hands the parent the new draft list; nothing is persisted until Save.
  final ValueChanged<List<CardTranslationDraft>> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final input = useMxTextSubmitState();

    void add() {
      if (!input.canSubmit) return;
      onChanged([
        ...rows,
        CardTranslationDraft(
          text: input.controller.text,
          languageCode: languageCode,
        ),
      ]);
      input.controller.clear();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MxText(l10n.additionalTranslationsLabel, role: MxTextRole.overline),
        const MxGap.s3(),
        for (final (index, translation) in rows.indexed) ...[
          _TranslationRow(
            text: translation.text,
            onRemove: () => onChanged([
              for (final (other, row) in rows.indexed)
                if (other != index) row,
            ]),
          ),
          const MxGap.s2(),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: MxTextField(
                controller: input.controller,
                label: l10n.addTranslationLabel,
                boxed: true,
                placeholder: l10n.addTranslationPlaceholder,
                onChanged: (_) {},
                onSubmitted: (_) => add(),
              ),
            ),
            const MxGap.s2(),
            MxIconButton.toolbar(
              icon: Symbols.add_rounded,
              semanticLabel: l10n.addTranslationLabel,
              onPressed: input.canSubmit ? add : null,
            ),
          ],
        ),
      ],
    );
  }
}

class _TranslationRow extends StatelessWidget {
  const _TranslationRow({required this.text, required this.onRemove});

  final String text;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        const MxGap.s2(),
        const MxIcon(icon: Symbols.translate_rounded),
        const MxGap.s3(),
        Expanded(child: MxText(text, role: MxTextRole.body)),
        MxIconButton.toolbar(
          icon: Symbols.close_rounded,
          semanticLabel: l10n.removeTranslationLabel,
          onPressed: onRemove,
        ),
      ],
    );
  }
}
