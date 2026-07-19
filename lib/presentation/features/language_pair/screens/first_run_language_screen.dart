import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox_v6/app/router/app_navigation.dart';
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

class _FirstRunLanguageBody extends ConsumerWidget {
  const _FirstRunLanguageBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final draft = ref.watch(firstRunLanguageDraftViewmodelProvider);
    final saveState = ref.watch(saveLanguagePairViewmodelProvider);

    listenMxAction(
      ref,
      saveLanguagePairViewmodelProvider,
      onSuccess: () => context.goFirstRunDeckSetup(),
    );

    final isComplete = draft.learningCode != null && draft.nativeCode != null;
    final isSaving = saveState is AsyncLoading<void>;
    final failure = MxActionErrors.failureOf(saveState);

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
          onSelected: (code) => ref
              .read(firstRunLanguageDraftViewmodelProvider.notifier)
              .setLearningLanguage(code),
        ),
        const MxGap.s6(),
        _LanguageSelectorField(
          label: l10n.meaningLanguageLabel,
          selectedCode: draft.nativeCode,
          onSelected: (code) => ref
              .read(firstRunLanguageDraftViewmodelProvider.notifier)
              .setMeaningLanguage(code),
        ),
        const MxGap.s6(),
        MxText(l10n.languagePairsHelperText, role: MxTextRole.caption),
        const MxGap.s6(),
        MxButton(
          label: l10n.continueLabel,
          block: true,
          onPressed: isComplete && !isSaving
              ? () => ref
                    .read(saveLanguagePairViewmodelProvider.notifier)
                    .saveLanguagePair()
              : null,
        ),
      ],
    );
  }
}

class _LanguageSelectorField extends StatelessWidget {
  const _LanguageSelectorField({
    required this.label,
    required this.selectedCode,
    required this.onSelected,
  });

  final String label;
  final String? selectedCode;
  final ValueChanged<String> onSelected;

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
        if (code != null) onSelected(code);
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
