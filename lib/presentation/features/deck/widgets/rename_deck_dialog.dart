import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/features/deck/viewmodels/deck_detail_viewmodel.dart';
import 'package:memox_v6/presentation/features/deck/viewmodels/rename_deck_dialog_viewmodel.dart';
import 'package:memox_v6/presentation/shared/dialogs/mx_dialog.dart';
import 'package:memox_v6/presentation/shared/hooks/mx_text_hooks.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_action_errors.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_action_runner.dart';
import 'package:memox_v6/presentation/shared/widgets/inputs/mx_text_field.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_button.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_gap.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_text.dart';

/// The rename-deck dialog (WBS 6.1; `edit-deck.md`, kit `deck-settings--rename`).
/// Metadata-only: it changes the deck's display name and nothing else. The form
/// pre-fills the current name; Save is disabled until the field is submittable.
Future<void> showRenameDeckDialog(
  BuildContext context, {
  required String deckId,
  required String currentName,
}) {
  final l10n = AppLocalizations.of(context);
  return showMxDialog<void>(
    context,
    title: l10n.renameDeckTitle,
    body: _RenameDeckForm(deckId: deckId, currentName: currentName),
    actions: const [],
  );
}

class _RenameDeckForm extends HookConsumerWidget {
  const _RenameDeckForm({required this.deckId, required this.currentName});

  final String deckId;
  final String currentName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final name = useMxTextSubmitState(initial: currentName);
    final renameState = ref.watch(renameDeckDialogViewmodelProvider);

    listenMxAction(
      ref,
      renameDeckDialogViewmodelProvider,
      onSuccess: () {
        // The deck-detail read is a one-shot future; refresh it so the renamed
        // name updates in place (open-deck.md), then close.
        ref.invalidate(deckDetailProvider(deckId: deckId));
        Navigator.of(context).pop();
      },
    );

    final isSubmitting = renameState is AsyncLoading<void>;
    final failure = MxActionErrors.failureOf(renameState);
    final nameError = _nameErrorOf(failure, l10n);

    return Material(
      type: MaterialType.transparency,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MxTextField(
            controller: name.controller,
            label: l10n.deckNameLabel,
            requiredField: true,
            errorText: nameError,
            enabled: !isSubmitting,
          ),
          if (failure != null && nameError == null) ...[
            const MxGap.s3(),
            MxText(
              MxActionErrors.messageOf(failure, l10n),
              role: MxTextRole.caption,
            ),
          ],
          const MxGap.s6(),
          Wrap(
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              MxButton(
                label: l10n.cancelLabel,
                variant: MxButtonVariant.secondary,
                onPressed: isSubmitting
                    ? null
                    : () => Navigator.of(context).pop(),
              ),
              const MxGap.s2(),
              MxButton(
                label: l10n.saveLabel,
                onPressed: name.canSubmit && !isSubmitting
                    ? () => ref
                          .read(renameDeckDialogViewmodelProvider.notifier)
                          .rename(deckId: deckId, name: name.value)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String? _nameErrorOf(AppFailure? failure, AppLocalizations l10n) {
    if (failure is ValidationFailure && failure.field == 'deckName') {
      return switch (failure.code) {
        'too-long' => l10n.deckNameTooLongMessage,
        _ => l10n.deckNameRequiredMessage,
      };
    }
    if (failure is ConflictFailure && failure.code == 'duplicate') {
      return l10n.deckNameDuplicateMessage;
    }
    return null;
  }
}
