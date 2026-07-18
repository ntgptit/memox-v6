# ADR-002 — Flutter platform and adaptive scope

- Status: **Accepted**
- Owner: Product / Architecture
- Accepted: 2026-07-18
- Decision gates: DG-02, DG-05

## Decision

MemoX v6 is a Flutter application. Release Tier 1 is:

- Android.
- Web.
- English and Vietnamese UI.

iOS, Windows, macOS, and Linux remain roadmap targets and must not be presented
as release-certified until their platform gates pass. RTL is not a v1 locale,
but layout, semantics, directional icons, and APIs remain RTL-ready.

The design kit's 390×780 light/dark frame remains the canonical compact visual
parity baseline. Production layouts branch on available width and input
capability, not platform labels. Web additionally requires keyboard, mouse,
resize, focus, URL/deep-link, and browser lifecycle acceptance.

## Consequences

- Platform capability matrices distinguish Tier 1, roadmap, and unsupported.
- No feature may claim parity on a roadmap platform based only on compilation.
- Flutter mappings preserve frozen token, `Mx*`, and semantic node names.

## Verification

Tier-1 smoke tests cover launch, local database, resize, keyboard/focus, file and
audio/notification capability fallbacks, offline restart, and the first-learning
journey. Locale tests cover en/vi plus expansion and CJK card content.
