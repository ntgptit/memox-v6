import 'package:memox_v6/domain/language_pair/language_pair.dart';

/// Outcome of a create attempt (WBS 5.1.1): a duplicate is never
/// created silently — the existing pair comes back for the flow's
/// "use existing" decision (`create-language-pair.md`).
sealed class CreateLanguagePairResult {
  const CreateLanguagePairResult(this.pair);

  final LanguagePair pair;
}

final class LanguagePairCreated extends CreateLanguagePairResult {
  const LanguagePairCreated(super.pair);
}

final class LanguagePairAlreadyExists extends CreateLanguagePairResult {
  const LanguagePairAlreadyExists(super.pair);
}
