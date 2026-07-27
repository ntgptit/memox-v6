import 'package:memox_v6/domain/flashcard/card_translation_draft.dart';
import 'package:memox_v6/domain/flashcard/flashcard.dart';
import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:memox_v6/app/router/app_navigation.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/features/flashcard/widgets/card_editor_chrome.dart';
import 'package:memox_v6/presentation/features/flashcard/widgets/card_tags_section.dart';
import 'package:memox_v6/presentation/features/flashcard/widgets/card_translations_section.dart';
import 'package:memox_v6/presentation/shared/dialogs/mx_confirm_dialog.dart';
import 'package:memox_v6/presentation/features/flashcard/viewmodels/card_translations_viewmodel.dart';
import 'package:memox_v6/presentation/features/flashcard/viewmodels/card_editor_viewmodel.dart';
import 'package:memox_v6/presentation/shared/hooks/mx_text_hooks.dart';
import 'package:memox_v6/presentation/shared/layouts/mx_form_footer.dart';
import 'package:memox_v6/presentation/shared/layouts/mx_scaffold.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_action_errors.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_async_builder.dart';
import 'package:memox_v6/presentation/features/flashcard/viewmodels/card_lifecycle_viewmodel.dart';
import 'package:memox_v6/presentation/shared/widgets/inputs/mx_switch.dart';
import 'package:memox_v6/presentation/shared/widgets/inputs/mx_text_field.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_banner.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_button.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_contextual_app_bar.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_disclosure.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_setting_row.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_gap.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_snackbar.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_icon_button.dart';
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
    // Create mode has no card to hang a translation off yet, so the slot is a
    // draft the save writes once the card exists. Edit mode manages real rows
    // through `CardTranslationsSection` and leaves this unused.
    final translationDraft = useMxTextValue();
    final createAnother = useState(false);
    final moreOptionsOpen = useState(false);
    // Seeded from the card in edit mode, false in create. The displayed state
    // is local in *both* modes on purpose: the editor reads its card through a
    // one-shot provider, so re-reading after a hide would rebuild this form
    // and throw away the term/meaning the user is part-way through typing.
    final hidden = useState(editingCard?.isHidden ?? false);
    final termTouched = useState(false);
    // Kit progressive disclosure: the resting form is Term -> Meaning ->
    // Tags, and the translation slot is one tap away behind the Meaning
    // label's `+`.
    final translationsOpen = useState(false);
    final meaningTouched = useState(false);

    // Edit is dirty only when the content diverges from the loaded card
    // (edit-flashcard.md §6 — a clean edit keeps Save disabled).
    // §6: "Child edits live in parent Card draft until Save". The stored rows
    // seed the draft once; every add and remove after that is local, and
    // Discard throws the whole draft away — which is what §6 means by "can be
    // undone by discard parent draft".
    final storedTranslations = isEdit
        ? ref.watch(cardTranslationsProvider(cardId: editingCard.id)).value
        : null;
    final translationDrafts = useState<List<CardTranslationDraft>?>(null);
    useEffect(() {
      if (storedTranslations == null) return null;
      if (translationDrafts.value != null) return null;
      translationDrafts.value = [
        for (final row in storedTranslations)
          CardTranslationDraft(
            id: row.id,
            text: row.text,
            languageCode: row.languageCode,
          ),
      ];
      return null;
    }, [storedTranslations]);
    final translationRows =
        translationDrafts.value ?? const <CardTranslationDraft>[];

    // A card that already carries translations shows them without being
    // asked — disclosure hides an empty slot, never existing content.
    final hasTranslations = isEdit && translationRows.isNotEmpty;

    /// Whether the draft diverged from what is stored (§6, and the editor's
    /// own dirty-cancel guard). A removed row used to commit on the spot, so
    /// nothing here had to notice it; now Cancel has to ask.
    bool translationsDirty() {
      final stored = storedTranslations;
      if (stored == null) return false;
      if (stored.length != translationRows.length) return true;
      for (var i = 0; i < stored.length; i++) {
        if (stored[i].id != translationRows[i].id) return true;
        if (stored[i].text != translationRows[i].text) return true;
      }
      return false;
    }

    bool computeDirty() {
      if (isEdit) {
        return term.controller.text != editingCard.term ||
            meaning.controller.text != editingCard.primaryMeaning ||
            translationsDirty();
      }
      return term.controller.text.isNotEmpty ||
          meaning.controller.text.isNotEmpty ||
          tagsInput.controller.text.isNotEmpty ||
          translationDraft.controller.text.isNotEmpty ||
          hidden.value;
    }

    void syncDraftState() {
      ref
          .read(cardEditorDirtyViewmodelProvider.notifier)
          .set(dirty: computeDirty());
      ref.read(cardEditorDuplicatesViewmodelProvider.notifier).clear();
    }

    // A draft translation change has to reach the dirty guard the same way a
    // typed character does. Nothing else observes the list, so without this
    // Cancel closed silently over a removal — the guard that exists to stop
    // work being thrown away could not see the work being thrown away.
    useEffect(() {
      // Deferred: hooks run their effects inside the build phase, and Riverpod
      // refuses a provider write there.
      WidgetsBinding.instance.addPostFrameCallback((_) => syncDraftState());
      return null;
    }, [translationRows]);

    final saveState = ref.watch(cardEditorSaveViewmodelProvider);

    // Success is signalled by the saved tick, never by the action
    // settling — a duplicate-review pause also settles without saving.
    ref.listen(cardEditorSavedTickViewmodelProvider, (previous, next) {
      if (previous == null || next <= previous) return;
      // `create-flashcard.md` §7 / `edit-flashcard.md` §7. Raised before
      // either branch: the create-another path stays on the form, where a
      // cleared form is the only other sign that anything was saved.
      showMxSnackbar(
        context,
        message: isEdit ? l10n.cardUpdatedMessage : l10n.cardAddedMessage,
      );
      if (createAnother.value) {
        term.controller.clear();
        meaning.controller.clear();
        tagsInput.controller.clear();
        // The next card starts from the resting form, translation slot closed
        // — leaving the previous card's translation in an open slot would
        // silently attach it to the new one.
        translationDraft.controller.clear();
        translationsOpen.value = false;
        hidden.value = false;
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
              translations: translationDrafts.value,
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
            draftTranslation: translationDraft.controller.text,
            isHidden: hidden.value,
            // Read off the already-watched context rather than threaded
            // through every call site: `submit` is declared outside the async
            // builder that resolves `editor`.
            meaningLanguageCode: editorContext.value?.meaningLanguageCode,
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
                    CardDeckContextPill(deckName: editor.deck.name),
                    const MxGap.s6(),
                    if (duplicates != null && duplicates.isNotEmpty) ...[
                      MxBanner.stacked(
                        tone: MxBannerTone.warning,
                        message: l10n.duplicateCardMessage(
                          duplicates.first.term,
                        ),
                        stackedActions: [
                          MxButton(
                            label: l10n.viewExistingLabel,
                            variant: MxButtonVariant.secondary,
                            size: MxButtonSize.sm,
                            // Pushed, and onto the card itself.
                            //
                            // §5: "Open existing: draft retained until
                            // explicit discard/return", and §8 repeats it.
                            // This used `go` to the *deck*, which replaces the
                            // route stack — the editor and everything typed
                            // into it were gone, and Back could not bring them
                            // back. Inspecting the card you are warned about
                            // is not a decision to abandon your draft.
                            onPressed: () => context.pushEditCard(
                              duplicates.first.deckId,
                              duplicates.first.id,
                            ),
                          ),
                          const MxGap.s2(),
                          MxButton(
                            label: l10n.addAnywayLabel,
                            variant: MxButtonVariant.ghost,
                            size: MxButtonSize.sm,
                            // The override must not be re-entrant while a
                            // save is already in flight.
                            onPressed: isSubmitting
                                ? null
                                : () => submit(allowDuplicate: true),
                          ),
                        ],
                      ),
                      const MxGap.s6(),
                    ],
                    if (failure != null) ...[
                      MxBanner(
                        tone: MxBannerTone.error,
                        // `body`, not `title`: the kit draws this one as the
                        // untitled inline banner — one regular-weight sentence
                        // with Try again trailing it on the same row. Passing
                        // it as a title made it a bold heading with the action
                        // stacked underneath, which is the decision layout,
                        // not the recoverable-failure one.
                        body: _saveFailureMessage(failure, l10n),
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
                      // Unconditional, as in the kit: `FlashcardEditor.jsx`
                      // hangs this `+` off the Meaning label with no mode
                      // gate, and `manage-card-translations.md` §2 lists the
                      // entry points as "Create/Edit Card -> Add
                      // translation". It shipped gated on `isEdit`, so a card
                      // being created had no route to a translation at all —
                      // the learner had to save, reopen and edit.
                      labelAction: MxIconButton(
                        icon: Symbols.add_rounded,
                        // Distinct from the section's own "Add
                        // translation" button: this one reveals the
                        // slot, that one commits what was typed into
                        // it, and two controls on a screen must not
                        // answer to the same name.
                        semanticLabel: l10n.showTranslationFieldLabel,
                        onPressed: isSubmitting
                            ? null
                            : () => translationsOpen.value = true,
                      ),
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
                    // The create-mode translation slot, revealed by the `+`
                    // above and ordered as the kit orders it: Term -> Meaning
                    // -> Translation -> Tags. Its `close` action clears the
                    // draft as well as hiding it, so a slot reopened later
                    // starts empty rather than resurrecting text the learner
                    // dismissed.
                    if (!isEdit && translationsOpen.value) ...[
                      MxTextField(
                        controller: translationDraft.controller,
                        label: l10n.addTranslationLabel,
                        boxed: true,
                        placeholder: l10n.addTranslationPlaceholder,
                        enabled: !isSubmitting,
                        labelAction: MxIconButton(
                          icon: Symbols.close_rounded,
                          semanticLabel: l10n.removeTranslationLabel,
                          onPressed: isSubmitting
                              ? null
                              : () {
                                  translationDraft.controller.clear();
                                  translationsOpen.value = false;
                                  syncDraftState();
                                },
                        ),
                        onChanged: (_) => syncDraftState(),
                      ),
                      const MxGap.s6(),
                    ],
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
                      // Hidden until the Meaning label's `+` asks for it, or
                      // until the card already carries translations — the kit
                      // keeps the resting form Term -> Meaning -> Tags.
                      if (translationsOpen.value || hasTranslations) ...[
                        CardTranslationsSection(
                          rows: translationRows,
                          languageCode: editor.meaningLanguageCode,
                          onChanged: (rows) => translationDrafts.value = rows,
                        ),
                        const MxGap.s6(),
                      ],
                      CardTagsSection(cardId: editingCard.id),
                      const MxGap.s6(),
                    ],
                    // Kit `flashcard-editor/more-toggle`: the advanced options
                    // sit behind a disclosure so the resting form stays Term
                    // -> Meaning -> Tags. Collapsed in every kit shot, which
                    // is why only the toggle shows at rest.
                    MxDisclosure(
                      label: l10n.moreOptionsLabel,
                      open: moreOptionsOpen.value,
                      onToggle: () =>
                          moreOptionsOpen.value = !moreOptionsOpen.value,
                      child: MxSettingRow(
                        title: l10n.hideDuringStudyLabel,
                        body: l10n.hideDuringStudyBody,
                        trailing: MxSwitch(
                          value: hidden.value,
                          semanticLabel: l10n.hideDuringStudyLabel,
                          // In edit the switch acts on a stored card, so it
                          // commits straight away like every other card action
                          // (`hide-flashcard.md`: the toggle is idempotent and
                          // needs no confirm). In create there is no card yet,
                          // so it rides along with Save.
                          onChanged: isSubmitting
                              ? null
                              : (value) {
                                  hidden.value = value;
                                  if (!isEdit) {
                                    syncDraftState();
                                    return;
                                  }
                                  ref
                                      .read(
                                        cardLifecycleCommandViewmodelProvider
                                            .notifier,
                                      )
                                      .setCardHidden(
                                        cardId: editingCard.id,
                                        hidden: value,
                                      );
                                },
                        ),
                      ),
                    ),
                    const MxGap.s6(),
                  ],
                ),
              ),
            ),
            MxFormFooter(
              children: [
                if (!isEdit) ...[
                  CardCreateAnotherToggle(
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

/// What a failed save says.
///
/// §6 gives the duplicate lookup its own line — "Couldn't check for
/// duplicates. Try again." — and the distinction is not cosmetic: a save that
/// was rejected and a check that could not run leave the learner in different
/// places, one holding content the store refused and one holding content it
/// was never offered. Both read as "couldn't save this card".
String _saveFailureMessage(AppFailure failure, AppLocalizations l10n) {
  if (failure is ConflictFailure && failure.code == 'duplicate-check-failed') {
    return l10n.duplicateCheckFailedMessage;
  }
  return l10n.cardSaveFailedMessage;
}
