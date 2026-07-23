/// The app-wide appearance preference (WBS 8.1; `set-appearance-preference.md`).
///
/// Only these supported modes persist; a missing or undecodable stored value
/// falls back to [system] (§1 invalid-fallback), so corruption never crashes
/// or strands the theme.
enum AppearanceMode {
  system('system'),
  light('light'),
  dark('dark');

  const AppearanceMode(this.storageValue);

  /// The stable string persisted in the preference store.
  final String storageValue;

  /// Decodes a stored payload, falling back to [system] for any value outside
  /// the supported set (including null).
  static AppearanceMode fromStorage(Object? value) {
    for (final mode in AppearanceMode.values) {
      if (mode.storageValue == value) return mode;
    }
    return AppearanceMode.system;
  }
}
