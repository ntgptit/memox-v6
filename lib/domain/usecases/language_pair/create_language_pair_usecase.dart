import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/core/ids/id_generator.dart';
import 'package:memox_v6/core/time/app_clock.dart';
import 'package:memox_v6/core/utils/string_utils.dart';
import 'package:memox_v6/domain/language_pair/create_language_pair_result.dart';
import 'package:memox_v6/domain/language_pair/language_pair.dart';
import 'package:memox_v6/domain/language_pair/language_pair_key.dart';
import 'package:memox_v6/domain/language_pair/language_pair_repository.dart';
import 'package:memox_v6/domain/language_pair/supported_languages.dart';

/// Creates a language pair with normalized identity (WBS 5.1.1).
///
/// Validation is fail-fast and typed: both selections required,
/// supported, distinct. Identity is stable (injected id/clock); a
/// concurrent duplicate resolves idempotently to [LanguagePairAlreadyExists].
class CreateLanguagePairUseCase {
  const CreateLanguagePairUseCase({
    required LanguagePairRepository repository,
    required IdGenerator idGenerator,
    required AppClock clock,
  }) : _repository = repository,
       _idGenerator = idGenerator,
       _clock = clock;

  final LanguagePairRepository _repository;
  final IdGenerator _idGenerator;
  final AppClock _clock;

  Future<CreateLanguagePairResult> call({
    required String learningLanguageCode,
    required String nativeLanguageCode,
  }) async {
    final learning = _normalizedCode(
      learningLanguageCode,
      field: 'learningLanguageCode',
    );
    final native = _normalizedCode(
      nativeLanguageCode,
      field: 'nativeLanguageCode',
    );
    if (learning == native) {
      throw ValidationFailure(
        field: 'nativeLanguageCode',
        code: 'not-distinct',
      );
    }

    final key = buildNormalizedPairKey(
      learningLanguageCode: learning,
      nativeLanguageCode: native,
    );
    final existing = await _repository.findByNormalizedKey(key);
    if (existing != null) return LanguagePairAlreadyExists(existing);

    final now = _clock.nowUtc();
    final pair = LanguagePair(
      id: _idGenerator.newId(),
      learningLanguageCode: learning,
      nativeLanguageCode: native,
      normalizedPairKey: key,
      createdAt: now,
      updatedAt: now,
    );
    try {
      await _repository.createPair(pair);
    } on ConflictFailure catch (failure) {
      if (failure.code != 'duplicate') rethrow;
      // Lost a race with an identical create: resolve idempotently.
      final winner = await _repository.findByNormalizedKey(key);
      if (winner != null) return LanguagePairAlreadyExists(winner);
      rethrow;
    }
    return LanguagePairCreated(pair);
  }

  String _normalizedCode(String raw, {required String field}) {
    final code = StringUtils.lowerCased(StringUtils.trimmed(raw));
    if (code.isEmpty) {
      throw ValidationFailure(field: field, code: 'required');
    }
    if (!isSupportedLanguageCode(code)) {
      throw ValidationFailure(field: field, code: 'unsupported');
    }
    return code;
  }
}
