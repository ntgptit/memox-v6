import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:memox_v6/domain/flashcard/card_translation.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/features/flashcard/viewmodels/card_translations_viewmodel.dart';
import 'package:memox_v6/presentation/shared/hooks/mx_text_hooks.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_action_errors.dart';
import 'package:memox_v6/presentation/shared/widgets/inputs/mx_text_field.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_gap.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_icon.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_icon_button.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_text.dart';

/// The additional-translations section of the Card Editor's edit mode (WBS 6.4;
/// `manage-card-translations.md`). Lists the card's extra meanings and lets the
/// user add or remove one; each mutation persists immediately with the card's
/// content-version bump. The primary meaning is never editable here.
class CardTranslationsSection extends HookConsumerWidget {
  const CardTranslationsSection({
    super.key,
    required this.cardId,
    required this.languageCode,
  });

  final String cardId;
  final String languageCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final translations = ref.watch(cardTranslationsProvider(cardId: cardId));
    final command = ref.watch(cardTranslationsCommandViewmodelProvider);
    final input = useMxTextSubmitState();

    // A committed add clears the field; a rejected add keeps the text so the
    // user can correct it (manage-card-translations.md §5).
    ref.listen(cardTranslationsCommandViewmodelProvider, (previous, next) {
      if (previous is AsyncLoading<void> && next is AsyncData<void>) {
        input.controller.clear();
      }
    });

    final isBusy = command is AsyncLoading<void>;
    final failure = MxActionErrors.failureOf(command);
    final rows = translations.value ?? const <CardTranslation>[];

    void add() {
      if (!input.canSubmit || isBusy) return;
      ref
          .read(cardTranslationsCommandViewmodelProvider.notifier)
          .addTranslation(
            cardId: cardId,
            languageCode: languageCode,
            text: input.controller.text,
          );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MxText(l10n.additionalTranslationsLabel, role: MxTextRole.overline),
        const MxGap.s3(),
        for (final translation in rows) ...[
          _TranslationRow(
            text: translation.text,
            onRemove: isBusy
                ? null
                : () => ref
                      .read(cardTranslationsCommandViewmodelProvider.notifier)
                      .removeTranslation(
                        cardId: cardId,
                        translationId: translation.id,
                      ),
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
                enabled: !isBusy,
                onChanged: (_) {},
                onSubmitted: (_) => add(),
              ),
            ),
            const MxGap.s2(),
            MxIconButton.toolbar(
              icon: Symbols.add_rounded,
              semanticLabel: l10n.addTranslationLabel,
              onPressed: input.canSubmit && !isBusy ? add : null,
            ),
          ],
        ),
        if (failure != null) ...[
          const MxGap.s2(),
          MxText(
            MxActionErrors.messageOf(failure, l10n),
            role: MxTextRole.caption,
          ),
        ],
      ],
    );
  }
}

class _TranslationRow extends StatelessWidget {
  const _TranslationRow({required this.text, required this.onRemove});

  final String text;
  final VoidCallback? onRemove;

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
