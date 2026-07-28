import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:memox_v6/app/router/app_navigation.dart';
import 'package:memox_v6/core/theme/extensions/app_theme_context.dart';
import 'package:memox_v6/domain/study_modes/study_mode_type.dart';
import 'package:memox_v6/domain/study_session/session_type.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/features/deck/viewmodels/deck_detail_viewmodel.dart';
import 'package:memox_v6/presentation/features/study/viewmodels/study_start_notifier.dart';
import 'package:memox_v6/presentation/shared/layouts/mx_scaffold.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_action_runner.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_button.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_card.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_contextual_app_bar.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_gap.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_icon.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_icon_tile.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_list.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_snackbar.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_text.dart';

/// The Practice mode picker (WBS 5.6.1; `study-deck.md` §4, §6; kit
/// `ModePicker.jsx`).
///
/// §6: "Mode Picker là selection surface và luôn có CTA `Start session`; chọn
/// một tile không tự start." Selecting a tile only selects it — the explicit
/// CTA is what creates the session. The deck row's bolt starts a session on one
/// tap, which is the behaviour §6 forbids and `int-108` recorded; this screen is
/// where a Practice session is chosen instead.
///
/// Practice only, which is what the kit draws and what §6 permits: the other
/// three session types run fixed plans, so there is nothing to pick for them.
class ModePickerScreen extends HookConsumerWidget {
  const ModePickerScreen({super.key, required this.deckId});

  final String deckId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // guard:allow-screen-watch -- reason: the app bar and the scope card both
    // name the deck this session would run over.
    final l10n = AppLocalizations.of(context);
    final deck = ref.watch(deckDetailProvider(deckId: deckId));
    final selected = useState(StudyModeType.review);
    final isStarting = ref.watch(studyStartProvider) is AsyncLoading<void>;

    listenMxAction(
      ref,
      studyStartProvider,
      onSuccess: () => context.goStudy(),
      // §7's blocked-start lines. The picker has the same problem the deck row
      // had before `int-108`: no inline surface, so a swallowed block reads as
      // a dead button.
      onFailure: (failure) =>
          showMxSnackbar(context, message: l10n.studyStartFailedMessage),
    );

    return MxScaffold(
      appBar: MxContextualAppBar(
        title: l10n.practiceModeTitle,
        onBack: () => Navigator.of(context).maybePop(),
        backLabel: l10n.backLabel,
      ),
      // One rhythm for the whole body, which is what the kit's scaffold gives
      // its children. Hand-placed gaps between the sections drifted every row
      // a little lower than the shot, and the error accumulated downward: by
      // the last mode the offset was most of a row, and the note and CTA below
      // it were displaced entirely (`int-110`).
      body: MxList(
        children: [
          _ScopeCard(deckName: deck.value?.name ?? ''),
          for (final mode in _practiceModes)
            _ModeOption(
              mode: mode,
              selected: selected.value == mode,
              onSelect: isStarting ? null : () => selected.value = mode,
            ),
          // §6 is why this line is true: "Practice outcome vẫn có thể ghi
          // history nhưng không mutate SRS/Goal/Streak trong v1."
          Center(
            child: MxText(
              l10n.practiceNoSrsNote,
              role: MxTextRole.caption,
              color: context.colors.textTertiary,
            ),
          ),
          MxButton(
            label: isStarting
                ? l10n.studyStartingLabel
                : l10n.startSessionLabel,
            block: true,
            size: MxButtonSize.lg,
            onPressed: isStarting
                ? null
                : () => ref
                      .read(studyStartProvider.notifier)
                      .start(
                        deckId: deckId,
                        type: SessionType.practice,
                        selectedMode: selected.value,
                      ),
          ),
        ],
      ),
    );
  }
}

/// The five modes Practice offers (kit `MODES`).
///
/// Not `StudyModeType.values`: `srsBinaryReview` is the plan the SRS session
/// types run, not a practice choice, and §6 is explicit that the "Practice Mode
/// Picker chỉ hiển thị/enable modes product hỗ trợ".
const List<StudyModeType> _practiceModes = <StudyModeType>[
  StudyModeType.review,
  StudyModeType.match,
  StudyModeType.guess,
  StudyModeType.recall,
  StudyModeType.fill,
];

/// The kit's `ScopeCard`, minus its chevron.
///
/// The kit draws it as a control that opens the `scope-dropdown` state, and
/// that sheet is not built — §5's Parent choice between the whole subtree and
/// an eligible child subtree has nowhere to happen yet. Drawing the chevron
/// without the sheet would promise a control that does nothing, so the card
/// states the scope it is actually going to use and nothing more.
class _ScopeCard extends StatelessWidget {
  const _ScopeCard({required this.deckName});

  final String deckName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return MxCard(
      padding: MxCardPadding.sm,
      child: Row(
        children: [
          const MxIconTile(icon: Symbols.tune, tone: MxIconTileTone.success),
          const MxGap.s4(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MxText(l10n.cardSourceLabel, role: MxTextRole.subtitle),
                const MxGap.s1(),
                MxText(deckName, role: MxTextRole.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One mode choice (kit `ModeOption.jsx`): tile, name, description, and the
/// radio that says selecting is not starting.
class _ModeOption extends StatelessWidget {
  const _ModeOption({
    required this.mode,
    required this.selected,
    required this.onSelect,
  });

  final StudyModeType mode;
  final bool selected;
  final VoidCallback? onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (icon, name, description) = switch (mode) {
      StudyModeType.review => (
        Symbols.style,
        l10n.modeReviewName,
        l10n.modeReviewDescription,
      ),
      StudyModeType.match => (
        Symbols.join_inner,
        l10n.modeMatchName,
        l10n.modeMatchDescription,
      ),
      StudyModeType.guess => (
        Symbols.quiz,
        l10n.modeGuessName,
        l10n.modeGuessDescription,
      ),
      StudyModeType.recall => (
        Symbols.psychology,
        l10n.modeRecallName,
        l10n.modeRecallDescription,
      ),
      StudyModeType.fill => (
        Symbols.keyboard,
        l10n.modeFillName,
        l10n.modeFillDescription,
      ),
      // Unreachable: the list above is the five practice modes.
      StudyModeType.srsBinaryReview => (
        Symbols.style,
        l10n.modeReviewName,
        l10n.modeReviewDescription,
      ),
    };

    return MxCard(
      padding: MxCardPadding.sm,
      variant: selected ? MxCardVariant.primarySoft : MxCardVariant.elevated,
      onTap: onSelect,
      semanticLabel: l10n.selectModeSemantics(name),
      child: Row(
        children: [
          MxIconTile(icon: icon, tone: MxIconTileTone.accent),
          const MxGap.s4(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MxText(name, role: MxTextRole.subtitle),
                const MxGap.s1(),
                MxText(description, role: MxTextRole.caption),
              ],
            ),
          ),
          MxIcon(
            icon: selected
                ? Symbols.radio_button_checked
                : Symbols.radio_button_unchecked,
            color: selected
                ? context.colors.primary
                : context.colors.textTertiary,
          ),
        ],
      ),
    );
  }
}
