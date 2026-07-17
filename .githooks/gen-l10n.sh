#!/usr/bin/env bash
#
# Shared helper: regenerate Flutter localizations from the ARB files.
# Sourced by the post-merge and post-checkout hooks. Non-fatal by design —
# it must never block a git operation.
#
regen_l10n() {
  # Only act on Flutter projects that use gen-l10n.
  [ -f l10n.yaml ] || return 0

  if ! command -v flutter >/dev/null 2>&1; then
    echo "gen-l10n: flutter not on PATH, skipping localization regen." >&2
    return 0
  fi

  echo "gen-l10n: regenerating localizations from ARB files..."
  if ! flutter gen-l10n >/dev/null 2>&1; then
    echo "gen-l10n: generation failed — check your .arb files (run 'flutter gen-l10n')." >&2
  fi
  return 0
}
