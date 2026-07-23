import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:memox_v6/domain/study_modes/mode_preferences.dart';
import 'package:memox_v6/domain/study_modes/study_mode_type.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/features/settings/viewmodels/mode_preferences_viewmodel.dart';
import 'package:memox_v6/presentation/shared/bottom_sheets/mx_sheet.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_action_errors.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_action_runner.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_async_builder.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_button.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_gap.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_icon.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_tappable.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_text.dart';

/// Practice mode preferences (WBS 8.3; `configure-mode-preferences.md`): enable
/// the modes the Practice picker offers and pick the default. Save is blocked
/// until at least one mode is enabled and the default is among them (§2). The
/// canonical order is kept here; accessible reorder is a follow-up.
Future<void> showModePreferencesSheet(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return showMxSheet<void>(
    context,
    title: l10n.studyModesLabel,
    child: const _ModePreferencesBody(),
  );
}

class _ModePreferencesBody extends ConsumerWidget {
  const _ModePreferencesBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final prefs = ref.watch(modePreferencesProvider);

    return MxAsyncBuilder<ModePreferences>(
      value: prefs,
      loadingLabel: l10n.loadingLabel,
      errorTitle: l10n.somethingWentWrongMessage,
      data: (context, value) => _ModePreferencesForm(initial: value),
    );
  }
}

String _titleOf(StudyModeType mode, AppLocalizations l10n) {
  return switch (mode) {
    StudyModeType.review => l10n.reviewModeTitle,
    StudyModeType.match => l10n.matchModeTitle,
    StudyModeType.guess => l10n.guessModeTitle,
    StudyModeType.recall => l10n.recallModeTitle,
    StudyModeType.fill => l10n.fillModeTitle,
    StudyModeType.srsBinaryReview => mode.id,
  };
}

class _ModePreferencesForm extends HookConsumerWidget {
  const _ModePreferencesForm({required this.initial});

  final ModePreferences initial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    const policy = ModePreferencesPolicy();
    final modes = policy.selectableModes;

    final enabled = useState<Set<StudyModeType>>(
      initial.enabledInOrder.toSet(),
    );
    final defaultMode = useState<StudyModeType>(initial.defaultMode);

    final saveState = ref.watch(modePreferencesCommandViewmodelProvider);
    final isSaving = saveState is AsyncLoading<void>;
    final failure = MxActionErrors.failureOf(saveState);

    listenMxAction(
      ref,
      modePreferencesCommandViewmodelProvider,
      onSuccess: () => Navigator.of(context).pop(),
    );

    final valid =
        enabled.value.isNotEmpty && enabled.value.contains(defaultMode.value);

    void toggle(StudyModeType mode) {
      final next = {...enabled.value};
      // Set.add returns false when the mode was already enabled, so a failed
      // add means "was on -> turn off" — a branchless toggle (no else).
      if (!next.add(mode)) next.remove(mode);
      enabled.value = next;
    }

    void save() {
      final ordered = modes
          .where((mode) => enabled.value.contains(mode))
          .toList();
      ref
          .read(modePreferencesCommandViewmodelProvider.notifier)
          .setModePreferences(
            ModePreferences(
              enabledInOrder: ordered,
              defaultMode: defaultMode.value,
            ),
          );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final mode in modes)
          _ModeRow(
            key: ValueKey('mode-${mode.id}'),
            title: _titleOf(mode, l10n),
            enabled: enabled.value.contains(mode),
            isDefault: defaultMode.value == mode,
            onToggle: isSaving ? null : () => toggle(mode),
            onMakeDefault: isSaving || !enabled.value.contains(mode)
                ? null
                : () => defaultMode.value = mode,
            makeDefaultLabel: l10n.makeDefaultLabel,
            defaultBadge: l10n.modeDefaultLabel,
          ),
        if (!valid) ...[
          const MxGap.s3(),
          MxText(l10n.modePreferencesInvalidHint, role: MxTextRole.caption),
        ],
        if (failure != null) ...[
          const MxGap.s3(),
          MxText(
            MxActionErrors.messageOf(failure, l10n),
            role: MxTextRole.caption,
          ),
        ],
        const MxGap.s5(),
        MxButton(
          label: isSaving ? l10n.savingLabel : l10n.saveLabel,
          block: true,
          onPressed: valid && !isSaving ? save : null,
        ),
      ],
    );
  }
}

class _ModeRow extends StatelessWidget {
  const _ModeRow({
    super.key,
    required this.title,
    required this.enabled,
    required this.isDefault,
    required this.onToggle,
    required this.onMakeDefault,
    required this.makeDefaultLabel,
    required this.defaultBadge,
  });

  final String title;
  final bool enabled;
  final bool isDefault;
  final VoidCallback? onToggle;
  final VoidCallback? onMakeDefault;
  final String makeDefaultLabel;
  final String defaultBadge;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const MxGap.s3(),
        MxTappable(
          semanticLabel: title,
          onTap: onToggle,
          child: MxIcon(
            icon: enabled
                ? Symbols.check_box_rounded
                : Symbols.check_box_outline_blank_rounded,
          ),
        ),
        const MxGap.s3(),
        Expanded(child: MxText(title, role: MxTextRole.body)),
        if (isDefault) ...[
          MxText(defaultBadge, role: MxTextRole.caption),
          const MxGap.s3(),
        ],
        MxTappable(
          semanticLabel: makeDefaultLabel,
          onTap: onMakeDefault,
          child: MxIcon(
            icon: isDefault
                ? Symbols.radio_button_checked_rounded
                : Symbols.radio_button_unchecked_rounded,
          ),
        ),
        const MxGap.s3(),
      ],
    );
  }
}
