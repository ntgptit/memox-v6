import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:memox_v6/app/router/app_navigation.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/shared/dialogs/mx_confirm_dialog.dart';
import 'package:memox_v6/presentation/features/flashcard/viewmodels/card_editor_viewmodel.dart';
import 'package:memox_v6/presentation/shared/hooks/mx_text_hooks.dart';
import 'package:memox_v6/presentation/shared/layouts/mx_form_footer.dart';
import 'package:memox_v6/presentation/shared/layouts/mx_scaffold.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_action_errors.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_async_builder.dart';
import 'package:memox_v6/presentation/shared/widgets/inputs/mx_text_field.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_banner.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_button.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_context_pill.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_contextual_app_bar.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_gap.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_icon.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_tappable.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_text.dart';
import 'package:memox_v6/core/utils/string_utils.dart';

/// Card Editor — create mode (WBS 5.3.2A; `create-flashcard.md`, kit
/// `flashcard-editor--create`): one focused form, single sticky Save,
/// deck-driven language labels and a deck-context pill. Duplicate
/// review, edit mode and the advanced sections land with children B/C.
class CardEditorScreen extends ConsumerWidget {
  const CardEditorScreen({super.key, required this.deckId});

  final String deckId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // guard:allow-screen-watch -- reason: the modal bar's close action
    // is the kit dirty-cancel guard over the draft state (KIT-25-06).
    final l10n = AppLocalizations.of(context);
    final isDirty = ref.watch(cardEditorDirtyViewmodelProvider);

    Future<void> close() async {
      if (!isDirty) {
        Navigator.of(context).pop();
        return;
      }
      final discard = await showMxConfirmDialog(
        context,
        icon: Symbols.delete_rounded,
        tone: MxConfirmTone.warning,
        title: l10n.discardCardTitle,
        text: l10n.discardCardBody,
        confirmLabel: l10n.discardLabel,
        cancelLabel: l10n.keepEditingLabel,
        danger: true,
      );
      if (discard && context.mounted) Navigator.of(context).pop();
    }

    return MxScaffold(
      appBar: MxContextualAppBar(
        title: l10n.newCardTitle,
        onClose: close,
        closeLabel: l10n.cancelLabel,
      ),
      scrollable: false,
      body: _CardEditorBody(deckId: deckId),
    );
  }
}

class _CardEditorBody extends HookConsumerWidget {
  const _CardEditorBody({required this.deckId});

  final String deckId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final editorContext = ref.watch(cardEditorContextProvider(deckId: deckId));

    final term = useMxTextSubmitState();
    final meaning = useMxTextSubmitState();
    final tagsInput = useMxTextValue();
    final createAnother = useState(false);
    final termTouched = useState(false);
    final meaningTouched = useState(false);

    void syncDraftState() {
      ref
          .read(cardEditorDirtyViewmodelProvider.notifier)
          .set(
            dirty:
                term.controller.text.isNotEmpty ||
                meaning.controller.text.isNotEmpty ||
                tagsInput.controller.text.isNotEmpty,
          );
      ref.read(cardEditorDuplicatesViewmodelProvider.notifier).clear();
    }

    final saveState = ref.watch(cardEditorSaveViewmodelProvider);

    // Success is signalled by the saved tick, never by the action
    // settling — a duplicate-review pause also settles without saving.
    ref.listen(cardEditorSavedTickViewmodelProvider, (previous, next) {
      if (previous == null || next <= previous) return;
      if (createAnother.value) {
        term.controller.clear();
        meaning.controller.clear();
        tagsInput.controller.clear();
        ref.read(cardEditorSaveViewmodelProvider.notifier).reset();
        return;
      }
      Navigator.of(context).pop();
    });

    final duplicates = ref.watch(cardEditorDuplicatesViewmodelProvider);
    final isSubmitting = saveState is AsyncLoading<void>;
    final failure = MxActionErrors.failureOf(saveState);

    void submit({required bool allowDuplicate}) {
      ref
          .read(cardEditorSaveViewmodelProvider.notifier)
          .createFlashcard(
            deckId: deckId,
            term: term.controller.text,
            primaryMeaning: meaning.controller.text,
            rawTagLabels: _tagLabelsOf(tagsInput.controller.text),
            allowDuplicate: allowDuplicate,
          );
    }

    return MxAsyncBuilder<CardEditorContext?>(
      value: editorContext,
      loadingLabel: l10n.loadingLabel,
      errorTitle: l10n.somethingWentWrongMessage,
      data: (context, editor) {
        if (editor == null) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const MxGap.s8(),
              MxText(l10n.deckNotFoundMessage, role: MxTextRole.body),
            ],
          );
        }

        final canSave = term.canSubmit && meaning.canSubmit && !isSubmitting;

        // Kit create state: the form scrolls while the footer (create
        // another + Save) stays pinned as sticky chrome.
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const MxGap.s4(),
                    _DeckContextPill(deckName: editor.deck.name),
                    const MxGap.s6(),
                    if (duplicates != null && duplicates.isNotEmpty) ...[
                      MxBanner(
                        tone: MxBannerTone.warning,
                        title: l10n.duplicateCardMessage(duplicates.first.term),
                        action: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            MxButton(
                              label: l10n.viewExistingLabel,
                              variant: MxButtonVariant.secondary,
                              size: MxButtonSize.sm,
                              onPressed: () =>
                                  context.goDeckDetail(duplicates.first.deckId),
                            ),
                            const MxGap.s2(),
                            MxButton(
                              label: l10n.addAnywayLabel,
                              variant: MxButtonVariant.ghost,
                              size: MxButtonSize.sm,
                              onPressed: isSubmitting
                                  ? null
                                  : () => submit(allowDuplicate: true),
                            ),
                          ],
                        ),
                      ),
                      const MxGap.s6(),
                    ],
                    if (failure != null) ...[
                      MxBanner(
                        tone: MxBannerTone.error,
                        title: l10n.cardSaveFailedMessage,
                        action: MxButton(
                          label: l10n.tryAgainLabel,
                          variant: MxButtonVariant.secondary,
                          size: MxButtonSize.sm,
                          onPressed: isSubmitting
                              ? null
                              : () => submit(allowDuplicate: false),
                        ),
                      ),
                      const MxGap.s6(),
                    ],
                    MxTextField(
                      controller: term.controller,
                      label: l10n.termFieldLabel(editor.termLanguageName),
                      boxed: true,
                      requiredField: true,
                      placeholder: l10n.enterTermPlaceholder,
                      errorText: termTouched.value && !term.canSubmit
                          ? l10n.enterTermError
                          : null,
                      enabled: !isSubmitting,
                      onChanged: (_) {
                        termTouched.value = true;
                        syncDraftState();
                      },
                    ),
                    const MxGap.s6(),
                    MxTextField(
                      controller: meaning.controller,
                      label: l10n.meaningFieldLabel(editor.meaningLanguageName),
                      boxed: true,
                      requiredField: true,
                      placeholder: l10n.enterMeaningPlaceholder,
                      errorText: meaningTouched.value && !meaning.canSubmit
                          ? l10n.enterMeaningError
                          : null,
                      enabled: !isSubmitting,
                      onChanged: (_) {
                        meaningTouched.value = true;
                        syncDraftState();
                      },
                    ),
                    const MxGap.s6(),
                    MxTextField(
                      controller: tagsInput.controller,
                      label: l10n.tagsSectionLabel,
                      boxed: true,
                      placeholder: l10n.addTagsPlaceholder,
                      enabled: !isSubmitting,
                      onChanged: (_) => syncDraftState(),
                    ),
                    const MxGap.s6(),
                  ],
                ),
              ),
            ),
            MxFormFooter(
              children: [
                _CreateAnotherToggle(
                  value: createAnother.value,
                  onChanged: isSubmitting
                      ? null
                      : (value) => createAnother.value = value,
                ),
                const MxGap.s4(),
                MxButton(
                  label: isSubmitting ? l10n.savingLabel : l10n.saveLabel,
                  block: true,
                  onPressed: canSave
                      ? () => submit(allowDuplicate: false)
                      : null,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  /// Splits the free-form tags input into labels: comma-separated,
  /// optional leading `#` per token.
  List<String> _tagLabelsOf(String raw) {
    return raw
        .split(RegExp(r'[,\s]+'))
        .map(StringUtils.trimmed)
        .map((token) => token.startsWith('#') ? token.substring(1) : token)
        .where((token) => token.isNotEmpty)
        .toList();
  }
}

/// Kit `flashcard-editor/deck-context`: the shared context pill,
/// start-aligned like the kit (never stretched).
class _DeckContextPill extends StatelessWidget {
  const _DeckContextPill({required this.deckName});

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
class _CreateAnotherToggle extends StatelessWidget {
  const _CreateAnotherToggle({required this.value, required this.onChanged});

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
