# Metric formulas v1 — `metrics-v1`

## Qualified activity

- `qualifyingSession`: finalized `newLearning`, `dueReview` hoặc `relearn` session. Practice is recorded separately and does not contribute Goal/Streak in v1.
- `qualifiedCard`: distinct Card with a committed terminal outcome or Box-0 activation in one qualifying session. Mastery retries do not increase this count.
- `localDayId`: date derived once from event UTC instant using the effective IANA timezone snapshot; format `YYYY-MM-DD`.

## Goal and streak

- Daily Goal unit v1 is qualified Cards. `goalProgress = count(distinct sessionId, cardId)` for qualifying sessions in the local day.
- Goal met when enabled and `goalProgress >= target`; transition emits once per `(goalVersion, localDayId)`.
- A streak day qualifies when at least one qualifying session finalizes with at least one qualified Card. Multiple sessions that day remain one day record.
- `currentStreak` is consecutive qualified local-day ids ending today, or ending yesterday when today has no qualifying event yet. A gap before yesterday yields zero.
- `longestStreak` is the maximum consecutive run over deduplicated qualified day ids.

## Statistics

- `sessionCount`: count distinct finalized session ids; report Practice separately.
- `qualifiedCardCount`: sum qualified Cards per session.
- `terminalAccuracy = terminalCorrect / (terminalCorrect + terminalWrong)`. Exclude reviewed-only, invalid, skipped/missing and Box-0 activation without binary grade. If denominator is zero, state is `insufficient`, not 0%.
- `activeStudyDurationMs`: sum validated foreground-active intervals, excluding background, interruption, loading and clock-negative/overlapping duplicate intervals.
- Percentages round half-up to one decimal for stored/display-neutral projection; locale controls presentation only.

Late sync/restore rebuilds buckets from source events using event timezone snapshot and formula id; it does not rebucket history using current timezone.

## Acceptance criteria

- Golden tests cover same-day retries, midnight/DST, timezone change, late events, Practice exclusion, sticky-wrong and zero denominator.
- Incremental and full rebuild produce identical projection hashes for same source watermark.
- Goal, Streak, Today and Statistics reference `metrics-v1`; no surface reimplements formulas.
