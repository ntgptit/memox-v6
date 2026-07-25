import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:memox_v6/domain/flashcard/card_tag.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/features/flashcard/viewmodels/card_tags_viewmodel.dart';
import 'package:memox_v6/presentation/shared/hooks/mx_text_hooks.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_action_errors.dart';
import 'package:memox_v6/presentation/shared/widgets/inputs/mx_tag_field.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_chip.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_gap.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_text.dart';

/// The tags section of the Card Editor's edit mode (WBS 6.4;
/// `manage-card-tags.md`). Lists the card's tags as removable chips and lets
/// the user attach a new one by label; each mutation persists immediately with
/// the card's content-version bump. Removing the last user of a tag deletes it.
class CardTagsSection extends HookConsumerWidget {
  const CardTagsSection({super.key, required this.cardId});

  final String cardId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tags = ref.watch(cardTagsProvider(cardId: cardId));
    final command = ref.watch(cardTagsCommandViewmodelProvider);
    final input = useMxTextSubmitState();

    // A committed add clears the field; a rejected one keeps the text.
    ref.listen(cardTagsCommandViewmodelProvider, (previous, next) {
      if (previous is AsyncLoading<void> && next is AsyncData<void>) {
        input.controller.clear();
      }
    });

    final isBusy = command is AsyncLoading<void>;
    final failure = MxActionErrors.failureOf(command);
    final rows = tags.value ?? const <CardTag>[];

    void add() {
      if (!input.canSubmit || isBusy) return;
      ref
          .read(cardTagsCommandViewmodelProvider.notifier)
          .addTag(cardId: cardId, label: input.controller.text);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Kit `TagsField`: one bordered row carrying the tag glyph, the
        // attached chips and the entry caret. The chips are plain — the kit
        // draws no remove affordance on them, and removal stays what
        // `manage-card-tags.md` already specified, tapping the chip itself.
        MxTagField(
          label: l10n.tagsSectionLabel,
          placeholder: l10n.addTagsPlaceholder,
          controller: input.controller,
          enabled: !isBusy,
          onSubmitted: (_) => add(),
          chips: [
            for (final tag in rows)
              MxChip(
                label: tag.name,
                onTap: isBusy
                    ? null
                    : () => ref
                          .read(cardTagsCommandViewmodelProvider.notifier)
                          .removeTag(cardId: cardId, tagId: tag.id),
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
