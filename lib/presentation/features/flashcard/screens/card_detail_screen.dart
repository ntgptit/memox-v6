import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:memox_v6/app/router/app_navigation.dart';
import 'package:memox_v6/core/theme/extensions/app_theme_context.dart';
import 'package:memox_v6/domain/flashcard/card_detail.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/features/flashcard/viewmodels/card_detail_viewmodel.dart';
import 'package:memox_v6/presentation/features/flashcard/widgets/card_settings_sheet.dart';
import 'package:memox_v6/presentation/features/flashcard/widgets/move_card_sheet.dart';
import 'package:memox_v6/presentation/shared/layouts/mx_scaffold.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_async_builder.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_button.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_chip.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_contextual_app_bar.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_empty_state.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_gap.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_icon_button.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_icon_tile.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_text.dart';

/// Card Detail (WBS 6.x; `view-card-detail.md`).
///
/// A read projection over one Card: its text, additional translations, tags,
/// deck and a read-only Progress summary. It owns no rules — every action
/// routes to the flow that does, through the same settings sheet the Leaf list
/// opens.
///
/// It did not exist. Several flows name it as an entry point —
/// `hide-flashcard.md` §2 ("Card action sheet/detail"), `move-flashcard.md` §2
/// ("Card detail → Move") — and `open-search-result.md` §3 sends a valid card
/// result to the "Card/detail contract", which is why search opened the
/// *editor* instead: there was nowhere else to go (`int-100`).
class CardDetailScreen extends ConsumerWidget {
  const CardDetailScreen({
    super.key,
    required this.deckId,
    required this.cardId,
  });

  final String deckId;
  final String cardId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // guard:allow-screen-watch -- reason: the app bar's only action belongs to
    // the loaded card, and a not-found projection must not offer it.
    final l10n = AppLocalizations.of(context);
    final detail = ref.watch(cardDetailProvider(cardId: cardId));

    return MxScaffold(
      appBar: MxContextualAppBar(
        title: l10n.cardDetailTitle,
        onBack: () => Navigator.of(context).maybePop(),
        backLabel: l10n.backLabel,
        actions: [
          // The card's own flows live behind one action, which is what "route
          // to the owning Flashcard flows" means: this screen never edits.
          if (detail.asData?.value case final loaded?)
            MxIconButton(
              icon: Symbols.more_vert_rounded,
              semanticLabel: l10n.cardSettingsLabel,
              onPressed: () => _openSettings(context, ref, detail: loaded),
            ),
        ],
      ),
      scrollable: false,
      body: MxAsyncBuilder<CardDetail?>(
        value: detail,
        loadingLabel: l10n.loadingLabel,
        errorTitle: l10n.somethingWentWrongMessage,
        onRetry: () => ref.invalidate(cardDetailProvider(cardId: cardId)),
        retryLabel: l10n.tryAgainLabel,
        data: (context, value) {
          // "Not found/deleted: explain that the Card is unavailable and offer
          // safe return to its prior list/Deck." The return is the deck it
          // belonged to, which is where the learner came from and the one
          // place still guaranteed to exist.
          if (value == null) {
            return MxEmptyState(
              icon: Symbols.hide_source_rounded,
              tone: MxIconTileTone.warning,
              title: l10n.cardNotFoundTitle,
              body: l10n.cardNotFoundMessage,
              reserveNavZone: false,
              action: MxButton(
                onPressed: () => context.goDeckDetail(deckId),
                label: l10n.backToDeckLabel,
                variant: MxButtonVariant.secondary,
                block: true,
              ),
            );
          }
          return _Body(detail: value);
        },
      ),
    );
  }

  Future<void> _openSettings(
    BuildContext context,
    WidgetRef ref, {
    required CardDetail detail,
  }) async {
    final action = await showCardSettingsSheet(
      context,
      isHidden: detail.card.isHidden,
    );
    if (!context.mounted || action == null) return;
    // The owning flows are reached the same way the Leaf list reaches them;
    // this screen only decides where to send the learner, then re-reads.
    switch (action) {
      case CardSettingsAction.edit:
        await context.pushEditCard(deckId, cardId);
      case CardSettingsAction.move:
        await showMoveCardSheet(context, cardId: cardId);
      case CardSettingsAction.toggleHidden:
      case CardSettingsAction.delete:
        // Both belong to flows the Leaf list owns end to end, including their
        // confirms and their outcome reporting. Sending the learner back there
        // beats a second, thinner copy of the same decision on this screen.
        if (!context.mounted) return;
        context.goDeckDetail(deckId);
        return;
    }
    if (!context.mounted) return;
    ref.invalidate(cardDetailProvider(cardId: cardId));
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.detail});

  final CardDetail detail;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final card = detail.card;
    final deckName = detail.deckName;

    // The scaffold does not scroll this screen: its not-found state is an
    // `MxEmptyState`, which centres itself in the height it is given and
    // cannot be given an unbounded one. So the loaded body scrolls itself.
    return ListView(
      children: [
        const MxGap.s4(),
        if (deckName != null) ...[
          MxText(deckName, role: MxTextRole.caption),
          const MxGap.s2(),
        ],
        MxText(card.term, role: MxTextRole.title),
        const MxGap.s2(),
        MxText(card.primaryMeaning, role: MxTextRole.body),
        // `hide-flashcard.md` §4 again: the state is said, not only shown.
        if (card.isHidden) ...[
          const MxGap.s3(),
          MxText(
            l10n.cardHiddenBadge,
            role: MxTextRole.caption,
            color: context.colors.textSecondary,
          ),
        ],
        if (detail.translations.isNotEmpty) ...[
          const MxGap.s6(),
          MxText(l10n.additionalTranslationsLabel, role: MxTextRole.overline),
          const MxGap.s2(),
          for (final translation in detail.translations) ...[
            MxText(translation.text, role: MxTextRole.body),
            const MxGap.s1(),
          ],
        ],
        if (detail.tags.isNotEmpty) ...[
          const MxGap.s6(),
          MxText(l10n.tagsLabel, role: MxTextRole.overline),
          const MxGap.s2(),
          Wrap(
            spacing: MxGap.s2Value,
            runSpacing: MxGap.s2Value,
            children: [
              for (final tag in detail.tags) MxChip(label: tag.name),
            ],
          ),
        ],
        const MxGap.s6(),
        MxText(l10n.progressLabel, role: MxTextRole.overline),
        const MxGap.s2(),
        // Read-only, and deliberately shallow: the projection reports Box and
        // due status, and reset routes to Learning Progress rather than
        // happening here.
        MxText(_progressSummary(context, l10n), role: MxTextRole.body),
        const MxGap.s8(),
      ],
    );
  }

  String _progressSummary(BuildContext context, AppLocalizations l10n) {
    final progress = detail.progress;
    if (progress == null) return l10n.cardProgressNoneMessage;
    final dueAt = progress.dueAt;
    if (dueAt == null) return l10n.cardProgressBoxMessage(progress.box);
    // The card's schedule is a local-day fact everywhere else in the app, so
    // it reads in local time here too.
    return l10n.cardProgressBoxDueMessage(
      progress.box,
      MaterialLocalizations.of(context).formatMediumDate(dueAt.toLocal()),
    );
  }
}
