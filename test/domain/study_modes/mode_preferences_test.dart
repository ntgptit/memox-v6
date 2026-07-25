import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/domain/study_modes/mode_preferences.dart';
import 'package:memox_v6/domain/study_modes/study_mode_type.dart';

/// WBS 8.3 (constraint part) — Practice mode-preference invariants
/// (`configure-mode-preferences.md` §§1,4).
void main() {
  const policy = ModePreferencesPolicy();

  test('the session-only srsBinaryReview is not Practice-selectable', () {
    expect(policy.isSelectable(StudyModeType.srsBinaryReview), isFalse);
    expect(policy.isSelectable(StudyModeType.guess), isTrue);
    expect(policy.selectableModes, <StudyModeType>[
      StudyModeType.review,
      StudyModeType.match,
      StudyModeType.guess,
      StudyModeType.recall,
      StudyModeType.fill,
    ]);
  });

  test('a well-formed configuration validates', () {
    final error = policy.validate(
      const ModePreferences(
        enabledInOrder: <StudyModeType>[
          StudyModeType.guess,
          StudyModeType.fill,
        ],
        defaultMode: StudyModeType.guess,
      ),
    );
    expect(error, isNull);
  });

  test('no enabled mode is rejected', () {
    expect(
      policy.validate(
        const ModePreferences(
          enabledInOrder: <StudyModeType>[],
          defaultMode: StudyModeType.guess,
        ),
      ),
      ModePreferencesError.noneEnabled,
    );
  });

  test('a default outside the enabled set is rejected', () {
    expect(
      policy.validate(
        const ModePreferences(
          enabledInOrder: <StudyModeType>[StudyModeType.guess],
          defaultMode: StudyModeType.fill,
        ),
      ),
      ModePreferencesError.defaultNotEnabled,
    );
  });

  test('a non-selectable mode in the set is rejected', () {
    expect(
      policy.validate(
        const ModePreferences(
          enabledInOrder: <StudyModeType>[StudyModeType.srsBinaryReview],
          defaultMode: StudyModeType.srsBinaryReview,
        ),
      ),
      ModePreferencesError.nonSelectableMode,
    );
  });

  test('a duplicate mode in the order is rejected', () {
    expect(
      policy.validate(
        const ModePreferences(
          enabledInOrder: <StudyModeType>[
            StudyModeType.guess,
            StudyModeType.guess,
          ],
          defaultMode: StudyModeType.guess,
        ),
      ),
      ModePreferencesError.duplicateMode,
    );
  });

  group('normalizeEnabled (compatibility fallback)', () {
    test('drops unknown, non-selectable and duplicate ids, keeps order', () {
      final normalized = policy.normalizeEnabled(<String>[
        'fill',
        'wizard', // unknown
        'srsBinaryReview', // non-selectable
        'guess',
        'fill', // duplicate
      ]);
      expect(normalized, <StudyModeType>[
        StudyModeType.fill,
        StudyModeType.guess,
      ]);
    });
  });
}
