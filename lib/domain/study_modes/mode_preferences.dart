import 'package:memox_v6/domain/study_modes/study_mode_type.dart';

/// A user's Practice mode configuration: the enabled modes in their chosen
/// order and the default mode (WBS 8.3; `configure-mode-preferences.md`). Only
/// governs the Practice picker — newLearning's required five-stage plan is fixed
/// and never affected (ST-TYPE-002).
class ModePreferences {
  const ModePreferences({
    required this.enabledInOrder,
    required this.defaultMode,
  });

  final List<StudyModeType> enabledInOrder;
  final StudyModeType defaultMode;
}

/// Why a mode configuration is invalid (`configure-mode-preferences.md` §§1,4).
enum ModePreferencesError {
  /// No mode is enabled — a session needs at least one.
  noneEnabled,

  /// The default mode is not in the enabled set.
  defaultNotEnabled,

  /// A non-Practice-selectable mode (the session-only srsBinaryReview) was
  /// included.
  nonSelectableMode,

  /// The same mode appears twice in the order.
  duplicateMode,
}

/// Pure validation and compatibility-normalization for Practice mode
/// preferences (WBS 8.3 constraint part; `configure-mode-preferences.md`). It
/// enforces the config invariants and never invents the user's default or
/// order; it persists nothing.
class ModePreferencesPolicy {
  const ModePreferencesPolicy();

  /// Whether a mode can be chosen in the Practice picker. Every mode except the
  /// session-only [StudyModeType.srsBinaryReview] is selectable
  /// (`srs-binary-review.md`: it never appears in the Practice picker).
  bool isSelectable(StudyModeType mode) =>
      mode != StudyModeType.srsBinaryReview;

  /// The valid, ordered set of Practice-selectable modes.
  List<StudyModeType> get selectableModes =>
      StudyModeType.values.where(isSelectable).toList();

  /// Validate a configuration; `null` means valid. At least one mode must be
  /// enabled, the default must be within the enabled set, only selectable modes
  /// may appear and no mode may repeat (§§1,4).
  ModePreferencesError? validate(ModePreferences preferences) {
    final enabled = preferences.enabledInOrder;
    if (enabled.isEmpty) return ModePreferencesError.noneEnabled;
    if (enabled.toSet().length != enabled.length) {
      return ModePreferencesError.duplicateMode;
    }
    if (enabled.any((mode) => !isSelectable(mode))) {
      return ModePreferencesError.nonSelectableMode;
    }
    if (!enabled.contains(preferences.defaultMode)) {
      return ModePreferencesError.defaultNotEnabled;
    }
    return null;
  }

  /// Drop unknown, non-selectable and duplicate ids from a persisted order,
  /// preserving order — the compatibility fallback for a config written by an
  /// older or newer build (§§1,4 "unknown mode id bị bỏ qua/fallback an toàn").
  List<StudyModeType> normalizeEnabled(List<String> persistedIds) {
    final result = <StudyModeType>[];
    for (final id in persistedIds) {
      final mode = StudyModeType.tryFromId(id);
      if (mode == null || !isSelectable(mode) || result.contains(mode)) {
        continue;
      }
      result.add(mode);
    }
    return result;
  }
}
