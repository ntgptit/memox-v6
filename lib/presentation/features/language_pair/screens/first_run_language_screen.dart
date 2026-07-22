import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:memox_v6/app/router/app_navigation.dart';
import 'package:memox_v6/core/theme/extensions/app_theme_context.dart';
import 'package:memox_v6/domain/language_pair/supported_languages.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/features/language_pair/viewmodels/first_run_language_viewmodel.dart';
import 'package:memox_v6/presentation/features/language_pair/widgets/language_select_sheet.dart';
import 'package:memox_v6/presentation/shared/layouts/mx_scaffold.dart';
import 'package:memox_v6/presentation/shared/widgets/inputs/mx_select_row.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_contextual_app_bar.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_action_errors.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_action_runner.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_banner.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_button.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_gap.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_text.dart';

/// First-run language selection (WBS 5.1.2; kit step1 per 3.15B): two
/// required selectors, save disabled until both are chosen, failures
/// keep the draft.
class FirstRunLanguageScreen extends StatelessWidget {
  const FirstRunLanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return MxScaffold(
      appBar: MxContextualAppBar(
        title: '',
        onBack: () => context.goFirstRunLanding(),
        backLabel: l10n.backLabel,
        actions: [
          MxText(l10n.stepIndicatorLabel(1, 2), role: MxTextRole.caption),
        ],
      ),
      scrollable: true,
      body: const _FirstRunLanguageBody(),
    );
  }
}

class _FirstRunLanguageBody extends HookConsumerWidget {
  const _FirstRunLanguageBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final draft = ref.watch(firstRunLanguageDraftViewmodelProvider);
    final saveState = ref.watch(saveLanguagePairViewmodelProvider);

    // A selector that was opened and closed without a choice is the only
    // way to leave a required field visibly empty, so that is when the
    // kit shows its inline error. An untouched field stays quiet.
    final learningTouched = useState(false);
    final meaningTouched = useState(false);

    listenMxAction(
      ref,
      saveLanguagePairViewmodelProvider,
      onSuccess: () => context.goFirstRunDeckSetup(),
    );

    final isComplete = draft.learningCode != null && draft.nativeCode != null;
    final isSameLanguage =
        draft.learningCode != null && draft.learningCode == draft.nativeCode;
    final isSaving = saveState is AsyncLoading<void>;
    final failure = MxActionErrors.failureOf(saveState);

    // A picked language supersedes any prior save failure and, once the
    // pair is distinct again, any same-language guidance — so clear the
    // stale banner the moment the draft changes.
    void onLanguageChanged(void Function() applyToDraft) {
      applyToDraft();
      ref.read(saveLanguagePairViewmodelProvider.notifier).reset();
    }

    // Kit step1 rhythm: s4 below the bar, s6 between body children.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MxGap.s4(),
        MxText(l10n.firstRunLanguageTitle, role: MxTextRole.title),
        const MxGap.s6(),
        if (failure != null) ...[
          MxBanner(
            tone: MxBannerTone.error,
            title: l10n.saveFailedTitle,
            body: MxActionErrors.messageOf(failure, l10n),
          ),
          const MxGap.s6(),
        ],
        _LanguageSelectorField(
          label: l10n.learningLanguageLabel,
          selectedCode: draft.learningCode,
          onDismissedEmpty: () => learningTouched.value = true,
          onSelected: (code) => onLanguageChanged(
            () => ref
                .read(firstRunLanguageDraftViewmodelProvider.notifier)
                .setLearningLanguage(code),
          ),
        ),
        // The kit renders the message as a sibling of the row on the body
        // rhythm, not inside it, and leaves the row's own border alone
        // (`CreateDeckFirstRun.jsx` §5).
        if (learningTouched.value && draft.learningCode == null) ...[
          const MxGap.s6(),
          _RequiredSelectionError(
            message: l10n.learningLanguageRequiredMessage,
          ),
        ],
        const MxGap.s6(),
        _LanguageSelectorField(
          label: l10n.meaningLanguageLabel,
          selectedCode: draft.nativeCode,
          onDismissedEmpty: () => meaningTouched.value = true,
          onSelected: (code) => onLanguageChanged(
            () => ref
                .read(firstRunLanguageDraftViewmodelProvider.notifier)
                .setMeaningLanguage(code),
          ),
        ),
        // One meaning-field guidance line: the empty-required message when
        // the field was left blank, the distinct-pair message when it
        // duplicates the learning language, nothing otherwise.
        if (_meaningError(l10n, draft, meaningTouched.value, isSameLanguage)
            case final String message) ...[
          const MxGap.s6(),
          _RequiredSelectionError(message: message),
        ],
        const MxGap.s6(),
        MxText(l10n.languagePairsHelperText, role: MxTextRole.caption),
        const MxGap.s6(),
        MxButton(
          label: l10n.continueLabel,
          block: true,
          onPressed: isComplete && !isSameLanguage && !isSaving
              ? () => ref
                    .read(saveLanguagePairViewmodelProvider.notifier)
                    .saveLanguagePair()
              : null,
        ),
      ],
    );
  }
}

/// The single meaning-field guidance message, if any: empty-required beats
/// distinct-pair, and a valid distinct selection shows nothing.
String? _meaningError(
  AppLocalizations l10n,
  FirstRunLanguageDraft draft,
  bool meaningTouched,
  bool isSameLanguage,
) {
  if (meaningTouched && draft.nativeCode == null) {
    return l10n.meaningLanguageRequiredMessage;
  }
  if (isSameLanguage) return l10n.meaningLanguageDistinctMessage;
  return null;
}

class _LanguageSelectorField extends StatelessWidget {
  const _LanguageSelectorField({
    required this.label,
    required this.selectedCode,
    required this.onSelected,
    required this.onDismissedEmpty,
  });

  final String label;
  final String? selectedCode;
  final ValueChanged<String> onSelected;

  /// Fired when the picker closes with nothing chosen, which is what
  /// marks the field touched.
  final VoidCallback onDismissedEmpty;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final selected = _selectedLanguage();

    return MxSelectRow(
      label: label,
      // Kit SelectRow shows the plain language name; the picker sheet
      // carries the native-name detail.
      value: selected == null
          ? l10n.selectLanguagePlaceholder
          : selected.englishName,
      onTap: () async {
        final code = await showLanguageSelectSheet(
          context,
          title: label,
          selected: selectedCode,
        );
        if (code == null) {
          onDismissedEmpty();
          return;
        }
        onSelected(code);
      },
    );
  }

  SupportedLanguage? _selectedLanguage() {
    final code = selectedCode;
    if (code == null) return null;
    for (final language in supportedLanguages) {
      if (language.code == code) return language;
    }
    return null;
  }
}

/// The kit `field-group__error` line: sm, error-colored, announced.
class _RequiredSelectionError extends StatelessWidget {
  const _RequiredSelectionError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: MxText(
        message,
        role: MxTextRole.caption,
        color: context.colors.error,
      ),
    );
  }
}
