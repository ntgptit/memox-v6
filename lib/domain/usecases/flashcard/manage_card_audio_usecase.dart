import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/core/utils/string_utils.dart';
import 'package:memox_v6/domain/flashcard/card_audio_ref.dart';
import 'package:memox_v6/domain/flashcard/flashcard_repository.dart';

/// Card audio-reference management (WBS 5.3.1B;
/// `manage-card-audio.md`): asset/provider metadata only — player
/// state belongs to Audio Playback. Mutations commit with the Card
/// content-version bump.
class ManageCardAudioUseCase {
  const ManageCardAudioUseCase({required FlashcardRepository cards})
    : _cards = cards;

  final FlashcardRepository _cards;

  Future<List<CardAudioRef>> audioRefsOf(String cardId) {
    return _cards.audioRefsOf(cardId);
  }

  Future<CardAudioRef> addAudioRef({
    required String refId,
    required String cardId,
    required String languageCode,
    required String assetId,
    required String provider,
    required DateTime now,
  }) async {
    final ref = CardAudioRef(
      id: refId,
      cardId: cardId,
      languageCode: _required(languageCode, field: 'languageCode'),
      assetId: _required(assetId, field: 'assetId'),
      provider: _required(provider, field: 'provider'),
    );
    await _cards.addCardAudioRef(ref, now: now);
    return ref;
  }

  Future<void> removeAudioRef({
    required String refId,
    required String cardId,
    required DateTime now,
  }) {
    return _cards.removeCardAudioRef(refId, cardId: cardId, now: now);
  }

  String _required(String raw, {required String field}) {
    final trimmed = StringUtils.trimmed(raw);
    if (trimmed.isEmpty) {
      throw ValidationFailure(field: field, code: 'required');
    }
    return trimmed;
  }
}
