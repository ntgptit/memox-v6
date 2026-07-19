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
import 'package:memox_v6/presentation/shared/widgets/inputs/mx_text_field.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_banner.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_button.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_gap.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_icon_button.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_tappable.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_text.dart';

/// Step 2 of the first-run setup (WBS 5.2.3B; `create-deck.md` §6):
/// required deck name, the chosen pair summary with Change, a collapsed
/// optional description — and nothing else. Drafts survive Change/back.
class FirstRunDeckSetupScreen extends StatelessWidget {
  const FirstRunDeckSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MxScaffold(scrollable: true, body: _FirstRunDeckSetupBody());
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

    listenMxAction(
      ref,
      createFirstDeckViewmodelProvider,
      onSuccess: () => context.goLibrary(),
    );

    final isSubmitting = createState is AsyncLoading<void>;
    final failure = MxActionErrors.failureOf(createState);
    final nameError = _nameErrorOf(failure, l10n);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MxGap.s4(),
        Row(
          children: [
            MxIconButton(
              icon: Symbols.arrow_back,
              semanticLabel: l10n.backLabel,
              onPressed: () => context.goFirstRunLanguage(),
            ),
            const Spacer(),
            MxText(l10n.stepTwoOfTwo, role: MxTextRole.caption),
          ],
        ),
        const MxGap.s4(),
        MxText(l10n.createFirstDeckLabel, role: MxTextRole.headline),
        const MxGap.s4(),
        MxAsyncBuilder<LanguagePair?>(
          value: activePair,
          loadingLabel: l10n.loadingLabel,
          errorTitle: l10n.somethingWentWrongMessage,
          data: (context, pair) => _PairSummaryRow(pair: pair),
        ),
        const MxGap.s6(),
        MxText(
          StringUtils.upperCased(l10n.requiredSectionTitle),
          role: MxTextRole.overline,
        ),
        const MxGap.s2(),
        MxTextField(
          controller: name.controller,
          label: l10n.deckNameLabel,
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
            MxText(
              StringUtils.upperCased(l10n.optionalSectionTitle),
              role: MxTextRole.overline,
            ),
            const Spacer(),
            MxTappable(
              semanticLabel: showOptional.value
                  ? l10n.hideLabel
                  : l10n.showLabel,
              onTap: () => showOptional.value = !showOptional.value,
              child: MxText(
                showOptional.value ? l10n.hideLabel : l10n.showLabel,
                role: MxTextRole.subtitle,
              ),
            ),
          ],
        ),
        if (showOptional.value) ...[
          const MxGap.s2(),
          MxTextField(
            controller: description.controller,
            label: l10n.deckDescriptionLabel,
            enabled: !isSubmitting,
            multiline: true,
            onChanged: (value) => ref
                .read(firstRunDeckDraftViewmodelProvider.notifier)
                .setDeckDescription(value),
          ),
        ],
        if (failure != null && nameError == null) ...[
          const MxGap.s4(),
          MxBanner(
            tone: MxBannerTone.error,
            title: l10n.saveFailedTitle,
            body: MxActionErrors.messageOf(failure, l10n),
          ),
        ],
        const MxGap.s6(),
        MxButton(
          label: l10n.createDeckLabel,
          block: true,
          onPressed: name.canSubmit && !isSubmitting
              ? () => ref
                    .read(createFirstDeckViewmodelProvider.notifier)
                    .createDeck()
              : null,
        ),
        const MxGap.s6(),
      ],
    );
  }

  String? _nameErrorOf(AppFailure? failure, AppLocalizations l10n) {
    if (failure is ValidationFailure && failure.field == 'deckName') {
      return l10n.deckNameRequiredMessage;
    }
    if (failure is ConflictFailure && failure.code == 'duplicate') {
      return l10n.deckNameDuplicateMessage;
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
        Expanded(child: MxText(summary, role: MxTextRole.subtitle)),
        MxTappable(
          semanticLabel: l10n.changeLabel,
          onTap: () => context.goFirstRunLanguage(),
          child: MxText(l10n.changeLabel, role: MxTextRole.subtitle),
        ),
      ],
    );
  }

  String _summaryOf(LanguagePair? pair) {
    if (pair == null) return '';
    return '${_nativeNameOf(pair.learningLanguageCode)} → '
        '${_nativeNameOf(pair.nativeLanguageCode)}';
  }

  String _nativeNameOf(String code) {
    for (final language in supportedLanguages) {
      if (language.code == code) return language.nativeName;
    }
    return code;
  }
}
