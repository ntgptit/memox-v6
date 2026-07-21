import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:memox_v6/app/router/app_navigation.dart';
import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/core/utils/string_utils.dart';
import 'package:memox_v6/domain/language_pair/language_pair.dart';
import 'package:memox_v6/domain/language_pair/supported_languages.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/features/deck/viewmodels/first_run_deck_viewmodel.dart';
import 'package:memox_v6/presentation/shared/hooks/mx_text_hooks.dart';
import 'package:memox_v6/presentation/shared/layouts/mx_scaffold.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_action_errors.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_action_runner.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_async_builder.dart';
import 'package:memox_v6/presentation/shared/widgets/inputs/mx_text_area.dart';
import 'package:memox_v6/presentation/shared/widgets/inputs/mx_text_field.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_action_callout.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_banner.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_contextual_app_bar.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_link.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_section_label.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_button.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_gap.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_text.dart';

/// Step 2 of the first-run setup (WBS 5.2.3B; `create-deck.md` §6):
/// required deck name, the chosen pair summary with Change, a collapsed
/// optional description — and nothing else. Drafts survive Change/back.
class FirstRunDeckSetupScreen extends StatelessWidget {
  const FirstRunDeckSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return MxScaffold(
      appBar: MxContextualAppBar(
        title: '',
        onBack: () => context.goFirstRunLanguage(),
        backLabel: l10n.backLabel,
        actions: [
          MxText(l10n.stepIndicatorLabel(2, 2), role: MxTextRole.caption),
        ],
      ),
      scrollable: true,
      body: const _FirstRunDeckSetupBody(),
    );
  }
}

class _FirstRunDeckSetupBody extends HookConsumerWidget {
  const _FirstRunDeckSetupBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final draft = ref.read(firstRunDeckDraftViewmodelProvider);
    final createState = ref.watch(createFirstDeckViewmodelProvider);
    final activePair = ref.watch(firstRunActivePairProvider);

    final name = useMxTextSubmitState(initial: draft.name);
    final description = useMxTextValue(initial: draft.description);
    final showOptional = useState(draft.description.isNotEmpty);

    // Whether this screen was entered on top of work the user already did.
    // Captured once at mount: the draft survives Change/back, so arriving
    // with content in it means it was restored, not typed just now.
    final resumedDraft = useState(
      draft.name.isNotEmpty || draft.description.isNotEmpty,
    );

    // The created deck's id is the kept-id the submit reuses, captured
    // before the command clears the draft so success can open the deck.
    final createdDeckId = useRef<String?>(null);

    listenMxAction(
      ref,
      createFirstDeckViewmodelProvider,
      onSuccess: () {
        final deckId = createdDeckId.value;
        // Success opens the just-created (empty) deck directly, where its
        // own empty state offers add-card / add-subdeck — the first
        // content fixes the deck kind (`create-deck.md` §§1, 7).
        if (deckId != null) context.goDeckDetail(deckId);
      },
    );

    final isSubmitting = createState is AsyncLoading<void>;
    final failure = MxActionErrors.failureOf(createState);
    final nameError = _nameErrorOf(failure, l10n);

    // Kit step2 rhythm: s4 below the bar, s6 between body children.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MxGap.s4(),
        // A submit failure announces itself above the title, so the first
        // thing read after a failed attempt is why it failed and that the
        // draft survived (`create-deck.md` §9).
        if (failure != null && nameError == null) ...[
          MxActionCallout(
            tone: MxBannerTone.error,
            text: l10n.deckCreateFailedMessage,
          ),
          const MxGap.s6(),
        ],
        if (resumedDraft.value) ...[
          MxActionCallout(
            tone: MxBannerTone.info,
            icon: Symbols.history_rounded,
            text: l10n.draftKeptMessage,
            action: MxLink(
              label: l10n.startOverLabel,
              onTap: () {
                ref
                    .read(firstRunDeckDraftViewmodelProvider.notifier)
                    .clearDraft();
                name.controller.clear();
                description.controller.clear();
                showOptional.value = false;
                resumedDraft.value = false;
              },
            ),
          ),
          const MxGap.s6(),
        ],
        MxText(l10n.createFirstDeckLabel, role: MxTextRole.title),
        const MxGap.s6(),
        MxAsyncBuilder<LanguagePair?>(
          value: activePair,
          loadingLabel: l10n.loadingLabel,
          errorTitle: l10n.somethingWentWrongMessage,
          data: (context, pair) => _PairSummaryRow(pair: pair),
        ),
        const MxGap.s6(),
        MxSectionLabel(text: StringUtils.upperCased(l10n.requiredSectionTitle)),
        const MxGap.s2(),
        MxTextField(
          controller: name.controller,
          label: l10n.deckNameLabel,
          boxed: true,
          requiredField: true,
          errorText: nameError,
          enabled: !isSubmitting,
          onChanged: (value) => ref
              .read(firstRunDeckDraftViewmodelProvider.notifier)
              .setDeckName(value),
        ),
        const MxGap.s6(),
        Row(
          children: [
            MxSectionLabel(
              text: StringUtils.upperCased(l10n.optionalSectionTitle),
            ),
            const Spacer(),
            MxLink(
              label: showOptional.value ? l10n.hideLabel : l10n.showLabel,
              onTap: () => showOptional.value = !showOptional.value,
            ),
          ],
        ),
        if (showOptional.value) ...[
          const MxGap.s2(),
          // A description keeps intentional line breaks (`edit-deck.md`
          // §Description), so it is a real multi-line control. It rests at
          // one row like the kit and grows into its content, rather than
          // reserving empty rows before anything is typed.
          MxTextArea(
            controller: description.controller,
            label: l10n.deckDescriptionLabel,
            boxed: true,
            enabled: !isSubmitting,
            rows: 1,
            onChanged: (value) => ref
                .read(firstRunDeckDraftViewmodelProvider.notifier)
                .setDeckDescription(value),
          ),
        ],
        const MxGap.s6(),
        MxButton(
          // The CTA names what is happening: the work in flight while
          // submitting, the retry after a failure, the action otherwise
          // (`create-deck.md` §7). The `+` belongs to the action only —
          // it would read as "add" against progress copy.
          label: switch ((isSubmitting, failure != null && nameError == null)) {
            (true, _) => l10n.deckCreatingLabel,
            (false, true) => l10n.tryAgainLabel,
            (false, false) => l10n.createDeckLabel,
          },
          icon: isSubmitting ? null : Symbols.add_rounded,
          block: true,
          onPressed: name.canSubmit && !isSubmitting
              ? () {
                  createdDeckId.value = ref
                      .read(firstRunDeckDraftViewmodelProvider.notifier)
                      .ensureRetryDeckId();
                  ref
                      .read(createFirstDeckViewmodelProvider.notifier)
                      .createDeck();
                }
              : null,
        ),
        const MxGap.s6(),
      ],
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
      // First-run always creates a root deck, so the clash is with the
      // Library, never with a sibling (`create-deck.md` §9).
      return l10n.deckNameDuplicateRootMessage;
    }
    return null;
  }
}

class _PairSummaryRow extends StatelessWidget {
  const _PairSummaryRow({required this.pair});

  final LanguagePair? pair;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final summary = _summaryOf(pair);

    return Row(
      children: [
        Expanded(child: MxText(summary, role: MxTextRole.body)),
        MxLink(
          label: l10n.changeLabel,
          onTap: () => context.goFirstRunLanguage(),
        ),
      ],
    );
  }

  // Kit step2 summary: plain language names with the arrow glyph.
  String _summaryOf(LanguagePair? pair) {
    if (pair == null) return '';
    return '${_englishNameOf(pair.learningLanguageCode)} → '
        '${_englishNameOf(pair.nativeLanguageCode)}';
  }

  String _englishNameOf(String code) {
    for (final language in supportedLanguages) {
      if (language.code == code) return language.englishName;
    }
    return code;
  }
}
