import 'package:memox_v6/app/di/usecase_providers.dart';
import 'package:memox_v6/domain/flashcard/card_detail.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'card_detail_viewmodel.g.dart';

/// The Card Detail read projection (WBS 6.x; `view-card-detail.md`).
///
/// A one-shot read: "Loaded: render the latest committed projection; no draft
/// state is created." Returning from a command invalidates it, which is the
/// spec's "Returning from a successful command refreshes the projection".
@riverpod
Future<CardDetail?> cardDetail(Ref ref, {required String cardId}) {
  return ref.watch(viewCardDetailUseCaseProvider).call(cardId);
}
