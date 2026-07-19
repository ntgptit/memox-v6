import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:memox_v6/app/router/app_navigation.dart';
import 'package:memox_v6/domain/language_pair/supported_languages.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/features/language_pair/viewmodels/first_run_language_viewmodel.dart';
import 'package:memox_v6/presentation/features/language_pair/widgets/language_select_sheet.dart';
import 'package:memox_v6/presentation/shared/layouts/mx_scaffold.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_action_errors.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_action_runner.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_banner.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_button.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_gap.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_icon.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_tappable.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_text.dart';

/// First-run language selection (WBS 5.1.2): two required selectors,
/// save disabled until both are chosen, failures keep the draft.
class FirstRunLanguageScreen extends StatelessWidget {
  const FirstRunLanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MxScaffold(scrollable: true, body: _FirstRunLanguageBody());
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
      onSuccess: () => context.goHome(),
    );

    final isComplete = draft.learningCode != null && draft.nativeCode != null;
    final isSaving = saveState is AsyncLoading<void>;
    final failure = MxActionErrors.failureOf(saveState);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MxGap.s6(),
        MxText(l10n.firstRunLanguageTitle, role: MxTextRole.headline),
        const MxGap.s2(),
        MxText(l10n.firstRunLanguageSubtitle, role: MxTextRole.body),
        const MxGap.s6(),
        if (failure != null) ...[
          MxBanner(
            tone: MxBannerTone.error,
            title: l10n.saveFailedTitle,
            body: MxActionErrors.messageOf(failure, l10n),
          ),
          const MxGap.s4(),
        ],
        _LanguageSelectorField(
          label: l10n.learningLanguageLabel,
          selectedCode: draft.learningCode,
          onSelected: (code) => ref
              .read(firstRunLanguageDraftViewmodelProvider.notifier)
              .setLearningLanguage(code),
        ),
        const MxGap.s4(),
        _LanguageSelectorField(
          label: l10n.meaningLanguageLabel,
          selectedCode: draft.nativeCode,
          onSelected: (code) => ref
              .read(firstRunLanguageDraftViewmodelProvider.notifier)
              .setMeaningLanguage(code),
        ),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MxText(label, role: MxTextRole.subtitle),
        const MxGap.s2(),
        MxTappable(
          semanticLabel: label,
          onTap: () async {
            final code = await showLanguageSelectSheet(
              context,
              title: label,
              selected: selectedCode,
            );
            if (code != null) onSelected(code);
          },
          child: Row(
            children: [
              const MxGap.s3(),
              const MxIcon(icon: Symbols.language),
              const MxGap.s3(),
              Expanded(
                child: MxText(
                  selected == null
                      ? l10n.selectLanguagePlaceholder
                      : '${selected.nativeName} · ${selected.englishName}',
                  role: MxTextRole.body,
                ),
              ),
              const MxIcon(icon: Symbols.expand_more),
              const MxGap.s3(),
            ],
          ),
        ),
      ],
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
