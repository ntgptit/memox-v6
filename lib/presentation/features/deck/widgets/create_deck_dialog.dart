import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/features/deck/viewmodels/create_deck_dialog_viewmodel.dart';
import 'package:memox_v6/presentation/shared/dialogs/mx_dialog.dart';
import 'package:memox_v6/presentation/shared/hooks/mx_text_hooks.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_action_errors.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_action_runner.dart';
import 'package:memox_v6/presentation/shared/widgets/inputs/mx_text_field.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_button.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_gap.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_text.dart';

/// The standard create-deck dialog (WBS 5.2.4C; `create-deck.md` §8):
/// opened from the Library root (`parentDeckId == null`) and from
/// Parent/Empty decks (nested create). First-run never opens a dialog.
///
/// The form and its actions live together in the dialog body so the
/// submit state can gate both (the shared action slot is static).
Future<void> showCreateDeckDialog(
  BuildContext context, {
  String? parentDeckId,
  String? parentDeckName,
}) {
  final l10n = AppLocalizations.of(context);
  return showMxDialog<void>(
    context,
    title: l10n.createDeckTitle,
    body: _CreateDeckForm(
      parentDeckId: parentDeckId,
      parentDeckName: parentDeckName,
    ),
    actions: const [],
  );
}

class _CreateDeckForm extends HookConsumerWidget {
  const _CreateDeckForm({
    required this.parentDeckId,
    required this.parentDeckName,
  });

  final String? parentDeckId;
  final String? parentDeckName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final name = useMxTextSubmitState();
    final createState = ref.watch(createDeckDialogViewmodelProvider);

    listenMxAction(
      ref,
      createDeckDialogViewmodelProvider,
      onSuccess: () => Navigator.of(context).pop(),
    );

    final isSubmitting = createState is AsyncLoading<void>;
    final failure = MxActionErrors.failureOf(createState);
    final nameError = _nameErrorOf(failure, l10n);
    final parentName = parentDeckName;

    return Material(
      type: MaterialType.transparency,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MxText(
            parentName == null
                ? l10n.insideLibraryLabel
                : l10n.insideDeckLabel(parentName),
            role: MxTextRole.caption,
          ),
          const MxGap.s4(),
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
                label: l10n.createDeckLabel,
                onPressed: name.canSubmit && !isSubmitting
                    ? () => ref
                          .read(createDeckDialogViewmodelProvider.notifier)
                          .createDeck(
                            name: name.value,
                            parentDeckId: parentDeckId,
                          )
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
      // The field has more than one way to be invalid, so the code — not
      // the field — picks the guidance (`create-deck.md` §19).
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
