import 'package:memox_v6/core/ids/id_generator.dart';
import 'package:memox_v6/domain/study_modes/round_order_policy.dart';
import 'package:memox_v6/domain/study_modes/study_mode_type.dart';
import 'package:memox_v6/domain/study_session/session_card_snapshot.dart';
import 'package:memox_v6/domain/study_session/session_mode_plan.dart';
import 'package:memox_v6/domain/study_session/session_round_order.dart';
import 'package:memox_v6/domain/study_session/session_scope.dart';
import 'package:memox_v6/domain/study_session/session_state.dart';
import 'package:memox_v6/domain/study_session/session_type.dart';
import 'package:memox_v6/domain/study_session/study_session.dart';

/// One eligible card the snapshot pins, already resolved to its content and
/// progress (the caller gathered it from the card + progress repositories).
class EligibleCard {
  const EligibleCard({
    required this.cardId,
    required this.term,
    required this.meaning,
    required this.contentVersion,
    required this.progressBox,
    required this.progressRevision,
  });

  final String cardId;
  final String term;
  final String meaning;
  final int contentVersion;
  final int progressBox;
  final int progressRevision;
}

/// The immutable triple the atomic `startSession` op (4.6C) persists together.
class StartSessionSnapshot {
  const StartSessionSnapshot({
    required this.session,
    required this.cardSnapshots,
    required this.initialOrder,
  });

  final StudySession session;
  final List<SessionCardSnapshot> cardSnapshots;
  final SessionRoundOrder initialOrder;
}

/// Assembles a start-session snapshot (WBS 5.6.2 domain part;
/// `start-study-session.md` §7). Pure and deterministic: it resolves the mode
/// plan, fixes the base card snapshots and builds the first stage's
/// deterministic round order — it persists nothing (the caller hands the result
/// to the atomic `startSession`, which enforces exactly-one-active).
///
/// The base [SessionCardSnapshot.displayOrder] keeps the caller's stable order;
/// the shuffled presentation order lives only in the [SessionRoundOrder], so a
/// reshuffle never disturbs the pinned snapshot. [initialRoundIndex] is the
/// caller's runtime convention (Review browses at its own index; a graded first
/// stage starts its mastery round) — this builder does not invent it.
class SessionSnapshotBuilder {
  const SessionSnapshotBuilder({
    required IdGenerator idGenerator,
    SessionModePlanResolver planResolver = const SessionModePlanResolver(),
    RoundOrderPolicy orderPolicy = const RoundOrderPolicy(),
  }) : _ids = idGenerator,
       _planResolver = planResolver,
       _orderPolicy = orderPolicy;

  final IdGenerator _ids;
  final SessionModePlanResolver _planResolver;
  final RoundOrderPolicy _orderPolicy;

  StartSessionSnapshot build({
    required String sessionId,
    required String deckId,
    required SessionScope scope,
    required SessionType type,
    required List<EligibleCard> eligibleCards,
    required int initialRoundIndex,
    required DateTime nowUtc,
    StudyModeType? selectedMode,
    bool guessPoolSufficient = false,
  }) {
    final ids = _ids;
    final plan = _planResolver.resolve(
      type: type,
      selectedMode: selectedMode,
      guessPoolSufficient: guessPoolSufficient,
    );

    // The base snapshot keeps the caller's stable order.
    final cardSnapshots = <SessionCardSnapshot>[];
    for (var index = 0; index < eligibleCards.length; index++) {
      final card = eligibleCards[index];
      cardSnapshots.add(
        SessionCardSnapshot(
          id: ids.newId(),
          sessionId: sessionId,
          cardId: card.cardId,
          displayOrder: index,
          term: card.term,
          meaning: card.meaning,
          contentVersion: card.contentVersion,
          progressBox: card.progressBox,
          progressRevision: card.progressRevision,
        ),
      );
    }

    // The first stage's deterministic presentation order (no previous sequence).
    final firstStage = plan.stages.first;
    final cardIds = eligibleCards.map((card) => card.cardId).toList();
    final orderedIds = _orderPolicy.order(
      sessionId: sessionId,
      modeId: firstStage.id,
      roundIndex: initialRoundIndex,
      cardIds: cardIds,
    );
    final initialOrder = SessionRoundOrder(
      id: ids.newId(),
      sessionId: sessionId,
      roundIndex: initialRoundIndex,
      seed: roundOrderSeed(
        sessionId: sessionId,
        modeId: firstStage.id,
        roundIndex: initialRoundIndex,
      ),
      cardIds: orderedIds,
    );

    final session = StudySession(
      id: sessionId,
      type: type,
      deckId: deckId,
      scope: scope,
      state: SessionState.active,
      revision: 0,
      snapshotVersion: 1,
      scheduleSrs: plan.scheduleSrs,
      startedAt: nowUtc,
      finalizedAt: null,
      createdAt: nowUtc,
      updatedAt: nowUtc,
    );

    return StartSessionSnapshot(
      session: session,
      cardSnapshots: cardSnapshots,
      initialOrder: initialOrder,
    );
  }
}
