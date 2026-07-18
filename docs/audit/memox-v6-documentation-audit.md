# MemoX v6 — Comprehensive Documentation Audit

**Type:** Documentation & contract audit (read-only). No source or original docs were modified.
**Repository:** `memox-v6` · branch `claude/memox-v6-doc-audit-wwzef0`
**Date:** 2026-07-18
**Method:** Lead Documentation Architect + 6 parallel workstream agents (A Inventory/IA · B Business/Domain · C Design/UX · D Architecture/Riverpod/Guard · E WBS/Delivery · F Traceability/E2E/SRS). Full manifest built; every business spec (127) read by Agent B; every WBS line (567) read by Agent E; design tokens/component contracts read by Agent C; the 48 KIT groups reconciled via the issue register; guard/config/`lib` verified against docs by Agent D.

> **Scope note on "single source of truth."** Per `AGENTS.md`, business (`docs/business/`) owns domain truth and the design kit (`docs/design/MemoX Design System_v4/`) owns visual truth. Where they diverge this report marks the conflict **P0** and quotes **both** sides without picking a winner — the decision is the Product Owner's.

---

## A. Executive verdict

### **APPROVED WITH CHANGES for foundation work · BLOCKED for the start-learning feature slice**

The documentation corpus is, on the whole, **unusually strong**: 538 doc files, **0 broken links**, **0 duplicate WBS IDs**, an exemplary business object-ownership catalog, a rigorously specified SRS policy that is consistent across business/design/WBS, and a WBS that already contains a 5Why, six decision gates, an architecture contract, a 16-step feature-delivery process, and a 14-point Definition of Done. This is far above typical pre-implementation quality.

It is **not yet sufficient to implement the learning features** because of **two P0 conflicts and a set of P1 preconditions the WBS itself declares mandatory but that are not yet satisfied**:

| Question | Answer |
| --- | --- |
| **Can implementation start now?** | **Foundation: yes.** Feature/learning slice: **no** — blocked on P0 decisions below. |
| **Can foundation work start?** | **Yes.** Tokens→theme→responsive (WBS 2), bootstrap/router/error/deterministic infra (WBS 1), Clean-Architecture/persistence (WBS 4) and shared `Mx*` (WBS 3) are specified well enough to begin — **once the guard submodule is initialized (P1-D01) and DG-02/DG-04 ADRs are written.** |
| **Can the start-learning flow start?** | **No.** It is not implementable as written: the "study mode" model is self-contradictory (**P0-02**), the deck content model conflicts between business and design (**P0-01**), and the design kit has no states for the mastery-round loop that defines the flow (**P1-07**). |
| **Which decision gates are blocking?** | **P0-01 / DG-01** (deck content model), **P0-02** (single-mode vs five-stage study model — *not currently in the WBS gate register*), **DG-02** (RN/phone design vs Flutter/multi-platform product), **DG-04** (guard pins SRS to data layer vs domain policy). DG-03 (SRS) is effectively resolved. |

**Readiness at a glance:** Business ✅ (strong, one internal conflict) · SRS ✅ · Design (phone-portrait) ✅ / (multi-platform) ⚠️ · Architecture-on-paper ✅ / artifacts ❌ · Guard ⚠️ (inert locally) · Tests ❌ (none) · WBS ✅ (minor gaps) · Start-learning ⛔ (blocked).

---

## B. Audit coverage

| Area | Total files | Read (full) | Inventoried / grep-sampled | Unreadable | Reviewer | Status |
| --- | ---: | ---: | ---: | ---: | --- | --- |
| `docs/business` | 127 (.md) | **127** | 0 | 0 | B (+F spine) | ✅ Complete |
| `docs/design/MemoX Design System_v4` | 270 | ~35 (.md specs, 12 tokens/*.css, SCOPE, readme, governance) | ~235 (125 jsx / 77 ts / 38 html mocks, HTML specimens) | 0 | C (+F specs) | ⚠️ Specs read; mocks inventoried/spot-checked |
| `docs/design/mobile-design-kit-audit-v5` | 55 | 4 (README, issue-register, audit-summary, KIT-32) | 51 (47 KIT via issue-register aggregation; rules/methods/manifest) | 0 | C | ✅ Register-complete |
| `docs/wbs` | 1 | **1** (567 lines) | 0 | 0 | E | ✅ Complete |
| `docs` root | 1 | **1** (`code-verification-guard.md`) | 0 | 0 | D | ✅ Complete |
| Root `README.md`, `AGENTS.md` | 2 | **2** | 0 | 0 | A/D | ✅ Complete |
| Config (`pubspec.*`, `l10n.yaml`, `analysis_options.yaml`, hooks, `ci.yml`, ARB) | ~12 | ~12 | 0 | 0 | D | ✅ Complete |
| `tools/code-verification-guard/**` | — | **0** | — | **Submodule not checked out** | D | ❌ Unreadable (see P1-D01) |
| `lib/**`, `test/**` | ~5 | 5 | 0 | 0 | D | ✅ Complete (greenfield template) |

**Files/areas NOT content-read (honest disclosure):**
- **~235 design mock files** under `MemoX Design System_v4/{ui_kits,components,templates}/**` (`.jsx`, `.ts`, `.d.ts`, `.html`, `.css`) — inventoried by path and grepped for platform/state keywords; representative frozen contracts (`MxButton.d.ts/.prompt.md`, token CSS) read in full. Component/state *contracts* were reviewed; individual mock render bodies were not line-read.
- **47 of 48 `KIT-XX-*.md`** — reviewed via `issue-register.md` (which aggregates every P0–P3 item per KIT id with status + evidence) + `audit-summary.md`; only `KIT-32` opened in full.
- **`tools/code-verification-guard/**` ruleset YAML** — physically absent from this checkout (submodule uninitialized); the `memox` rule contract could **not** be enumerated from disk.
- Design specimen HTML (`guidelines/*.html`, `audit/UI-UX Audit.html`), `screenshots/`, `assets/*.svg`, `_adherence.oxlintrc.json`, `SKILL.md`.

No file was found to be genuinely corrupt or unreadable except the uninitialized guard submodule. **This audit does not claim every mock render file was line-read**; the design *contracts, tokens, and audit register* were fully reviewed, which is the load-bearing surface.

---

## C. 5Why analysis

### 5Why-1 — Documentation source-of-truth
1. **Why is there ambiguity about which doc wins?** Because two source-of-truth docs (business, design kit) disagree on concrete points (deck content model; platform) and the reconciling decisions live only inside the WBS narrative.
2. **Why do they disagree?** The design kit was authored generically for **React Native / phone-portrait** and adopted into a **Flutter / multi-platform** repo without a reframing pass.
3. **Why wasn't it reframed?** No ADR process is stood up yet — `docs/architecture/`, `docs/decision-tables/` and the ADR index the WBS mandates (WBS 0.5) don't exist.
4. **Why does that matter now?** `AGENTS.md:45-52` makes any business↔design divergence a **STOP-and-ask** before feature work; without written ADRs, every developer re-litigates the same conflicts.
5. **Root cause / decision unlocked:** The corpus has *authorities* but no *adjudication layer*. **Decision:** produce the WBS-0 governance doc-set (ADR-001..004, decision-tables, navigation, database) **before** any 5.x feature work. **Impact if skipped:** guaranteed rework and guard drift on the critical path.

### 5Why-2 — Business ↔ Design divergence
1. **Why can't the learning UI be built?** The deck content model and the study-mode model differ between layers.
2. **Why?** "Deck" mixed-content is invalid in business but "and/or cards" in design SCOPE; "mode" means *one selectable strategy* in deck/today/preferences but *a fixed five-stage pipeline* in study-session/SRS.
3. **Why the overload?** The word "mode" and the deck-content prose were specified against different mental models at different times, never unified.
4. **Why not caught earlier?** The design mocks partially enforce the business model (parent decks disabled from receiving cards) so the prose conflict hid behind conformant fixtures.
5. **Root cause / decision unlocked:** Terminology and model unification is missing. **Decision:** Product Owner must pick one deck model (P0-01) and one study-mode model (P0-02) and record both in the SRS policy + study-deck + a glossary. **Impact if skipped:** the core flow cannot be coded; two teams build two incompatible engines.

### 5Why-3 — Ability to start the learning flow early
1. **Why prioritize start-learning?** User value begins only when a learner can create content, study it, resume safely, and get a deterministic next-due (WBS:24).
2. **Why isn't it ready?** The mode-model conflict (P0-02), the missing design states for mastery rounds/Recall-timeout (P1-07), and the un-written activation surface (F-15).
3. **Why weren't the mastery-round states designed?** The kit modeled single-pass grading; business later fixed the *unlimited-mastery-round* contract; the kit wasn't updated.
4. **Why the drift?** No traceability wiring forces design states to cover every business state (no Business→Design state matrix exists as an artifact).
5. **Root cause / decision unlocked:** Design-state coverage lags business-state coverage on the exact critical path. **Decision:** add `round-complete`/`retry-round`, Recall countdown/timeout, Guess invalid-pool, and an activation state to the graded-mode screens before WBS 5.6. **Impact if skipped:** the parity gate (FD-13) cannot pass for the most important screens.

### 5Why-4 — Clean Architecture / Riverpod foundation
1. **Why not code the Study screen first?** `lib/` is the stock counter template — no theme, DI, layers, or providers exist.
2. **Why start with foundation?** The guard rejects raw colors/spacing/Material and enforces domain/data roots + generated Riverpod; skipping foundation guarantees violations.
3. **Why is the guard not verifying this now?** The guard submodule is **not checked out** (P1-D01); the local pre-commit + agent Stop hooks fail *open*, so only CI enforces.
4. **Why does the architecture still risk drift?** DG-04: the guard pins SRS (`intervalForBox`/`boxAfterFinalization`) to **data-layer** files, contradicting the domain-policy placement the SRS doc and WBS §4 require.
5. **Root cause / decision unlocked:** The written architecture is best-practice, but its enforcer is absent and self-contradictory on SRS placement. **Decision:** initialize/pin the guard, make hooks fail-closed, and fix DG-04 upstream (WBS 0.4) before feature code. **Impact if skipped:** "passes locally" without any guard; SRS built in the wrong layer.

### 5Why-5 — Testability & guard compliance
1. **Why can't we trust the specs are testable?** The SRS doc mandates "every decision-table row has a test that cites its ID" (`srs-8-box-policy.md:181`) but `test/` has one starter file.
2. **Why no tests?** Greenfield; test infra (WBS 1.2/1.7) unstarted.
3. **Why is that a documentation risk?** Decision tables (SRS8-001..016, deck content-state, stage contracts) live inline in prose, not extracted to `docs/decision-tables/`, so there's nothing for tests to reference by ID.
4. **Why extract them?** Row-to-test parity (FD-14) and traceability need stable IDs outside prose.
5. **Root cause / decision unlocked:** Contracts are branch-heavy but the test-anchor layer is missing. **Decision:** extract decision tables + a traceability register (WBS 0.5) so ACs map to test IDs. **Impact if skipped:** un-provable conformance; regressions invisible.

### 5Why-6 — WBS dependency / critical path
1. **Why might delivery stall?** Group 16 (release hardening) depends on the literal string "selected release waves," not concrete IDs (E-07).
2. **Why does that matter?** The critical path and Group-16 ordering can't be computed automatically.
3. **Why isn't there a graph?** The WBS expresses deps as per-item text; there's no WBS-level DAG (E-08), unlike the business object DAG.
4. **Why do two gates lack owners?** DG-05 (locales) and DG-06 (storage matrix) aren't wired to owning WBS items (E-09).
5. **Root cause / decision unlocked:** The WBS is dependency-honest per item but lacks a computable critical-path artifact and two gate owners. **Decision:** add a WBS DAG, concrete Group-16 deps, and 0.x owners for DG-05/06. **Impact if skipped:** ambiguous scheduling; two mandatory gates can slip unnoticed.

---

## D. Findings (P0 → P3)

> IDs are prefixed by workstream (A/B/C/D/E/F) or `P0-`. Every finding cites `file:line`. Duplicate findings raised by multiple agents are merged (cross-refs shown).

### P0 — Blockers

**P0-01 — Deck content model: business "mixed content invalid" vs design "and/or cards"** · Conflict / Decision-required · (merges A-06, F-11, DG-01)
- **Evidence A (business):** `docs/business/deck/README.md:17` — "Mixed content | Có direct card và deck con cùng lúc | **Không hợp lệ** | Không render hoặc persist như trạng thái bình thường." Empty→Leaf **or** Parent, never both.
- **Evidence B (design):** `docs/design/MemoX Design System_v4/SCOPE.md:22` — "A Deck holds nested decks (a `children` count) **and/or cards**."
- **Internal design inconsistency:** the mocks *contradict their own SCOPE prose* and side with business — `ui_kits/.../add-card-target/AddCardTarget.jsx:3` ("PARENT decks are disabled … only leaf decks can receive cards"), `create-deck-firstrun/CreateDeckFirstRun.jsx:3` ("Create makes an EMPTY deck: no card, no nested deck").
- **Impact:** Schema (`decks`), create/add-content flows, library branching, and the study-scope aggregation all depend on this. Un-resolved, it forces a guess on the aggregate invariant.
- **Root cause:** SCOPE.md prose not reconciled to the finalized business content-state contract.
- **Decision required:** Product Owner confirms the deck content model. WBS DG-01 (`wbs:42`) *recommends* "Business wins" but no `ADR-001` exists. **Do not proceed on assumption** (`AGENTS.md:45-52`).
- **Closes when:** `ADR-001-deck-content-model.md` published; `SCOPE.md:22` corrected; both source docs cross-link the ADR; mixed-content decision-table row exists.
- **Blocks implementation:** YES (WBS 5.2, schema 4.2/4.3).

**P0-02 — "Study mode" model is self-contradictory: single-mode Picker vs fixed five-stage pipeline** · Conflict / Decision-required · (Agent B-01; core-flow blocker)
- **Evidence A (single-mode):** `docs/business/deck/study-deck.md:32,56-57,81` (a "Mode Picker", "Choose a mode", Review as a standalone selectable mode); `docs/business/preferences/configure-mode-preferences.md:7` (modes can be enabled/disabled/reordered, "session needs ≥1 mode"); `docs/business/today-dashboard/start-review-from-today.md:20` ("Resolve default/supported mode").
- **Evidence B (fixed five-stage, all mandatory):** `docs/business/study-session/start-study-session.md:82` ("Stage order mặc định: Review → Match → Guess → Recall → Fill"); unconditional chaining `study-mode/review-cards.md:64`, `match-terms-and-meanings.md:60`, `guess-card-meaning.md:30`, `recall-and-self-grade.md:41`; and **activation requires all five** — `learning-progress/srs-8-box-policy.md:47-53`.
- **Concrete break:** `configure-mode-preferences.md:7` permits disabling Match, but `srs-8-box-policy.md:50` makes Match mandatory for a new card to ever leave Box 0 → a disabled mode makes new cards **permanently unactivatable**.
- **Impact:** The START-LEARNING flow **cannot be implemented as written**; deck-doc readers build a picker, session-doc readers build a fixed pipeline. Activation, mode minimums, and mode preferences all break under the wrong reading.
- **Root cause:** "mode" is overloaded (session type vs one of five strategies); two doc layers specified against different mental models with no reconciling contract.
- **Decision required:** Choose one model and record it in `srs-8-box-policy.md §3`, `deck/study-deck.md`, and a glossary. If sessions always run all five, redefine the Mode Picker to *ordering-only* (never disable below the required five). If mode is user-selected, rewrite SRS activation to not require all five and make chaining conditional.
- **Closes when:** one model documented across all three docs; `configure-mode-preferences` reconciled with activation; decision-table updated. **This conflict is NOT in the WBS decision-gate register — add it as DG-07.**
- **Blocks implementation:** YES (WBS 5.5, 5.6, 5.4.3).

### P1 — Critical

**P1-D01 — Code-verification-guard submodule not checked out → guard inert locally & agent-side** · Defect/Drift · (Agent D-01)
- **Evidence:** `tools/code-verification-guard/` empty; `.gitmodules:1-4` → external repo `code-verification-guard-v2`; `git submodule status` → `-e583c9cd…` (uninitialized); `.githooks/pre-commit` exits 1 "submodule not initialized"; `.claude/hooks/guard_stop.py:60-66` exits **0** (does not block) when the guard is missing.
- **Impact:** The "3-surface enforcement" (`AGENTS.md:54-59`) is effectively **1 surface (CI)**; fresh clones and the Claude/Codex Stop hooks enforce nothing. The rule contract cannot be reviewed/versioned from this repo.
- **Fix:** `git submodule update --init --recursive` in setup (already documented in `docs/code-verification-guard.md:13`); make the Stop hooks **fail-closed** (non-zero) when the guard is absent; pin & document the guard commit in-repo.
- **Blocks implementation:** YES for trustworthy local verification.

**P1-PLATFORM — Design kit targets React Native / phone-portrait; product is Flutter / multi-platform** · Conflict / Decision-required · (merges A-01, C-01, C-02, C-06, D-02, F-01; = DG-02/DG-05)
- **Evidence A (design):** `docs/design/MemoX Design System_v4/readme.md:3` ("built with **React Native**"); `SCOPE.md:40` ("Target platform | React Native"); `SCOPE.md:50-59` (Tablet/Landscape/Foldable/RTL/i18n = "Not supported"); `MxButton.d.ts:1` (`import … from 'react'`).
- **Evidence B (product):** `AGENTS.md:3` ("Flutter, multi-platform"); `pubspec.yaml:2`; android/ios/linux/macos/web/windows runner dirs; `l10n.yaml` + en/vi ARB; the `memox-design` skill ("This project is Flutter… map onto Flutter `ThemeData`").
- **Internal contradiction inside the kit:** core layer is 100% React; **54 feature `.d.ts` files annotate "the Flutter counterpart"** (e.g. `_features/account-sync/components/SyncBlock.d.ts:12`, `reminder/components/TimeCol.d.ts:4`).
- **Two sub-defects:**
  - **Token→Flutter mapping absent (C-03):** all **265** manifest tokens are CSS custom properties; **zero** `ThemeData`/`ThemeExtension`/Dart token module exists.
  - **Responsive out-of-scope is invalid for this product (C-02):** 9 responsive/adaptive/landscape **P1** items were closed **ACCEPTED** as "phone-portrait RN kit out of scope" (`issue-register.md:36-44`) — for a web+desktop+mobile Flutter app these are **effectively open** (no tablet/desktop/web breakpoints, no adaptive presentation, no list-detail, no landscape/foldable).
- **Impact:** The design source-of-truth cannot be followed literally; a whole Flutter binding + adaptive layer is undelivered. The kit's "0 P1 open" gate does not hold for the real device matrix.
- **Decision required / fix:** Publish `ADR-002-flutter-platform-and-adaptive-scope.md`: keep 390×780 light/dark as the parity baseline, add the Flutter adaptive contract (WBS 2.6 already specifies width classes), reframe "React Native" → framework-neutral/Flutter across the kit, generate a Dart token layer, and re-open KIT-32/34/35/36 against the true target. `ADR-003-localization-scope.md` for en/vi + RTL deferral.
- **Blocks implementation:** Partially — foundation token mapping can proceed under the ADR; large-screen UI is blocked until adaptive rules exist.

**P1-B03 — `schedule-next-review` adds a three-outcome "conservative" schedule contradicting the binary 8-box policy** · Defect/Conflict · (Agent B-03)
- **Evidence A:** `docs/business/learning-progress/schedule-next-review.md:20-22` — outcome classes `correct | Partial/hard/almost → "Conservative next schedule" | wrong`.
- **Evidence B:** `docs/business/learning-progress/srs-8-box-policy.md:12` ("engine nhận `correct` hoặc `wrong`"), `:75` ("almost → wrong"), `:16` ("không dùng ease factor, SM-2 hoặc FSRS").
- **Impact:** An implementer following `schedule-next-review.md` builds a third scheduling path with no box rule, breaking determinism and sticky-wrong.
- **Fix:** Remove the "Partial/hard/almost → conservative" row and SM-2 terminology from `schedule-next-review.md §2`; state almost/timeout→`wrong` and reference `srs-8-box-policy.md §4-5` as sole source.
- **Blocks implementation:** YES for the SRS scheduling path.

**P1-B02 — Due-review session mode composition undefined** · Gap / Decision-required · (Agent B-02)
- **Evidence:** `srs-8-box-policy.md:70` assumes "an SRS review session" produces one terminal grade but never defines its mode set; `deck/study-deck.md:23` + `today-dashboard/start-review-from-today.md:20` imply a single/default mode; conflicts with the all-five new-learning flow (`srs-8-box-policy.md:47-56`). Also `surface-due-cards.md:45` excludes Box 8 from queues while `study-deck.md:9-10` allows manual study of any non-hidden card → decision-row `srs-8-box-policy.md:172` (Box 8 wrong→7) is reachable only via manual study.
- **Impact:** The most common ongoing path (due review of active cards) has no defined mode composition or terminal-grade derivation.
- **Fix:** Define mode composition + terminal-grade derivation for (a) new-card activation, (b) due-review, (c) manual full-deck study.
- **Blocks implementation:** YES for WBS 5.6 due-review.

**P1-07 — Design kit has no states for the mastery-round loop / Recall timeout / activation** · Coverage gap · (merges F-03, F-04, F-05, F-15)
- **Evidence (business requires):** `study-mode/README.md:16` ("graded mode complete only when the just-finished round has empty `nextRoundFailedCardIds`; unlimited mastery rounds"); `:77-79` per-mode `round-complete`/`retry-round`/`invalid-distractor-pool`; Recall 20s timeout `study-mode/README.md:37`, `answer-study-stage.md:23,66`; activation `srs-8-box-policy.md:59-64`.
- **Evidence (design lacks):** `specs/match-mode.md` states = playing/selected/correct/wrong/almost/complete; `guess-mode.md` = waiting/correct/wrong/long-text/complete; `recall-mode.md` = before-reveal/revealed/forgot/remembered/complete; `fill-mode.md` = waiting/typing/hint/correct/wrong/complete — **none has `round-complete`, `retry-round`, a Recall countdown/timeout state, Guess `invalid-distractor-pool`, or an SRS-activation surface.**
- **Impact:** The iterative loop and timeout that *define* start-learning have no reference states; the parity gate (FD-13) cannot pass for WBS 5.6.6–5.6.9 / 5.6.11.
- **Fix:** Add `round-complete` + `retry-round` to all four graded-mode screens; Recall countdown + timeout states; Guess invalid-pool recovery; an activation/graduation state (or explicitly note it is background-only).
- **Blocks implementation:** YES for design-parity on the critical path.

**P1-TRACE — Traceability spine un-rooted: no ADRs, decision-tables, architecture/navigation/database docs, or tests** · Missing · (merges D-04, F-02, E-02)
- **Evidence:** `docs/` contains only `business/ design/ wbs/` (+ this audit) — `docs/architecture/`, `docs/decision-tables/`, `docs/business/navigation/`, `docs/database/` and any ADR file are absent; the WBS makes them a hard precondition (`wbs:38,42-47,227`). `srs-8-box-policy.md:181` demands a test per decision-table row; `test/` has one starter file.
- **Impact:** The Business→Design→Architecture→WBS→Test→Guard chain exists only as prose; no ADR satisfies the DG-01..06 gates the WBS says must precede feature work; conformance is unprovable.
- **Fix:** Deliver the WBS-0.5 doc-set + traceability register first; extract inline decision tables to `docs/decision-tables/`; add a `source: guard/architecture` category for engineering-derived WBS items (E-02/F-10).
- **Blocks implementation:** YES per the WBS's own gate.

**P1-DG04 — Guard pins SRS to the data layer, contradicting domain-policy placement** · Conflict · (merges D-07, F-SRS, DG-04)
- **Evidence:** `wbs:44-45` (DG-04) — "Guard pins `intervalForBox`/`boxAfterFinalization` to data repo files and contains old `folders` target paths"; vs `srs-8-box-policy.md:192` ("engine … không import Flutter/Drift/Riverpod") and `wbs:97,342` (SRS = pure domain policy). Cannot be verified against the actual rules (P1-D01).
- **Impact:** Following the guard puts SRS calculation in `data/`, violating Clean Architecture; the domain SRS engine would trip stale-path rules.
- **Fix:** Resolve upstream in the guard repo (WBS 0.4); repoint stale `folders`/`Folder` paths to Deck paths; permit the domain SRS policy; bump the submodule pin.
- **Blocks implementation:** YES for WBS 5.4.3 placement.

### P2 — Major

- **P2-B04 — Current-session Relearn ↔ SRS bridge undefined** (B-04). `study-session/relearn-cards.md:62`, `learning-progress/schedule-next-review.md:12` vs `srs-8-box-policy.md:88-89,110-111` (min interval +1 day). Which terminal-wrong enters the session-local Relearn queue vs simply getting tomorrow's `dueAt` is unspecified. Fix: add a Relearn-trigger rule to `srs-8-box-policy.md`.
- **P2-B05 — Global deck-search ranking owned by two files** (B-05). `deck/search-decks.md:57-61` vs `search/search-library-content.md:46-51`; violates single-owner rule (`business/README.md:74`). Fix: give global deck+card ranking to `search/`; scope `deck/search-decks.md` to in-place Library/Parent search.
- **P2-B06 — Daily Study Goal metric/unit never defined** (B-06). `study-goal/README.md:9`, `track-daily-goal.md:9,38`, `finalize-study-session.md:62` reference an abstract "metric/unit/amount"; no file states what is measured. Fix: decide v1 metric (e.g. distinct cards with a committed terminal outcome per local day).
- **P2-B07 — Streak qualification policy undefined** (B-07). `study-streak/record-streak-day.md:7`, `README.md:8` — what qualifies a day is never stated. Fix: define the threshold.
- **P2-F06 — Backup capability has no design screen** (F-06). `business/backup/README.md` owns 6 flows; `specs/INDEX.md` has no backup screen. Fix: add backup/restore specs or record an explicit "design deferred to WBS 15" exception.
- **P2-F07 — No account registration/sign-up flow** (F-07). `account/sign-in.md:19` "Create account session" ≠ registration; no `create-account` flow, no sign-up screen. Fix: add a registration flow or record delegation to an external IdP (ADR under WBS 14.1).
- **P2-F08 — First-launch / onboarding UX has no owner** (F-08). WBS journey starts "Launch" (`wbs:13`) but WBS 1.3 is *technical* bootstrap only; cold-start/first-run/language-pair-gate is emergent across `handle-empty-library-today.md`, `create-deck.md`, `create-language-pair.md`. Fix: add a first-run owner doc.
- **P2-F09 — Theme accent picker vs fixed-palette / no-runtime-override rule** (F-09). Design composite `theme` = AccentPicker (`readme.md:123`) vs `readme.md:47,92` ("no runtime theme override") and `preferences/README.md:22-24` (Preferences chooses only System/light/dark). Fix: confirm whether AccentPicker is live; if so, STOP-and-ask.
- **P2-C04 — `coverage-report.md` stale/self-contradictory** (C-04). `governance/coverage-report.md:29` says 18 `Mx*` (omits the 5 feedback comps → actual 23); `:31` "11 token files" (actual 12); `:32` "190+ tokens" (manifest 265); claims RTL "0 blockers" while `SCOPE.md:58` says RTL unsupported. Fix: regenerate from `_ds_manifest.json`; reconcile RTL wording.
- **P2-C05 — High-contrast profile defined but not rolled out** (C-05). `tokens/high-contrast.css` exists but `_ds_manifest.json` `themes` has 1 entry (dark only); HC excluded from parity/contrast snapshot; `SCOPE.md:70` = Planned. Fix: register HC as a theme + fixtures + contrast gate.
- **P2-C10 — No primitive color ramp; semantic roles hold literal hex** (C-10). `tokens/colors.css:26-29` inline hex, no `--memox-violet-500`-style ramp (spacing/type/radius do have primitive tiers). Fix (optional): add a primitive palette or document the intentional collapse — matters for the Flutter `ColorScheme` port.
- **P2-D03 — Architecture depends on undeclared packages** (D-03). `pubspec.yaml:30-47` lacks Drift, go_router, clock, uuid, freezed that the WBS names as the persistence/nav/deterministic contracts. Fix: execute WBS 1.1 dependency baseline.
- **P2-D05 — `.codex/hooks.json` hardcodes a Windows absolute path** (D-05). `python 'D:\workspace\memox_v6\.codex\hooks\guard_stop.py'` — fails on any other machine/OS (incl. this Linux env). Fix: use a repo-relative invocation like `.claude/settings.json`.
- **P2-D06 — `intl: any` unpinned** (D-06). `pubspec.yaml:46`; WBS flags it twice (`wbs:33,234`). Fix: pin to a caret range.
- **P2-E01 — No Definition of Ready** (E-01). Strong DoD (`wbs:517-534`) but no DoR; entry control only implied. Fix: add a DoR mirroring §9.
- **P2-E05 — No localization foundation work package** (E-05). l10n appears only as folder contract/cert; the DG-05 pseudo-loc fixture + AppLocalizations scaffolding have no owning item. Fix: add a Group 1/2 "Localization foundation" item.
- **P2-E07 — Group 16 depends on undefined "selected release waves"** (E-07). `wbs:492-498`. Fix: replace with concrete WBS IDs.
- **P2-E09 — DG-05 and DG-06 lack owning WBS items** (E-09). DG-01..04 wired to 0.1–0.4; DG-05/06 not. Fix: add 0.x owners or annotate 0.6/4.1.
- **P2-A02 — 48-file KIT checklist reachable only via unlinked `file-manifest.md`** (A-02). 0 referrers; audit README doesn't link it. Fix: add the nav link.
- **P2-A03 — No `docs/README.md` portal** (A-03) and **P2-A04 — root `README.md` is the stock Flutter template** (A-04). Fix: add a docs portal; write a real project README pointing to `AGENTS.md`/`docs/`.
- **P2-A05 — WBS file is an orphan** (A-05). 0 referrers; no `docs/wbs/README.md`. Fix: link the WBS from `AGENTS.md`/portal.

### P3 — Minor

- **P3-B08 — Terminology drift** (B-08): "Flashcard" (object) vs "Card" (body); "stage" vs "mode" (amplifies P0-02); "native" vs "meaning" language. Fix: add a glossary to `business/README.md`.
- **P3-B09 — SRS decision table omits explicit almost/timeout rows** (B-09): normalization defined only in `srs-8-box-policy.md §4`, not in the §11 table; activation is grade-independent (worth one clarifying line). Fix: add rows SRS8-017/018.
- **P3-A06 — DG-01 decision logged only in WBS**, not cross-linked from `deck/README.md` or `SCOPE.md` (A-06). Fix: cross-link once ADR-001 exists.
- **P3-A07 — Missing folder indexes** for `components/*`, `guidelines`, `governance` (A-07).
- **P3-A08 — "126 specs" vs 109 actual** (`AGENTS.md:38`; 127 md − 18 READMEs) (A-08). WBS repeats "126" (`wbs:30`). Fix: correct the count.
- **P3-A09/A10 — Naming:** lone lowercase `readme.md` among 23 `README.md`; `INDEX.md` vs `README.md`; folder `MemoX Design System_v4` has spaces+underscore (forces quoting) (A-09/A-10).
- **P3-A12 — Superseded `audit/UI-UX Audit.html` (v4-era)** sits beside the current v5 md audit (A-12). Fix: archive/date it.
- **P3-A13 — `SKILL.md` triplicated** (design kit, `.claude`, `.agents`) — drift risk (A-13).
- **P3-A14 — No machine-readable doc-status field** anywhere (all DRAFT/DEPRECATED/PLACEHOLDER hits are domain vocabulary, verified) (A-14). Optional front-matter `status:`.
- **P3-C07 — `MxButton.prompt.md:13` "no built-in loading state" vs `.d.ts:20` `loading?`** (C-07).
- **P3-C08 — `MxList` spec/contract in `core/` but impl+manifest in `surfaces/`** (C-08).
- **P3-C09 — `MxCard.prompt.md` lacks the per-component RTL/localization note** all other 22 carry (C-09).
- **P3-C11 — Two open exceptions:** bespoke brand/app icon (EXC-02), 2 uncomparable parity pairs (EXC-05) (C-11).
- **P3-D08 — "Riverpod Annotation v3" heading vs pinned `riverpod_annotation 4.0.2` on Riverpod 3.x** (`wbs:154`) (D-08).
- **P3-D09 — Blanket ban on Riverpod Mutations** should be an ADR, not a one-liner (`wbs:165`) (D-09).
- **P3-F12 — Screen-count drift** ("26 screens" `readme.md:81` vs "27" `INDEX.md`/`wbs:32`) and `SCOPE.md:72` wrong WBS ref (says 5.3 Dashboard; dashboard = 5.7) (F-12).
- **P3-E04/E06/E10/E11/E12 — WBS:** no per-item owner column; some XL packages exceed a reviewable PR (5.6.13, 3.x); no explicit input column; no timeline/velocity anchor; doc-section vs WBS-group number namespace collision ("5.1" ambiguous).

> **"No findings" declarations (required):** **Broken links — none** (0 across 253 links/270 files). **Duplicate WBS IDs — none.** **Corrupt/unreadable docs — none** (except the uninitialized guard submodule). **Open design P0 by the kit's own gate — none** (all 6 genuinely FIXED). **SRS interval/box/transition inconsistency across business/design/WBS — none.**

---

## E. Conflict register

| ID | Business evidence | Design evidence | Arch/WBS impact | PO decision needed | Options | Trade-off | Recommendation (non-binding) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| **CF-01** (P0-01/DG-01) | `deck/README.md:17` mixed content invalid | `SCOPE.md:22` "and/or cards" | Schema 4.2/4.3, flows 5.2 | Deck content model | (a) Business no-mixed (b) Design and/or | (a) simpler invariant, matches mocks; (b) more flexible, breaks current fixtures | (a) — mocks already enforce it; publish ADR-001 |
| **CF-02** (P0-02/new DG-07) | `study-deck.md:32,56` single-mode picker | `start-study-session.md:82` + `srs-8-box-policy.md:47-53` fixed five-stage | 5.5, 5.6, 5.4.3 | Study-mode model | (a) always all five (b) user-selectable | (a) matches activation rule; (b) matches picker/preferences UI | Decide explicitly; if (a), make preferences ordering-only |
| **CF-03** (P1-PLATFORM/DG-02) | `AGENTS.md:3` Flutter multi-platform | `readme.md:3`/`SCOPE.md:40` React Native, phone-portrait | Tokens 2.x, responsive 2.6, all UI | Platform & adaptive scope | (a) Flutter+adaptive, 390×780 parity baseline | Adaptive work adds scope; parity keeps a stable baseline | (a) per WBS 5Why-3; publish ADR-002/003 |
| **CF-04** (P1-DG04) | `srs-8-box-policy.md:192` SRS = pure domain | Guard pins SRS to data files (`wbs:45`) | 5.4.3 placement | Guard↔architecture reconciliation | (a) fix guard upstream (b) bend code to guard | (a) correct layering, needs guard-repo change; (b) violates Clean Arch | (a) — WBS 0.4 |
| **CF-05** (P2-F09) | `preferences/README.md:22-24` mode only | `readme.md:123` AccentPicker | core/theme | Is runtime accent live? | (a) demo-only (b) real feature | (b) contradicts no-runtime-override token rule | Confirm; default to (a) |

---

## F. Traceability matrix

Legend: **C** contract exists · **G** gap · **⚠** conflict. (Architecture/Test columns are target-only repo-wide — greenfield.)

| Capability | Business doc | Design screen | Arch boundary | WBS | AC | Test | Guard | Status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Language Pair | `language-pair/*` C | `languages.md` C | domain/usecases G | 5.1 C | C | G | design-system C | Contract-only |
| Deck (content model) | `deck/README.md` C | `create-deck-*`,`library` C | schema `decks.parent_id` G | 5.2 ⚠ | C | G | Deck-path (stale `folders`) ⚠ | **⚠ CF-01** |
| Flashcard | `flashcard/*` C | `flashcard-editor/list`,`add-card-target` C | domain+data G | 5.3,6.3-5 C | C | G | design-system C | Contract-only |
| Learning Progress / SRS | `srs-8-box-policy.md` C | `settings.md` (display) C | ⚠ guard data-layer | 5.4,0.3 ⚠ | `srs-8-box-policy.md:183-194` C | none (SRS8 IDs unbacked) G | data-layer SRS rule ⚠ | **⚠ CF-04 + no tests** |
| Study Mode (5) | `study-mode/*` C | 5 mode specs C (**retry/round-complete G**) | domain factory/DI C | 5.5 C | C | G | Mx*/DS C | **⚠ P1-07 + P0-02** |
| Study Session | `study-session/*` C | `study-session`,`mode-picker`,`study-result` C | data tx boundary G | 5.6 ⚠ | C | G | async-builder/Mx* C | **⚠ P0-02, P1-B02** |
| Today Dashboard | `today-dashboard/*` C | `dashboard.md` C | read projection G | 5.7 C | C | G | C | Contract-only |
| Goal / Streak / Stats | `study-goal/*`,`study-streak/*`,`study-statistics/*` C | `statistics.md`+cards C | projections G | 7.x,11.x C | ⚠ metric/threshold undefined | G | C | **⚠ P2-B06/B07** |
| Reminder | `reminder/*` C | `reminder.md` C | platform adapter G | 9.x C | C | G | C | Contract-only |
| Search | `search/*` C | `search.md` C | read model G | 10.x C | C | G | C | **⚠ P2-B05 dual owner** |
| Audio Playback | `audio-playback/*` C | `player.md` C | domain queue G | 12.x C | C | G | C | Contract-only |
| Content Transfer | `content-transfer/*` C | `import`,`export` C | data adapters G | 13.x C | C | G | C | Contract-only |
| Account / Sync | `account/*` C (**registration G**) | `account-sync.md` C | auth ADR G | 14.x C | C | G | secure-storage C | **⚠ P2-F07** |
| Backup / Restore | `backup/*` C | **none G** | versioned format G | 15.x C | C | G | C | **⚠ P2-F06** |
| Preferences | `preferences/*` C | `settings`,`theme` C (**accent ⚠**) | core/theme G | 8.x C | C | G | design-system C | **⚠ P2-F09** |
| First launch / onboarding | **no owner G** | emergent | bootstrap 1.3 (technical) | 1.3 partial | G | G | — | **⚠ P2-F08** |
| Verifier / infra | guard-derived | — | WBS §4 C | 1.2,1.5,1.6 C | WBS DoD C | G | guard C | Engineering-derived |

---

## G. End-to-end flow audit (22 flows)

**Flow 5 — START LEARNING (exhaustive).** Business-to-business chain is fully specified and internally consistent: `deck/study-deck.md` (scope/eligibility) → `study-session/start-study-session.md:24-38,77-87` (atomic snapshot, no orphan, idempotent retry) → five graded stages `answer-study-stage.md:18-24` with mastery rounds `study-mode/README.md:16` → sticky-wrong terminal aggregation `srs-8-box-policy.md:68-81` → activation 0→1 `srs-8-box-policy.md:36-66` → finalize `finalize-study-session.md:14-36`. **Blockers on this flow:** P0-02 (mode model), P1-07 (no design states for mastery rounds/Recall-timeout/activation), and the Guess ≥5-distinct-meaning eligibility only partially designed (P1-07/F-05). Error/offline states exist (`start-study-session.md:72,94`; `finalize-study-session.md:71,87`). Architecture/test/guard columns are target-only.

**Flows 1–4, 6–22 (gap summary):**

| # | Flow | Owner | Design | WBS | Gap/conflict |
| --- | --- | --- | --- | --- | --- |
| 1 | First app launch | **none (emergent)** | `dashboard` empty, `create-deck-firstrun` | 1.3 (technical) | **P2-F08 unowned UX** |
| 2 | Select/create Language Pair | `language-pair/*` | `languages.md` | 5.1 | — |
| 3 | Create Deck | `deck/create-deck.md` | `create-deck-*` | 5.2 | **CF-01 P0-01** |
| 4 | Create/import Flashcard | `flashcard/create`, `content-transfer/*` | `flashcard-editor`,`import` | 5.3,13.x | — |
| 5 | **Start learning** | (chain above) | 5 mode specs | 5.5-5.7 | **P0-02, P1-07** |
| 6 | Complete required modes | `study-mode/README.md:14-16` | 5 mode specs | 5.5,5.6 | **P1-07** |
| 7 | Activate Learning Progress | `srs-8-box-policy.md:36-66` | none | 5.4.3 | **F-15 no surface** |
| 8 | Card enters SRS | `initialise-card-progress.md` | none (background) | 5.4.1 | acceptable |
| 9 | Get due queue | `surface-due-cards.md` | `dashboard`,`mode-picker` | 5.4.2 | — |
| 10 | Answer correct/wrong/almost/timeout | `answer-study-stage.md:18-24` | 5 mode specs | 5.6.10 | **P1-07 (Recall timeout)** |
| 11 | Retry | `answer-study-stage.md:10-11,15` | `study-session` | 5.6.10-11 | **P1-07 (mastery round undesigned)** |
| 12 | Finish Study Session | `finalize-study-session.md` | `study-result.md` | 5.6.13 | — |
| 13 | Update SRS 8-box | `srs-8-box-policy.md:83-116` | `settings` (read-only) | 5.4.3-4 | **P1-B03, P1-DG04** |
| 14 | Today Dashboard | `load-today-dashboard.md` | `dashboard.md` | 5.7 | — |
| 15 | Streak/statistics/goal | `study-*` | `statistics`+cards | 7.x,11.x | **P2-B06/B07 undefined metric/threshold** |
| 16 | Reminder | `reminder/*` | `reminder.md` | 9.x | — |
| 17 | Search | `search/*` | `search.md` | 10.x | **P2-B05 dual owner** |
| 18 | Reset progress | `reset-learning-progress.md`,`reset-deck-progress.md` | `deck-settings` | 6.1 | folded into deck-settings |
| 19 | Backup/restore | `backup/*` | **none** | 15.x | **P2-F06** |
| 20 | Import/export/transfer | `content-transfer/*` | `import`,`export` | 13.x | — |
| 21 | Offline/restart/crash | `resume/exit-study-session.md`,`answer-study-stage.md:90-95` | `study-session` (exit/resume-error) | 5.6.12,5.7.4 | well-distributed; no single owner |
| 22 | Account lifecycle | `account/*` | `account-sync.md` | 14.x | **P2-F07 no sign-up** |

---

## H. WBS assessment

**Strengths:** 117 leaf work packages, **unique contiguous IDs, no duplicates, no gaps**; strong 14-point global DoD (`wbs:517-534`); per-wave release gates; ordering genuinely engineered to reach "start learning" fastest (Group 5 critical path gated at 5.7.5); explicit 5Why and six decision gates; FD-01..16 delivery process; test/evidence matrix (`wbs:503-513`).

**Issues:**
- **Missing decision gate:** the study-mode model conflict (P0-02) is **not** in the DG register — **add DG-07**.
- **Dependency:** Group 16 depends on the literal "selected release waves" not IDs (P2-E07); no WBS-level critical-path DAG (E-08).
- **Foundation gap:** no localization foundation package (P2-E05); expected foundation step 9 unslotted.
- **Under-wired gates:** DG-05 (locales) and DG-06 (storage matrix) have no owning WBS item (P2-E09).
- **Per-item fields absent (uniform across all 117):** owner, explicit input, AC-distinct-from-DoD, per-item guard command, per-item source references, per-item verification command — all supplied *globally* instead (E-02/E-04/E-10/E-03). No DoR (P2-E01).
- **Oversized packages:** several XL items (5.6.13 bundles finalize+summary+contribution+retry+result+return-route; 3.3-3.5, 3.7, 3.10, 3.11) exceed a reviewable PR (E-06).
- **Ordering deviations from the literal expected sequence** (all defensible): bootstrap/router before tokens; Mx widgets before persistence; Learning Progress+SRS before Study Session (arguably *more* correct — the session writes into progress).
- **Namespace collision:** doc §5/§7 vs WBS group 5/7 makes "5.1" ambiguous (E-12).

**Optimal ordering to "start learning" fastest (with quality gates):** 0.1–0.6 governance/ADRs (add DG-07 + DG-05/06 owners) → 1.1 deps + 1.2 verifier + 1.3 bootstrap + 1.6 deterministic infra + **new localization foundation** → 2.x tokens/theme/responsive + 1.4 router + 1.5 error/observability → **4.x Clean-Arch/persistence in parallel with 3.x Mx widgets** (independent lanes) → 5.1 Language Pair → 5.2 Deck → 5.3 Flashcard → 5.4 Progress+SRS → 5.5 Study Mode → 5.6 Study Session → 5.7 Today → **5.7.4/5.7.5 first-learning E2E + release gate (ship)** → Groups 6–16 in documented wave order with concrete Group-16 deps.

---

## I. Missing-document register

| Document | Owner | Proposed location | Required content | Reason | Severity | WBS dep |
| --- | --- | --- | --- | --- | --- | --- |
| ADR-001 Deck content model | Product + Arch | `docs/architecture/adr/` | Resolve CF-01; mixed-content decision-table | Unblocks 5.2, schema | P0 | 0.1 |
| ADR (DG-07) Study-mode model | Product + Domain | `docs/architecture/adr/` | Resolve CF-02; activation vs picker | Unblocks 5.5/5.6 | P0 | new 0.x |
| ADR-002 Platform & adaptive scope | Arch | `docs/architecture/adr/` | 390×780 parity + Flutter adaptive matrix; RN reframing | Unblocks all UI | P1 | 0.2 |
| ADR-003 Localization scope | Arch | `docs/architecture/adr/` | en/vi v1, RTL deferral, CJK test | DG-05 | P1 | 0.6 |
| ADR-004 Storage platform matrix | Arch | `docs/architecture/adr/` | Drift opener per platform | DG-06 | P1 | 4.1 |
| Decision-tables set | Domain | `docs/decision-tables/` | Extract SRS8-001..018, deck content-state, stage contracts w/ test-ID column | Testability/traceability | P1 | 0.5 |
| Navigation contract | Arch | `docs/business/navigation/` | Route names/paths/guards | Router 1.4 | P1 | 0.5 |
| Database/schema docs | Data | `docs/database/` | Schema v1, migrations, invariants | 4.2/4.7 | P1 | 0.5 |
| Traceability register | Lead | `docs/` | Business→…→test IDs; `source: guard/architecture` tag | Verifiable chain | P1 | 0.5 |
| `docs/README.md` portal | Docs | `docs/` | Cross-link business/design/wbs/standards | Discoverability | P2 | — |
| First-run/onboarding owner | Domain | `docs/business/` | Cold-start, language-pair gate | P2-F08 | P2 | 5.1 |
| Backup design specs (or deferral note) | Design | design specs | Backup/restore screens or scope note | P2-F06 | P2 | 15 |
| Localization foundation WBS item | Delivery | `docs/wbs` | ARB pipeline, pseudo-loc/CJK fixtures | P2-E05 | P2 | 1.x |

---

## J. Duplication / staleness register

| Item | Type | Evidence | Proposed source-of-truth | Action (do NOT auto-delete) |
| --- | --- | --- | --- | --- |
| Flutter vs React Native framing | Conflict | `readme.md:3` vs `AGENTS.md:3` | Flutter (repo reality) | Reframe kit prose (ADR-002) |
| Deck content model | Conflict (adjudicated in WBS only) | `deck/README.md:17` vs `SCOPE.md:22` | Business | Publish ADR-001, fix SCOPE prose |
| `schedule-next-review` 3-outcome vs binary SRS | Conflict | `schedule-next-review.md:21` vs `srs-8-box-policy.md:12` | `srs-8-box-policy.md` | Correct `schedule-next-review.md` |
| Global deck search | Dual ownership | `deck/search-decks.md` vs `search/search-library-content.md` | `search/` object | Scope deck search to in-place |
| v4 HTML audit vs v5 md audit | Superseded/stale | `audit/UI-UX Audit.html` vs `mobile-design-kit-audit-v5/` | v5 | Archive/date the v4 html |
| `coverage-report.md` counts + RTL | Stale/contradictory | `coverage-report.md:29-32` vs manifest/`SCOPE.md:58` | `_ds_manifest.json` | Regenerate |
| `SKILL.md` ×3 | Near-duplicate | design kit + `.claude` + `.agents` | one source | Single source + generated copies |
| "126 specs" | Stale count | `AGENTS.md:38`, `wbs:30` | actual 109 | Correct count |
| Screen count 26/27 | Doc drift | `readme.md:81` vs `INDEX.md`/`wbs:32` | 27 | Correct readme |

---

## K. Recommended remediation plan

| Action | Files to create/edit | Section | Change | Dependency | AC | Reviewer |
| --- | --- | --- | --- | --- | --- | --- |
| **K1 (P0)** Resolve CF-01 deck model | `docs/architecture/adr/ADR-001` (new); cross-link `deck/README.md`, `SCOPE.md:22` | content model | Decide + record; fix SCOPE prose | PO decision | ADR accepted; SCOPE matches; decision-table row | Product+Arch |
| **K2 (P0)** Resolve CF-02 study-mode model + add DG-07 | new ADR; `srs-8-box-policy.md §3`, `deck/study-deck.md`, `configure-mode-preferences.md`, `docs/wbs` DG table | study model | Decide all-five vs picker; reconcile preferences | PO decision | one model across 3 docs; DG-07 added | Product+Domain |
| **K3 (P1)** Init/pin guard + fail-closed hooks | setup docs; `.claude/hooks/guard_stop.py`; `.codex/hooks.json` | guard | Initialize submodule; hooks non-zero when missing; fix Windows path | — | guard runs locally; hooks block on absence | Arch |
| **K4 (P1)** ADR-002/003 platform+adaptive+locale; Dart token layer plan | new ADRs; kit `readme.md`/`SCOPE.md` | platform | Reframe RN→Flutter; adaptive matrix; token→ThemeExtension mapping | K1-K2 | ADRs accepted; token mapping doc | Arch+Design |
| **K5 (P1)** Fix SRS scheduling contradiction | `schedule-next-review.md §2` | scheduling | Remove 3-outcome; almost/timeout→wrong; ref policy §4-5 | — | binary only; no SM-2 terms | Domain |
| **K6 (P1)** Define due-review mode composition | `srs-8-box-policy.md`, `study-deck.md` | review | Mode set + terminal-grade for new/due/manual | K2 | 3 cases defined | Domain |
| **K7 (P1)** Add design states for mastery loop | graded-mode specs `match/guess/recall/fill-mode.md` | states | round-complete/retry-round/Recall-timeout/Guess-invalid-pool/activation | K2 | states + shots exist | Design |
| **K8 (P1)** Stand up governance doc-set | `docs/architecture`, `docs/decision-tables`, `docs/business/navigation`, `docs/database`, traceability register | WBS 0.5 | Create + ADR index; extract decision tables w/ test-ID column | K1-K5 | doc-set exists; DG-01..06 ADRs present | Lead |
| **K9 (P1)** Fix DG-04 upstream | guard repo; submodule pin | guard | Repoint stale `folders`; permit domain SRS | K3 | 0 stale-path warnings for active code | Arch |
| **K10 (P2)** Business gaps | `study-goal/set-*`+`track-*`, `study-streak/record-*`, `srs-8-box-policy.md`, `search/*` | domain | Define goal metric, streak threshold, relearn bridge, search owner | — | metrics/thresholds/rules defined | Domain |
| **K11 (P2)** WBS corrections | `docs/wbs` | WBS | DoR, localization item, Group-16 concrete deps, DG-05/06 owners, source-refs column, WBS DAG | — | fields present | Delivery |
| **K12 (P2)** Design/doc hygiene | `coverage-report.md`, HC theme reg, `docs/README.md`, root `README.md`, KIT nav link, WBS link | IA | Regenerate coverage; register HC; add portal/README/links | — | counts match; links resolve | Design/Docs |
| **K13 (P2)** Config hygiene | `pubspec.yaml`, `.codex/hooks.json` | config | Pin `intl`; add Drift/go_router/clock/uuid; fix Windows path | — | reproducible lockfile | Arch |
| **K14 (P3)** Cleanup | AGENTS.md count, naming, MxButton/MxList/MxCard prose, glossary, screen count, Riverpod version/Mutations ADR | — | Correct counts/naming/prose; add glossary | — | consistent | various |

---

## L. Proposed patches (P0/P1 — not applied)

**Patch L-1 — `docs/design/MemoX Design System_v4/SCOPE.md:22` (CF-01, after ADR-001 = "Business wins"):**
```diff
-There is **no separate "Subdeck" model** — a "subdeck" is only a Deck one level down. A Deck
-holds nested decks (a `children` count) and/or cards. Hierarchy: **Library › Deck (→ nested Deck…)
+There is **no separate "Subdeck" model** — a "subdeck" is only a Deck one level down. A Deck holds
+**either** nested decks (a `children` count) **or** direct cards, **never both** (mixed content is
+invalid — see `docs/architecture/adr/ADR-001-deck-content-model.md` and `docs/business/deck/README.md`).
+Hierarchy: **Library › Deck (→ nested Deck…)
```

**Patch L-2 — `docs/business/learning-progress/schedule-next-review.md` §2 (P1-B03):** remove the middle row and SM-2 terminology.
```diff
-| correct | ... |
-| Partial/hard/almost | Conservative next schedule theo policy |
-| wrong | ... |
+| correct | Next box = min(box+1, 8); schedule per srs-8-box-policy §6 |
+| wrong   | Almost/timeout normalize to `wrong` (sticky) per srs-8-box-policy §4; next box = max(box-1, 1) |
+
+> Grades are binary (`correct`/`wrong`). There is no "partial/hard/conservative" path;
+> `srs-8-box-policy.md §4–§6` is the sole scheduling source.
```

**Patch L-3 — `.claude/hooks/guard_stop.py` & `.codex/hooks.json` (P1-D01, K3):** make hooks **fail-closed** when the guard submodule is absent (currently `guard_stop.py:60-66` exits 0), and replace the hardcoded `D:\workspace\memox_v6\...` Codex path with a repo-relative `python .codex/hooks/guard_stop.py`. (Exact diff deferred to the hook owner; behavior change: non-zero exit + message "guard submodule not initialized — run `git submodule update --init`".)

**Patch L-4 — `docs/wbs/memox-v6-development-wbs.md` §3.2 (P0-02, add DG-07):**
```diff
+| DG-07 | Study-mode model: single-mode Picker vs fixed five-stage pipeline? | `deck/study-deck.md:32,56` (Mode Picker; per-mode minimums) | `study-session/start-study-session.md:82` + `srs-8-box-policy.md:47-53` (all five required to activate) | Decide one model; if five-stage, make mode preferences ordering-only | `ADR-005-study-mode-model.md`, reconciled configure-mode-preferences + srs activation |
```

For P2/P3 the fixes are mechanical (counts, links, naming, prose, config pins, adding missing docs) and are described in §K rather than diffed here due to volume.

---

## M. Final readiness checklist

| Dimension | Verdict | Basis |
| --- | --- | --- |
| **Business readiness** | ✅ Strong, 1 internal conflict | 127/127 specs read; exemplary ownership catalog; only P0-02 mode model + B-03/B-02 to resolve |
| **Design readiness (phone-portrait)** | ✅ Ready by kit gate | 0 P0/P1 open; strong token discipline; 23 `Mx*` fully specced |
| **Design readiness (multi-platform)** | ⚠️ Not ready | 9 P1 responsive/adaptive items out-of-scope; RN framing; no Flutter token layer (P1-PLATFORM) |
| **Architecture readiness** | ⚠️ On-paper strong, artifacts absent | Best-practice contracts, but ADRs/decision-tables/schema/navigation docs don't exist (P1-TRACE); `lib/` greenfield |
| **Riverpod readiness** | ✅ Contract sound | Correct lifecycle/keepAlive/family/command rules; Mutations-ban should be an ADR (D-09) |
| **Guard readiness** | ⚠️ Inert locally | Submodule not checked out; hooks fail-open; DG-04 SRS-placement conflict (P1-D01/P1-DG04) |
| **Test readiness** | ❌ None | 1 starter test; SRS8/decision-table IDs unbacked (P1-TRACE) |
| **WBS readiness** | ✅ High, minor gaps | No dup IDs, strong DoD/gates; add DG-07, localization item, Group-16 deps, DoR (§H) |
| **Start-learning-flow readiness** | ⛔ Blocked | P0-02 mode model, P1-07 missing design states, P1-B02 due-review composition |
| **SRS readiness** | ✅ Strong | 18/21 conformance clean; consistent across business/design/WBS; fix B-03 + placement DG-04 |
| **Overall implementation readiness** | ⚠️ **Foundation: go · Features: blocked** | Start foundation after K3+K4+K8; start learning only after K1+K2 (P0 decisions) |

---

## Final answers

1. **Is the documentation sufficient to implement?** **Not for the learning features yet** — two P0 conflicts (deck content model, study-mode model) and the WBS's own mandatory preconditions (ADRs, decision-tables, an initialized guard) are unmet. It **is** sufficient to begin foundation work. The corpus quality is high; the blockers are a small number of specific, well-localized decisions and artifacts.

2. **What can be implemented right now?** The foundation: dependency baseline + verifier + bootstrap + deterministic infra (WBS 1), tokens→theme→responsive (WBS 2, under ADR-002), shared `Mx*` (WBS 3), and Clean-Architecture/persistence (WBS 4) — provided the guard is initialized (K3) and ADR-002/DG-04 are settled. SRS domain policy (5.4.3) is specification-ready and can be built test-first once DG-04 placement is fixed.

3. **What is blocked?** The start-learning feature slice (WBS 5.5–5.7): blocked on P0-02 (mode model), P0-01 (deck model, for 5.2/schema), P1-07 (missing design states), and P1-B02 (due-review composition). All UI at scale is blocked on the multi-platform adaptive gap (P1-PLATFORM) beyond the 390×780 baseline.

4. **What decisions must the Product Owner make first?** (a) **Deck content model** — mixed content invalid vs "and/or cards" (CF-01/DG-01). (b) **Study-mode model** — always-five-stages vs user-selectable (CF-02/new DG-07). (c) **Platform & adaptive scope** — Flutter multi-platform target + adaptive rules vs the phone-portrait kit (CF-03/DG-02). (d) **Guard↔architecture** — fix the guard upstream so SRS lives in domain (CF-04/DG-04). (e) Minor: is the Theme accent picker a live feature (CF-05)?

5. **Fastest quality-preserving path to "start learning":** Resolve the two P0 decisions and DG-02/DG-04 → write the WBS-0.5 governance doc-set + ADRs → initialize/fix the guard (fail-closed) → build foundation (Groups 1→2→ 3∥4) → add the missing graded-mode design states → deliver Group 5 in order (Language Pair → Deck → Flashcard → Progress+SRS → Study Mode → Study Session → Today) → ship at the 5.7.5 first-learning release gate. Correct `schedule-next-review.md`, pin `intl`, and add the localization foundation item along the way.
