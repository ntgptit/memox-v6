import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:memox_v6/app/router/app_navigation.dart';
import 'package:memox_v6/domain/flashcard/flashcard.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/features/flashcard/widgets/card_translations_section.dart';
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

/// Card Editor (WBS 5.3.2A create; WBS 6.3 edit — `create-flashcard.md`,
/// `edit-flashcard.md`, kit `flashcard-editor--create`): one focused form,
/// single sticky Save, deck-driven language labels and a deck-context pill.
/// [cardId] non-null opens edit mode — the form prefills from the existing
/// card and rewrites its content; null is create mode.
class CardEditorScreen extends ConsumerWidget {
  const CardEditorScreen({super.key, required this.deckId, this.cardId});

  final String deckId;
  final String? cardId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // guard:allow-screen-watch -- reason: the modal bar's close action
    // is the kit dirty-cancel guard over the draft state (KIT-25-06).
    final l10n = AppLocalizations.of(context);
    final isDirty = ref.watch(cardEditorDirtyViewmodelProvider);
    final cardId = this.cardId;

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
        title: cardId == null ? l10n.newCardTitle : l10n.editCardTitle,
        onClose: close,
        closeLabel: l10n.cancelLabel,
      ),
      scrollable: false,
      body: cardId == null
          ? _CardEditorForm(deckId: deckId, editingCard: null)
          : _EditCardLoader(deckId: deckId, cardId: cardId),
    );
  }
}

/// Resolves the card to edit before the form's hooks are created, so the
/// term/meaning fields prefill from stable initial values (WBS 6.3).
class _EditCardLoader extends ConsumerWidget {
  const _EditCardLoader({required this.deckId, required this.cardId});

  final String deckId;
  final String cardId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final card = ref.watch(editingCardProvider(cardId: cardId));

    return MxAsyncBuilder<Flashcard?>(
      value: card,
      loadingLabel: l10n.loadingLabel,
      errorTitle: l10n.somethingWentWrongMessage,
      data: (context, value) => value == null
          ? _CardNotFound(l10n: l10n)
          : _CardEditorForm(deckId: deckId, editingCard: value),
    );
  }
}

class _CardNotFound extends StatelessWidget {
  const _CardNotFound({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MxGap.s8(),
        MxText(l10n.cardNotFoundMessage, role: MxTextRole.body),
      ],
    );
  }
}

class _CardEditorForm extends HookConsumerWidget {
  const _CardEditorForm({required this.deckId, required this.editingCard});

  final String deckId;
  final Flashcard? editingCard;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final editorContext = ref.watch(cardEditorContextProvider(deckId: deckId));
    final editingCard = this.editingCard;
    final isEdit = editingCard != null;

    final term = useMxTextSubmitState(initial: editingCard?.term ?? '');
    final meaning = useMxTextSubmitState(
      initial: editingCard?.primaryMeaning ?? '',
    );
    final tagsInput = useMxTextValue();
    final createAnother = useState(false);
    final termTouched = useState(false);
    final meaningTouched = useState(false);

    // Edit is dirty only when the content diverges from the loaded card
    // (edit-flashcard.md §6 — a clean edit keeps Save disabled).
    bool computeDirty() {
      if (isEdit) {
        return term.controller.text != editingCard.term ||
            meaning.controller.text != editingCard.primaryMeaning;
      }
      return term.controller.text.isNotEmpty ||
          meaning.controller.text.isNotEmpty ||
          tagsInput.controller.text.isNotEmpty;
    }

    void syncDraftState() {
      ref
          .read(cardEditorDirtyViewmodelProvider.notifier)
          .set(dirty: computeDirty());
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
      if (isEdit) {
        ref
            .read(cardEditorSaveViewmodelProvider.notifier)
            .editFlashcard(
              cardId: editingCard.id,
              term: term.controller.text,
              primaryMeaning: meaning.controller.text,
              expectedContentVersion: editingCard.contentVersion,
              allowDuplicate: allowDuplicate,
            );
        return;
      }
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

        final canSave =
            term.canSubmit &&
            meaning.canSubmit &&
            !isSubmitting &&
            (!isEdit || computeDirty());

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
                    // Tags are create-only here; editing a card's tags is the
                    // manage-card-tags flow (WBS 6.4).
                    if (!isEdit) ...[
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
                    // Additional translations manage in place on an existing
                    // card (WBS 6.4); create adds them after the first save.
                    if (isEdit) ...[
                      CardTranslationsSection(
                        cardId: editingCard.id,
                        languageCode: editor.meaningLanguageCode,
                      ),
                      const MxGap.s6(),
                    ],
                  ],
                ),
              ),
            ),
            MxFormFooter(
              children: [
                if (!isEdit) ...[
                  _CreateAnotherToggle(
                    value: createAnother.value,
                    onChanged: isSubmitting
                        ? null
                        : (value) => createAnother.value = value,
                  ),
                  const MxGap.s4(),
                ],
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
