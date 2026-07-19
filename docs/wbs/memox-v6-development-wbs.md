# MemoX v6 — Quy trình phát triển và WBS chi tiết

Trạng thái: baseline đã chấp nhận quyết định kiến trúc; feature vẫn tuân thủ DoR reconciliation
Phạm vi: ứng dụng Flutter local-first; Tier 1 Web + Android, các platform khác là roadmap

Ưu tiên: hoàn thiện hành trình học đầu tiên trước các capability thứ cấp
Nguồn chuẩn: `docs/business/**`, `docs/design/MemoX Design System_v4/**`, `docs/design/mobile-design-kit-audit-v5/**`, `AGENTS.md` của repo và ruleset guard `memox`

## 1. Kết quả mục tiêu

WBS này chuyển các contract nghiệp vụ và thiết kế hiện có thành chương trình bàn giao tăng dần. Mục tiêu của release đầu không phải một tập hợp màn hình rời rạc, mà là một hành trình hoàn chỉnh, an toàn khi app bị đóng/mở lại:

`Launch → create/select language pair → create deck → add cards → choose study scope/mode → complete all required study stages → persist attempts and next review → view result → start or resume from Today`.

Mỗi feature được bàn giao theo vertical slice xuyên suốt domain, use case, persistence, Riverpod state, UI, localization, test, visual evidence và tài liệu. Chỉ render được happy path không được tính là hoàn thành feature.

## 2. Phân tích 5Why

| Why | Root cause / constraint | Trade-off | Decision unlocked |
| --- | --- | --- | --- |
| 1. Why not start by coding the Study screen? | The repository is effectively greenfield: `lib/main.dart` is the starter counter app; theme, router, database, shared `Mx*` widgets and clean layers do not exist. | Foundation work delays the first visible feature, but skipping it guarantees rework and guard violations. | Build a thin but production-grade foundation before feature UI. |
| 2. Why must tokens/theme/responsive precede shared widgets? | The kit enforces `Token → Component → Screen`, while the guard rejects raw colors, spacing, radii, durations and many raw Material widgets. | Mapping all token families is larger than styling one screen. | Port the exact kit values and stable names into `lib/core/theme/**`, then build `Mx*` APIs on top. |
| 3. Why can the historical design kit not be copied literally? | Its original baseline was React Native, phone portrait and 390×780; the current rebaseline targets Flutter with Web + Android Tier 1. | Exact phone parity and adaptive large-screen behavior require two complementary contracts. | Keep 390×780 light/dark as the canonical visual baseline and use the centralized Flutter adaptive profile without changing frozen token/component/node names. |
| 4. Why is Clean Architecture not enough by itself? | The guard enforces additional concrete conventions: global `domain`/`data` roots, generated Riverpod, app-level DI, Drift/DAO boundaries, shared navigation wrappers and `Mx*` surfaces. The current guard also contains stale `Folder` paths and a data-layer-specific SRS rule. | Blindly following either a generic Clean Architecture template or stale guard paths creates drift. | Resolve guard conflicts first; use `Presentation → UseCase → Repository port → Repository impl → DAO`, with domain remaining pure Dart. |
| 5. Why prioritize one complete learning path instead of finishing all CRUD first? | User value starts when a learner can create content, study it, resume safely and receive a deterministic next due time. | Some broad library/settings features are deferred. | Put Language Pair, Deck, Flashcard, Progress, Study Mode, Session and Today on the critical path; deliver the remaining aggregates in dependency order afterward. |

## 3. Baseline và các decision gate bắt buộc

### 3.1 Baseline có bằng chứng

- Business catalog: use `docs/business/README.md` as the generated/current denominator; do not freeze a hand-maintained file count here.
- UI kit: 27 canonical screens and 215 canonical states; 23 documented `Mx*` component contracts.
- Current source: starter `main.dart`, ARB localization setup and Riverpod packages only.
- Current guard: 246 rules; the remediation run passes with 0 errors but 170 scaffold warnings, largely because expected architecture paths do not exist yet. `intl` is pinned; WBS 1.8 retires the remaining warnings as canonical paths become active.
- Accepted baseline artifacts now live under `docs/architecture`, `docs/database`, `docs/decision-tables` and `docs/traceability`; the consolidated verifier is active. Executable migration fixtures and the integration-test harness remain delivery outputs of this WBS.

### 3.2 Các gate phải dừng để quyết định

DG-01 through DG-06 are accepted by the Product Owner on 2026-07-18 through the ADRs below. A decision is not the same as source reconciliation: an affected feature remains blocked by Definition of Ready while owning business/design prose still contradicts the accepted ADR.

| ID | Accepted decision | ADR | Owner | Status/date | Required follow-up |
| --- | --- | --- | --- | --- | --- |
| DG-01 | A Deck contains direct cards or child Decks, never both. | `docs/architecture/adr/ADR-001-deck-content-model.md` | Product | Accepted · 2026-07-18 | Reconcile business/design prose and fixtures; preserve frozen identifiers. |
| DG-02 | Production is Flutter; Tier 1 is Web + Android; 390×780 remains compact parity baseline. | `docs/architecture/adr/ADR-002-platform-and-adaptive-scope.md` | Product / Architecture | Accepted · 2026-07-18 | Publish Tier-1/roadmap window/input/capability matrix. |
| DG-03 | New learning is five stages; due/relearn/practice are separate; SRS is fixed `leitner-8-box-v1`. | `docs/architecture/adr/ADR-003-learning-session-and-scheduling.md` | Product / Learning | Accepted · 2026-07-18 | Maintain decision rows and deterministic clock tests. |
| DG-04 | SRS transition math has one source at `lib/domain/learning_progress/srs_8_box_policy.dart`; data code only persists its result. | `docs/architecture/adr/ADR-003-learning-session-and-scheduling.md` | Architecture / Guard | Accepted · 2026-07-18 | Align guard upstream and pin the accepted rule. |
| DG-05 | v1 UI locales are en/vi; implementation is RTL-ready; CJK card content is tested. | `docs/architecture/adr/ADR-002-platform-and-adaptive-scope.md` | Product | Accepted · 2026-07-18 | Reconcile kit scope and add locale/pseudo-locale fixtures. |
| DG-06 | Web and Android share one Drift schema with platform-specific tested openers. | `docs/architecture/adr/ADR-004-local-persistence-platforms.md` | Product / Data | Accepted · 2026-07-18 | Select pinned opener dependencies and run the same repository suite. |

### 3.3 Bản đồ độ phủ business capability

| Business object/capability | WBS chính | Thứ tự |
| --- | --- | --- |
| Language Pair | 5.1 | Critical path |
| Deck | 5.2, 6.1–6.2 | Critical path rồi hoàn thiện lifecycle |
| Flashcard | 5.3, 6.3–6.5 | Critical path rồi hoàn thiện lifecycle |
| Learning Progress | 5.4 | Critical path |
| Study Mode | 5.5 | Critical path |
| Study Session | 5.6 | Critical path |
| Today Dashboard | 5.7, 7.3 | Critical path rồi enrich projection |
| Study Goal | 7.1, 7.3–7.5 | Wave ngay sau first-learning |
| Study Streak | 7.2–7.5 | Wave ngay sau first-learning |
| Preferences | 8.1–8.6 | Sau khi contract session/theme ổn định |
| Reminder | 9.1–9.4 | Sau Goal/Today và platform capability |
| Search | 10.1–10.4 | Sau Deck/Card lifecycle |
| Study Statistics | 11.1–11.3 | Sau Session/Progress/Streak ổn định |
| Audio Playback | 12.1–12.4 | Sau card audio và voice preference |
| Content Transfer | 13.1–13.4 | Sau target/content invariants ổn định |
| Account/Sync | 14.1–14.6 | Sau local data/migration/versioning ổn định |
| Backup | 15.1–15.5 | Sau schema và transfer/security contract |

## 4. Contract kiến trúc mục tiêu

### 4.1 Luồng dependency

```text
Flutter UI / route
    → generated @riverpod query or command provider
        → domain use case
            → domain repository port
                → data repository implementation
                    → Drift DAO / platform datasource

app/di → concrete database, DAO, repository, service and factory instances
data → domain
presentation → domain + shared presentation + core UI-safe APIs
domain → Dart SDK only
```

Transactions stay in data/database code. A use case requests one atomic repository operation; it does not open a Drift transaction itself. Widgets never import repositories, data sources, DAOs or platform IO.

### 4.2 Contract thư mục

| Folder | Responsibility | Allowed | Forbidden |
| --- | --- | --- | --- |
| `lib/app/` | Composition root | bootstrap, app widget, shell, router, route constants, navigation extension, app-level DI | business rules, feature widgets, DB queries |
| `lib/core/` | Cross-cutting technical foundation | theme/tokens/responsive, database opener, clock, IDs, errors, logging, utilities, platform services | feature workflows or domain entities |
| `lib/domain/` | Pure business model | entities, value objects, repository ports, use cases, policies and Study Mode contract | Flutter, Riverpod, Drift, data or presentation imports |
| `lib/data/` | Persistence/integration adapters | Drift tables, DAOs, mappers, repository implementations, migrations, file/device adapters | widgets, localized copy, provider state |
| `lib/presentation/shared/` | Frozen design-system and UI infrastructure | concrete `Mx*` widgets, layouts, dialogs, sheets, async/error surfaces, UI-only hooks | feature imports, navigation ownership, repositories or business rules |
| `lib/presentation/features/<feature>/` | Feature presentation | `screens`, `widgets`, `providers`, optional `routes` | data imports, raw DB/network/JSON/IO |
| `lib/l10n/` | Localized copy | ARB source files | generated output edits or hardcoded screen copy |
| `test/` | Unit/widget/golden/contract tests | mirrors source ownership | production runtime code |
| `integration_test/` | End-to-end user journeys | app/device flow tests | business logic implementation |
| `tool/` | Developer automation | one verifier, fixture/golden/schema helpers | app runtime code |

### 4.3 Cây source đề xuất

```text
lib/
├─ main.dart
├─ app/
│  ├─ app.dart
│  ├─ app_shell.dart
│  ├─ bootstrap/app_bootstrap.dart
│  ├─ di/app_providers.dart
│  └─ router/
│     ├─ app_router.dart
│     ├─ app_navigation.dart
│     ├─ route_names.dart
│     ├─ route_paths.dart
│     └─ registries/
├─ core/
│  ├─ theme/{tokens,responsive,extensions,component_themes}/
│  ├─ database/
│  ├─ errors/
│  ├─ logging/
│  ├─ time/
│  ├─ ids/
│  ├─ platform/
│  └─ utils/
├─ domain/
│  ├─ entities/
│  ├─ value_objects/
│  ├─ repositories/
│  ├─ usecases/<business_object>/
│  ├─ policies/
│  └─ study_modes/
├─ data/
│  ├─ database/{tables,daos,migrations}/
│  ├─ models/
│  ├─ mappers/
│  ├─ repositories/
│  └─ datasources/
├─ presentation/
│  ├─ shared/{widgets,layouts,dialogs,bottom_sheets,feedback,hooks,viewmodels}/
│  └─ features/<feature>/{screens,widgets,providers,routes}/
└─ l10n/
```

Do not create per-feature `domain/data/presentation` triplets. The repository guard is built around app-wide domain/data roots and feature-owned presentation roots.

## 5. Quy tắc triển khai Riverpod, persistence và UI

### 5.1 Contract Riverpod Annotation v3

- Declare every provider with `@riverpod` or `@Riverpod`; never use manual `Provider`, `StateProvider`, `FutureProvider`, `StateNotifierProvider` or `ChangeNotifierProvider` constructors.
- Use `@Riverpod(keepAlive: true)` for app-wide infrastructure: database, DAO, repository, clock, codec, platform service and Study Mode factory.
- Use auto-dispose generated families for screen/query state keyed by stable IDs. Provider parameters must have stable equality.
- Use generated class-based `Notifier`/`AsyncNotifier` for commands and mutable presentation orchestration; expose semantic methods such as `createDeck`, `saveCard`, `submitAnswer`.
- UI watches state in `build`; callbacks call `ref.read(provider.notifier)` only. Never call `ref.watch` inside callbacks.
- Provider files contain no `BuildContext`, `WidgetRef`, snackbar, dialog or navigation call. UI side effects are emitted as typed events and handled with `ref.listen`.
- Presentation commands depend on use-case providers, never repository providers. Prefer narrow provider refresh/update over broad invalidation.
- Use `ref.onDispose` for timers/subscriptions and `ref.mounted` after awaited work. Recall timing is driven by an injected clock/timer port, not a widget timer.
- Render async state through the shared `AppAsyncBuilder`/MemoX equivalent required by the guard, with retained skeleton/data where the state contract demands it.
- Do not adopt Riverpod experimental Mutations in the baseline; the guard and architecture already standardize command notifiers.
- Generated `*.g.dart`/`*.freezed.dart` files are regenerated locally and never committed.

### 5.2 Contract Drift

- Drift is the local canonical source; open it off the main isolate on native/desktop and use the approved web opener on web.
- Store instants in UTC and convert through an injected timezone/clock boundary. Persist local-date and timezone snapshots where Goal/Streak contracts require them.
- Every aggregate has a DAO; UI/providers do not call DAOs. Cross-table atomic operations live in repository implementations or a data-layer transaction coordinator.
- Export a schema snapshot for each schema version; generate and run migration tests from every supported version.
- Use stable IDs and idempotency keys for create-card, start-session, attempt, finalize, projection and import operations.
- Store secrets in secure storage, never SharedPreferences or plain Drift columns. SharedPreferences is limited to explicitly non-sensitive lightweight app settings and is created only by app DI.
- Repository methods state read source, transaction boundary, ordering and idempotency behavior.

### 5.3 Contract responsive và adaptive

The 390×780 kit remains the pixel-parity baseline. The Flutter layout branches by available window width, not by device label or orientation.

| Class | Width | Navigation/layout intent | Required test widths |
| --- | ---: | --- | --- |
| Compact mobile density | `<430` | Bottom nav, single pane, reduced spacing density without reducing touch targets | 320, 360, 390, 412 |
| Compact | `<600` | Bottom nav, single pane | 599 |
| Medium | `600–839` | Rail or compact two-region layout when useful | 600, 768, 839 |
| Expanded | `840–1199` | Navigation rail, constrained content, optional list/detail | 840, 1024, 1199 |
| Large | `≥1200` | Rail/sidebar, centered max-width content, no stretched phone surfaces | 1200, 1440, 1920 |

All exact values live in `core/theme/responsive`; features consume `context.screenClass`, `context.spacing`, `context.component` and `context.layout`. Study/card/dialog surfaces receive explicit max-width tokens. Text scaling remains enabled and is tested at 1.0, 1.3 and 2.0. Keyboard, mouse, trackpad, focus traversal, safe areas, resizing and state restoration are first-class acceptance cases.

## 6. Definition of Ready và quy trình bàn giao

### 6.1 Definition of Ready

A work package may move to `Ready` only when all conditions are true:

1. Owner and domain resolve through `docs/traceability/work-item-register.md`.
2. Its dependency cells resolve only to unique WBS/milestone IDs and every dependency is Done.
3. Required ADR/decision gates are Accepted; owning business/design sources have no unresolved conflict for the item.
4. Inputs, output boundary, `AC-WBS-<id>-01`, test approach and required fixtures are linked.
5. Relevant design screens/KIT gates and guard rules are identified; exceptions have owner, expiry and approval.
6. Persistence work names schema version, transaction, idempotency and migration impact; time-sensitive work names the injected clock/timezone contract.
7. The item is small enough for independent review; an XL wave has child evidence boundaries before implementation starts.
8. Every implementation item links a conforming
   [implementation packet](./implementation-packets/README.md) with exact
   create/modify files, symbols, test files, evidence and out-of-scope.

### 6.2 Current implementation readiness

The WBS is executed sequentially; `Ready` is never assigned to descendants
whose dependencies are not Done.

| Status | WBS | Reason / next action |
| --- | --- | --- |
| Done | `0.1–0.6`, `1.1–1.6`, `1.9`, `2.1–2.10`, `3.1–3.7`, `3.9–3.10`, `4.1` | Durable evidence is in the work-item register. Wave 2 (token→theme→responsive) is closed. |
| Blocked | All remaining implementation rows | Preserve dependency order; create/review the item packet immediately before promotion. Gates 4.10 and 3.12 PASSED (2026-07-19). 5.1 block complete (2026-07-19). 5.2 Deck block complete (2026-07-19). PROCESS RULE (owner, 2026-07-19): no screen-changing PR merges without kit-parity evidence <3% (item `3.15`). Next: `3.15` retro coverage (landing, library-empty, step1, step2 enforced 2026-07-19; library loaded + empty-deck + subdeck + dialog states next), then `5.3.1` children B/C. |

Sequencing note (2026-07-19): `1.7` (developer fixtures) and `1.10` (shared
test infrastructure) declare only wave-1 dependencies, but their deliverables
(paused-session/due-card seeds, in-memory Drift and opener harness) require
the database layer from `4.1+`. Their packets are deferred until those inputs
exist; the `4.10` foundation gate — which requires `1.8–1.11` — still holds.
The token→theme stream (`2.x`) proceeds first as the active vertical slice.

For an XL row, the packet must split child boundaries even when the stable WBS
ID remains unchanged. This keeps dependency IDs stable while allowing one
independently reviewable child at a time.

### 6.3 Feature delivery sequence

Every feature work package follows FD-01 through FD-16. A PR may complete one or more consecutive steps, but no step is silently skipped.

| ID | Activity | Required output / exit condition |
| --- | --- | --- |
| FD-01 | Reconcile contract | Read owning business flow, linked objects, UI spec/shots and relevant KIT groups; no unresolved business↔design divergence. |
| FD-02 | Build traceability row | Map business acceptance criteria → decision-table rows → use cases → UI states → test IDs → evidence paths. |
| FD-03 | Define state/action matrices | Happy, loading, empty, invalid, submitting, recoverable failure, success, offline, stale/concurrent, long text, large text, compact/wide and light/dark. |
| FD-04 | Define domain model | Entity/value-object invariants, typed commands/results/errors, idempotency keys, clock and policy version. |
| FD-05 | Define persistence change | Tables/columns/indexes/constraints, transaction boundary, schema version, migration and rollback/repair behavior. |
| FD-06 | Implement domain | Pure-Dart use cases/policies/ports with unit and decision-table tests. |
| FD-07 | Implement data | Drift DAO, mapper and repository implementation with in-memory DB/repository/migration tests. |
| FD-08 | Wire DI | Generated app-level providers; infrastructure keep-alive; no direct construction in widgets. |
| FD-09 | Implement presentation state | Generated query/command providers, immutable state, narrow refresh and typed effects/errors. |
| FD-10 | Implement shared gap first | Reuse existing `Mx*`; add a shared variant only when the kit contract supports it; document any new shared API. |
| FD-11 | Implement feature UI | Compose from shared widgets; no raw visual values or business logic; all copy through ARB. |
| FD-12 | Verify interaction/accessibility | Focus order, semantics, 48px target baseline, non-color cues, keyboard/back/dismiss, reduced motion and announcements. |
| FD-13 | Verify responsive/visual parity | Canonical 390×780 light/dark golden under 3% where a reference exists; adaptive review at the window matrix. |
| FD-14 | Run automated tests | Domain, repository, provider, widget and targeted integration tests; row-to-test parity for each decision table. |
| FD-15 | Run repository gate | One consolidated verifier should run format, l10n, codegen, guard, analyze and targeted/full tests; no relevant warning or failure is ignored. |
| FD-16 | Close documentation | Update business/navigation/schema/migration/decision-table/WBS traceability docs and attach KIT evidence; no open P0/P1. |

The deterministic acceptance and test IDs, prefix owners and source inheritance
rules are defined in `docs/traceability/work-item-schema.md`. No item is Done
without updating its register evidence.

## 7. WBS chi tiết

Sizing is relative (`S`, `M`, `L`, `XL`) and is not a calendar estimate. A work package is independently reviewable and testable. `CP` marks the critical path to the first complete learning release.

### 0. Governance và đồng bộ contract

| WBS | Work package | Size | Depends on | Deliverable / Definition of Done |
| --- | --- | --- | --- | --- |
| 0.1 CP | Reconcile accepted DG-01 Deck model | M | — | ADR-001 is accepted; business/design prose and fixtures agree; mixed-content decision table exists. |
| 0.2 CP | Publish accepted DG-02/05 platform scope | M | — | ADR-002 Tier-1 Web+Android and en/vi/RTL-ready window/input/parity matrix is linked from owning docs. |
| 0.3 CP | Freeze accepted SRS Policy v1 | M | — | ADR-003 and `leitner-8-box-v1` decision rows SRS8-001..028 agree; canonical math path is `lib/domain/learning_progress/srs_8_box_policy.dart`; UTC deterministic contract tests are specified. |
| 0.4 CP | Align guard upstream | L | 0.1, 0.3 | Old `folders` paths removed/replaced with Deck paths; SRS rule permits the approved domain policy; submodule pin updated. |
| 0.5 CP | Establish documentation set | M | 0.1–0.4 | `docs/architecture`, `docs/decision-tables`, `docs/business/navigation`, `docs/database`, `docs/traceability`, ADR index and work-item register are linked and pass docs validation. |
| 0.6 | Define release scope/exceptions | S | 0.2 | Explicit v1 locales, platforms, RTL/high-contrast/cloud exclusions, owners and revisit targets. |

### 1. Baseline kỹ thuật và verification

| WBS | Work package | Size | Depends on | Deliverable / Definition of Done |
| --- | --- | --- | --- | --- |
| 1.1 CP | Dependency baseline | M | 0.4 | Execute [WBS-1.1 packet](./implementation-packets/WBS-1.1-dependency-baseline.md): approved direct manifest in `pubspec.yaml`, reproducible `pubspec.lock`, no disallowed dependency source, full verifier pass. |
| 1.2 CP | Consolidated verifier | L | 0.4 | `tool/verify/run.mjs` or equivalent owns pub-get/l10n/codegen/format/guard/analyze/tests and emits a pass marker; CI/hooks call the same entry. |
| 1.3 CP | App bootstrap | M | 1.1 | `main.dart` contains only bootstrap; ProviderScope, error zones, lifecycle and app widget are wired. |
| 1.4 CP | Router skeleton | L | 1.1 | RouteNames/RoutePaths, navigation extension, app router, feature route registries and empty shell routes; no raw route strings. |
| 1.5 CP | Error and observability pipeline | L | 1.3 | Typed AppFailure mapping, redacted logger, Flutter/platform async error capture and user-safe error presentation. |
| 1.6 CP | Deterministic infrastructure | M | 1.3 | Clock/timezone, ID/idempotency and deterministic random/shuffle ports with test fakes. |
| 1.7 | Developer fixtures | M | 1.3 | Seed/reset commands for empty, minimum, dense, error, paused-session and due-card states; never shipped in release mode. |
| 1.8 | Raise guard profile | S | 1.1–1.7 | Active source paths have no stale-target warnings; CI moves from `local` toward `ci` after approved cleanup. |
| 1.9 CP | Localization foundation | M | 1.1, 0.6 | en/vi ARB generation, locale-aware number/date/plural formatting, expansion/CJK fixtures, RTL-ready direction contract and localized test wrapper. |
| 1.10 CP | Shared test infrastructure | L | 1.1–1.7 | Fake clock/IDs/random/repos, ProviderContainer overrides, in-memory Drift, Tier-1 opener contract harness, widget/golden wrappers and restart/E2E fixtures. |
| 1.11 CP | Riverpod foundation | M | 1.3, 1.6, 1.10 | Generated provider lifecycle/family/keepAlive rules, command/effect pattern, cancellation/invalidation/retry contract and override tests. |

### 2. Nền tảng thiết kế: token → theme → responsive

| WBS | Work package | Size | Depends on | Deliverable / Definition of Done |
| --- | --- | --- | --- | --- |
| 2.1 CP | Token inventory/mapping manifest | L | 0.2, 1.1 | Every CSS token has a Dart owner and source path; missing/duplicate/additive-only checks; no renamed frozen token. |
| 2.2 CP | Color and opacity tokens | M | 2.1 | Semantic light/dark roles, state layers and visualization colors mapped exactly; contrast evidence. |
| 2.3 CP | Typography/font tokens | M | 2.1 | Plus Jakarta Sans assets registered; semantic roles/weights/tracking/line heights mapped; Vietnamese/CJK fallback tested. |
| 2.4 CP | Spacing/size/radius/stroke/elevation tokens | L | 2.1 | 4px rhythm and all component/layout roles mapped without raw literals above token layer. |
| 2.5 CP | Motion/icon tokens | M | 2.1 | Duration/easing/reduced-motion, icon size/weight and Material Symbols mapping contract. |
| 2.6 CP | Theme extensions/accessors | L | 2.2–2.5 | Dimension and semantic color/text contracts; token-only core with no Riverpod. |
| 2.7 CP | Theme assembly | L | 2.6 | Material 3 light/dark ThemeData, component themes, system UI appearance and runtime theme mode. |
| 2.8 CP | Responsive foundation | XL | 2.7 | ScreenInfo/Class, compact-mobile density, adaptive family values, content width caps, grid/pane rules and resize tests. |
| 2.9 | High-contrast readiness | M | 2.7, 0.6 | Either implemented and tested or explicitly deferred with no false support claim. |
| 2.10 CP | Foundation contract tests | L | 2.2–2.9 | Token-value tests, theme completeness, no raw value scans and responsive snapshots at all width classes. |

Relevant audit groups: KIT-02–13, KIT-32–39, KIT-42, KIT-48.

### 3. Hệ thống presentation dùng chung `Mx*`

Build components in dependency order. Each public shared type has guard-required documentation: summary, purpose, use-when, do-not-use-when, category, public API, variants and states.

| WBS | Work package | Size | Depends on | Deliverable / Definition of Done |
| --- | --- | --- | --- | --- |
| 3.1 CP | Shared text/icon/tappable foundation | L | 2.10 | `MxText`, icon adapter, shaped/focused tappable semantics and spacing helpers. |
| 3.2 CP | `MxButton` family | L | 3.1 | Primary/secondary/outline/ghost/destructive/icon/loading/disabled states; touch/focus tests. |
| 3.3 CP | `MxTextField` and form foundation | XL | 3.1 | Label/help/error, validation, controller/focus hooks, keyboard/autofill, multiline and long-text states. |
| 3.4 CP | `MxCard`, list and surface primitives | XL | 3.1 | Card variants, list rows, icon tiles, section headers, dividers and semantic tap behavior. |
| 3.5 CP | `MxScaffold` and content shells | XL | 2.10, 3.1 | App bar/body/nav/FAB slots, safe areas, retained composition, constrained study/form/detail layouts. |
| 3.6 CP | Navigation primitives | L | 3.2, 3.5 | Contextual app bar, bottom nav, rail adaptation, FAB, icon buttons and search dock. |
| 3.7 CP | First-learning feedback primitives | L | 3.2–3.5 | Progress, banner, loading/error/offline, dialog and sheet states required by create/start/study/retry. |
| 3.8 | Selection/control primitives | L | 3.1–3.4 | Chip, segmented control, switch, badge, avatar and link with full state matrices. |
| 3.9 CP | Async/action infrastructure | L | 3.7 | `AppAsyncBuilder`, action runner, typed effect listener, `MxAsyncDraft` and retry surfaces aligned with guard rules. |
| 3.10 CP | First-learning shared composites | L | 3.2–3.9 | ConfirmDialog, SelectSheet, ActionCallout, breadcrumb and study prompt patterns; feature-free APIs. |
| 3.11 | Full component golden/a11y catalog | XL | 3.1–3.10, 3.13–3.14 | Full variant × state × theme matrix, 390 baseline goldens, text-scale/focus/semantics tests, no open P0/P1. |
| 3.12 CP | Minimal `Mx*` first-learning gate | L | 3.1–3.10, 4.10 | Only APIs/states used by Language Pair→Deck→Card→Picker→five stages→Result are documented and pass widget/golden/a11y tests; later catalog variants do not block this gate. |
| 3.13 | Feedback expansion | L | 3.7 | Snackbar service, skeleton, generic empty states and menu variants not required by the first-learning gate. |
| 3.14 | Shared composite expansion | L | 3.10 | StatusCardRow and post-first-learning composites with feature-free APIs. |
| 3.15 CP | Kit visual parity gate | L | 3.12 | Pre-merge rule: every changed screen state compares against its kit shot (390, light+dark) with <3% pixel diff; retro coverage of shipped screens. |

Relevant audit groups: KIT-15–22, KIT-28–31, KIT-40–43, KIT-47–48.

### 4. Nền tảng Clean Architecture cho data/domain

| WBS | Work package | Size | Depends on | Deliverable / Definition of Done |
| --- | --- | --- | --- | --- |
| 4.1 CP | Database runtime | L | 0.2, 1.1, 1.6 | One shared Drift schema opens through tested Web and Android adapters, off the UI isolate where applicable, with close/lifecycle tests. |
| 4.2 CP | Schema v1 design | XL | 0.1, 0.3 | Tables/relations/indexes for language pairs, decks, cards/children, progress, sessions/snapshots/checkpoints/attempts and policy versions. |
| 4.3 CP | Schema constraints | L | 4.2 | Stable IDs, unique sibling names/pairs/attempt keys, foreign keys and deletion policies; mixed-content invariant enforced transactionally. |
| 4.4 CP | DAO layer | XL | 4.2–4.3 | One responsibility per DAO; paged/stream queries; no raw SQL outside data/database paths. |
| 4.5 CP | Mapper/model layer | L | 4.2 | Explicit DB↔domain mapping, enum/version fallback and corruption errors; no domain dependence on Drift rows. |
| 4.6 CP | Repository ports/implementations | XL | 4.4–4.5 | UseCase→Repository→DAO flow, atomic cross-table methods and repository contract tests. |
| 4.7 CP | Migration system | L | 4.2 | Exported schema v1, guided migration structure, integrity/rollback tests and fixture database policy. |
| 4.8 CP | App DI graph | L | 1.11, 4.1–4.7 | Keep-alive generated providers for DB/DAO/repos/services; startup fail-fast graph test. |
| 4.9 | Performance baseline | M | 4.4–4.6 | Query plans/index checks, pagination/stream limits, dense-library fixtures and latency/memory budgets. |
| 4.10 CP | Architecture/data foundation gate | L | 0.5, 1.2–1.6, 1.8–1.11, 2.10, 4.1–4.8 | Accepted docs/traceability, verifier, bootstrap/error/router, Riverpod/l10n/test harness, Tier-1 Drift contracts and foundation tests all pass before feature UI begins. |

Minimum schema groups for the first-learning release:

- `language_pairs`
- `decks` (`parent_id`, `language_pair_id`; content kind is derived, not a persistent mode)
- `flashcards`, `flashcard_translations`, `tags`, `flashcard_tags`, `card_audio_refs`
- `learning_progress`, `study_attempts`
- `study_sessions`, `study_session_cards`, `study_checkpoints`, `study_round_orders`, `session_relearn_items`
- `preferences`
- `daily_goals`, `goal_day_progress`, `streak_days` may land in the first-follow-up migration if Result/Today initially omit them by an approved state contract.

### 5. Critical path: hành trình học hoàn chỉnh đầu tiên

No work package below is accepted as “complete” without applying FD-01–FD-16.

#### 5.1 Language Pair

| WBS | Work package | Size | Depends on | Completion boundary |
| --- | --- | --- | --- | --- |
| 5.1.1 CP | Language Pair domain/data | L | 4.10 | Create/select/list, duplicate normalization, stable identity and Deck dependency guard. |
| 5.1.2 CP | First-run language UI | L | 3.12, 5.1.1 | Two required selectors, search/long-name/validation/save-failure/draft states in en/vi. |
| 5.1.3 CP | Language Pair tests/evidence | M | 5.1.2 | Unit/repo/provider/widget/E2E coverage; light/dark and adaptive evidence. |

#### 5.2 Deck core

| WBS | Work package | Size | Depends on | Completion boundary |
| --- | --- | --- | --- | --- |
| 5.2.1 CP | Deck entity and state derivation | L | 0.1, 5.1.1 | Empty/Leaf/Parent derived deterministically; cycle/pair/mixed-content invariants. |
| 5.2.2 CP | Create Deck transaction | L | 5.2.1 | Root/nested create, sibling uniqueness, retry idempotency, no automatic content. |
| 5.2.3 CP | First-run landing + two-step setup | XL | 3.12, 5.1.2, 5.2.2 | Landing/Not-now/import handoff, step drafts, submitting/failure/success/callout states. |
| 5.2.4 CP | Library and open Deck | XL | 5.2.2 | Root list, Empty/Leaf/Parent branching, loading/error/offline/dense/deep/long-name states. |
| 5.2.5 CP | Empty Deck content choice | M | 5.2.4 | Add card/create child/import actions exactly follow the selected content model. |
| 5.2.6 CP | Deck tests/evidence | L | 5.2.3–5.2.5 | Decision tables, transaction/property tests, provider/widget/golden/E2E coverage. |

#### 5.3 Flashcard creation

| WBS | Work package | Size | Depends on | Completion boundary |
| --- | --- | --- | --- | --- |
| 5.3.1 CP | Flashcard domain/data | XL | 5.2.6 | Required multilingual content, duplicate candidate query, atomic Card+initial Progress+Deck transition. |
| 5.3.2 CP | Card Editor | XL | 3.12, 5.3.1 | Default/validation/duplicate/submitting/failure/dirty-discard/stale-target/keyboard states. |
| 5.3.3 CP | Flashcard list/minimum management | L | 5.3.2 | List, open/add, minimum/dense/loading/empty/error; enough editing access to build a valid study scope. |
| 5.3.4 CP | Creation tests/evidence | L | 5.3.1–5.3.3 | Atomic rollback/idempotency, draft/provider/widget/golden and first-run E2E tests. |

#### 5.4 Learning Progress and SRS

| WBS | Work package | Size | Depends on | Completion boundary |
| --- | --- | --- | --- | --- |
| 5.4.1 CP | Initial progress | M | 0.3, 5.3.1 | Idempotent New state and repair behavior; no orphan progress. |
| 5.4.2 CP | Due/new/relearn query policy | L | 5.4.1 | Unique scoped queues, hidden/deleted exclusion, parent aggregation, new-card limits and boundary tests. |
| 5.4.3 CP | Leitner 8 Box policy implementation | XL | 0.3, 5.4.1 | The sole pure-domain implementation is `lib/domain/learning_progress/srs_8_box_policy.dart`: Box 0 activation; Box 1..7 intervals 1/3/7/14/30/60/120; Box 8 mastered; correct +1, sticky-wrong -1. |
| 5.4.4 CP | Attempt/schedule transaction | XL | 5.4.3 | Exactly-once terminal scheduling; concurrent outcome conflict; atomic Attempt+Progress update. |
| 5.4.5 CP | Progress tests | XL | 5.4.2–5.4.4 | Full policy decision table, property/boundary/timezone/idempotency/repository/migration tests. |

#### 5.5 Study Mode engine

| WBS | Work package | Size | Depends on | Completion boundary |
| --- | --- | --- | --- | --- |
| 5.5.1 CP | Canonical mode/evidence model | L | 5.4.5 | One enum for Review/Match/Guess/Recall/Fill/SRS Binary Review, typed input/evidence/outcome/metadata and no UI/data types. |
| 5.5.2 CP | Pure strategy template | L | 5.5.1 | Mandatory domain-only validate→evaluate→map template; no Attempt persistence, checkpoint, navigation, Riverpod or Drift. |
| 5.5.3 CP | Deterministic shuffle/round policy | L | 1.6, 5.5.2 | Mode/round seed, collision resolution, persisted orders and resume stability. |
| 5.5.4 CP | Six concrete strategies | XL | 5.5.2–5.5.3 | Review, Match, Guess, Recall, Fill and session-only SRS Binary Review implement only pure hooks/evidence rules. |
| 5.5.5 CP | Mandatory StudyModeFactory + DI | L | 5.5.4 | Exhaustive enum→strategy resolution; exactly one instance per id; missing/duplicate/unknown fail fast; app-level generated provider injects the factory; Session depends only on factory. |
| 5.5.6 CP | Mode/factory contract tests | XL | 5.5.5 | Shared tests over six strategies plus exhaustive factory resolution, Guess five-options, Recall 20s race, binary self-grade, Fill normalization and Match classification. |

#### 5.6 Study Session engine and UI

| WBS | Work package | Size | Depends on | Completion boundary |
| --- | --- | --- | --- | --- |
| 5.6.1 CP | Mode picker and eligibility | L | 5.3.4, 5.4.2 | Leaf/subtree scope, hidden/due/new counts, mode minimums and Guess distinct-meaning check. |
| 5.6.2 CP | Start session snapshot | XL | 5.5.6, 5.6.1 | Exactly one active session; stable card/content/preferences/mode-plan/pool/order snapshot; Due uses binary plan and Relearn snapshots Guess or binary fallback; no orphan start. |
| 5.6.3 CP | Session command provider | XL | 5.6.2 | Immutable state/checkpoint orchestration; typed effects/errors; no repository access from UI. |
| 5.6.4 CP | Shared study shell | L | 3.12 | Constrained progress/header/prompt/action/error composition across all stages and widths. |
| 5.6.5 CP | Review UI | L | 5.6.3–5.6.4, 5.6.10 | Browse/audio/edit handoff/loading/error/end states through the durable answer boundary. |
| 5.6.6 CP | Match UI | XL | 5.6.3–5.6.4, 5.6.10 | Playing/selected/correct/wrong/almost/round-complete/retry states with non-color cues. |
| 5.6.7 CP | Guess UI | L | 5.6.3–5.6.4, 5.6.10 | Exactly five distinct-meaning choices, one correct, invalid-pool recovery and long-text states. |
| 5.6.8 CP | Recall UI | XL | 5.6.3–5.6.4, 5.6.10 | Reveal, remembered/forgot, injected 20s timer, pause/resume and deadline/tap race behavior. |
| 5.6.9 CP | Fill UI | XL | 5.6.3–5.6.4, 5.6.10 | Keyboard, hint, compare, correct/wrong/retry and multilingual input states. |
| 5.6.10 CP | Durable answer persistence/recovery | XL | 5.6.2–5.6.3 | Production command boundary exists before mode UI completion: attempt saved before advance; retry same key; stale writer blocked; answer-save-error retains evidence. |
| 5.6.11 CP | Mastery rounds and relearn | XL | 5.6.5–5.6.10 | Failed set deduped, unlimited retry rounds, separate persistence retry/relearn namespaces. |
| 5.6.12 CP | Exit/pause/resume | XL | 5.6.11 | Committed progress safe, uncommitted input truthful, Recall remaining time/order/failed set restored. |
| 5.6.13 CP | Finalize/result | XL | 5.6.11 | Idempotent completion/summary/contribution events, finalize retry, result branches and return route. |
| 5.6.14 CP | Study test pyramid | XL | 5.6.2–5.6.13 | Contract, repository, provider, fake-clock, widget/golden and interruption/restart E2E tests; durable-answer, Recall 20s and exactly-once terminal scheduling rows all have test IDs. |

#### 5.7 Today learning entry

| WBS | Work package | Size | Depends on | Completion boundary |
| --- | --- | --- | --- | --- |
| 5.7.1 CP | Today read projection | L | 5.4.2, 5.6.13 | Composes due/new/relearn and paused session without owning source calculations. |
| 5.7.2 CP | Today states | XL | 3.12, 5.7.1 | Empty library, not studied, due, paused, caught-up, loading/error/offline and create sheet. |
| 5.7.3 CP | Start/continue handoffs | L | 5.6.12, 5.7.2 | Revalidates before navigation; paused session outranks new review. |
| 5.7.4 CP | First-learning release E2E | XL | 5.1.3, 5.2.6, 5.3.4, 5.4.5, 5.5.6, 5.6.14, 5.7.3 | Fresh install → 5 valid cards → picker/CTA → all five new-learning stages → result → due state; force-close/resume and offline Web/Android variants. |
| 5.7.5 CP | First-learning release gate | L | 0.5, 1.2, 1.5, 1.8, 3.12, 4.10, 5.7.4 | Consolidated verifier passes; study test pyramid is complete; no audit P0/P1; canonical parity and Tier-1 Web/Android smoke evidence attached. |

### 6. Hoàn thiện quản lý nội dung và Library

Deliver in this order because later capabilities depend on stable Deck/Card lifecycle events.

| WBS | Complete feature slice | Size | Depends on | Included business flows |
| --- | --- | --- | --- | --- |
| 6.1 | Deck metadata/lifecycle | XL | 5.7.5 | edit, move, delete, reset progress with impact/confirm/recovery. |
| 6.2 | Nested Deck navigation | XL | 6.1 | browse deep hierarchy, breadcrumb, reparent/cycle guard, empty transitions. |
| 6.3 | Flashcard edit and duplicate | XL | 6.1 | edit draft, duplicate review/keep/merge decision. |
| 6.4 | Flashcard translations/tags/audio refs | XL | 6.3 | add/edit/reorder/remove translations, tags and card audio asset lifecycle. |
| 6.5 | Flashcard move/hide/delete | XL | 6.3 | atomic target move, eligibility refresh, hide/show and destructive delete. |
| 6.6 | Library selection/bulk actions | XL | 6.1–6.5 | selection entry/exit, tri-state select all, filtered hidden selection, partial outcomes. |
| 6.7 | Content/library E2E gate | L | 6.1–6.6 | Dense/deep/long-text/offline/concurrency flows and visual evidence pass. |

### 7. Goal, streak và Today/Result đầy đủ hơn

| WBS | Complete feature slice | Size | Depends on | Completion boundary |
| --- | --- | --- | --- | --- |
| 7.1 | Daily Goal | XL | 5.6.13 | set/disable, local-day contribution, one-time completion, timezone rollover. |
| 7.2 | Study Streak | XL | 5.6.13 | qualified day, current/longest, break and timezone/DST reconciliation. |
| 7.3 | Today projection enrichment | L | 7.1–7.2 | Goal/streak cards consume committed projections only. |
| 7.4 | Study Result enrichment | L | 7.1–7.2 | Goal met/missed and streak feedback without duplicate events. |
| 7.5 | Goal/streak E2E gate | L | 7.3–7.4 | Midnight, timezone, retry-finalize and large-count evidence. |

### 8. Preferences và Settings

| WBS | Complete feature slice | Size | Depends on | Completion boundary |
| --- | --- | --- | --- | --- |
| 8.1 | Appearance preference | M | 2.7 | System/light/dark globally applied and persisted; invalid fallback. |
| 8.2 | Study/SRS preferences | L | 0.3, 5.6.14 | Defaults validated and snapshotted only into new sessions. |
| 8.3 | Mode preferences | L | 5.5.6 | Availability/default/order constraints without breaking required stages. |
| 8.4 | Word display preferences | M | 6.4 | Presentation-only effects, no history rewrite. |
| 8.5 | Voice preferences | M | 6.4 | Valid voice/speed defaults and missing capability fallback. |
| 8.6 | Restore defaults/settings hub | L | 8.1–8.5 | Impact summary, confirm, atomic reset and recovery. |

### 9. Reminder

| WBS | Complete feature slice | Size | Depends on | Completion boundary |
| --- | --- | --- | --- | --- |
| 9.1 | Notification platform boundary | L | 0.2, 8.1 | Capability/permission adapter per supported platform; denied/blocked matrix. |
| 9.2 | Reminder schedule | XL | 9.1 | enable/edit/disable, atomic reschedule, timezone/DST and no duplicate notifications. |
| 9.3 | Notification entry | M | 5.7.5, 9.2 | Tap navigates to current learning entry and revalidates; never auto-starts Study. |
| 9.4 | Reminder E2E gate | L | 9.1–9.3 | Permission/system-settings/time-change/stale-target evidence. |

### 10. Search

| WBS | Complete feature slice | Size | Depends on | Completion boundary |
| --- | --- | --- | --- | --- |
| 10.1 | Search index/read model | XL | 6.7 | Deterministic Deck/Card indexing and create/edit/move/delete invalidation. |
| 10.2 | Query/filter/recent | XL | 10.1 | Blank/recent/loading/results/no-results/error, filters and privacy policy. |
| 10.3 | Open result/navigation preservation | L | 10.2 | Stable identity/path resolution, stale result recovery, preserve/reset rules. |
| 10.4 | Search E2E gate | L | 10.1–10.3 | Multilingual/dense/stale/offline/keyboard/adaptive evidence. |

### 11. Thống kê học tập

| WBS | Complete feature slice | Size | Depends on | Completion boundary |
| --- | --- | --- | --- | --- |
| 11.1 | Versioned statistics projection | XL | 5.4.5, 7.2 | No double-count, parent aggregation, formula/time-range versions and rebuild. |
| 11.2 | Statistics UI | XL | 11.1 | Summary, retention, heatmap, trends, scope switch, insufficient/loading/error states. |
| 11.3 | Projection reconciliation gate | L | 11.1–11.2 | Reset/late event/timezone/large data and visual/performance evidence. |

### 12. Phát audio

| WBS | Complete feature slice | Size | Depends on | Completion boundary |
| --- | --- | --- | --- | --- |
| 12.1 | Audio queue/player domain | XL | 6.4, 8.5 | Stable queue snapshot, controls/speed, no Progress mutation. |
| 12.2 | Platform audio lifecycle | XL | 12.1 | Focus/interruption/background/headphone behavior and recoverable position. |
| 12.3 | Player UI/error recovery | L | 12.1–12.2 | playing/paused/speed/error/end/no-audio states. |
| 12.4 | Audio E2E gate | L | 12.1–12.3 | Interruption/missing asset/background/platform capability evidence. |

### 13. Import/Export nội dung

| WBS | Complete feature slice | Size | Depends on | Completion boundary |
| --- | --- | --- | --- | --- |
| 13.1 | Import source/parser/mapping | XL | 6.7 | File/paste permissions, typed parser errors, required mapping and retained configuration. |
| 13.2 | Import preview/dedup/commit | XL | 13.1 | Flat/hierarchy preview, invalid rows, duplicate plan and atomic/idempotent commit. |
| 13.3 | Export snapshot/generation/share | XL | 6.7 | Consistent scope snapshot, supported formats, file generation and share-only recovery. |
| 13.4 | Transfer stress/security gate | XL | 13.1–13.3 | Large/malformed/untrusted files, path safety, low storage, cancellation and rollback evidence. |

### 14. Account và Sync

This wave starts only after local workflows and migration/version contracts are stable.

| WBS | Complete feature slice | Size | Depends on | Completion boundary |
| --- | --- | --- | --- | --- |
| 14.1 | Auth/security architecture | XL | 0.6, 13.4 | Provider selected, token secure storage, privacy/threat model and offline local access. |
| 14.2 | Sign-in/out/session recovery | XL | 14.1 | Local data preserved, auth/network errors separated, return flow safe. |
| 14.3 | Versioned sync/outbox | XL | 14.1 | Idempotent upload/download, retries, tombstones and object invariant validation. |
| 14.4 | Conflict resolution | XL | 14.3 | Explicit compare/choose/merge; no silent cloud-wins; atomic apply. |
| 14.5 | Account deletion conditional flow | L | 14.2 | Only if product support is approved; cloud/local impact and recovery fully specified. |
| 14.6 | Sync chaos/security gate | XL | 14.2–14.5 | Offline/flaky/duplicate/out-of-order/conflict/expired-session/redaction tests. |

### 15. Backup và restore

| WBS | Complete feature slice | Size | Depends on | Completion boundary |
| --- | --- | --- | --- | --- |
| 15.1 | Versioned backup format | XL | 13.4 | Integrity/version metadata, sensitive-data policy and consistent snapshot. |
| 15.2 | Create/inspect backup | L | 15.1 | Progress/error/done plus counts/date/version/integrity preview. |
| 15.3 | Restore/compatibility/rollback | XL | 15.1 | Validate before mutation, merge/replace impact, transaction rollback and recovery verification. |
| 15.4 | Cloud backup conditional flow | XL | 14.1, 15.3 | Only after provider/retention/security approval. |
| 15.5 | Backup disaster gate | XL | 15.2–15.4 | Old/new/corrupt/huge/low-storage/cancelled/half-write scenarios. |

### 16. Release hardening

| WBS | Work package | Size | Depends on | Deliverable / Definition of Done |
| --- | --- | --- | --- | --- |
| 16.0 | Release-scope lock | S | 0.6, 5.7.5 | Names the exact included wave gates and Tier-1 platforms/locales; excluded roadmap capabilities have owner/revisit target. |
| 16.1 | Full responsive/platform certification | XL | 16.0 | Tier-1 Web/Android matrix; resize, orientation, keyboard/mouse/touch and state restoration. Roadmap platforms are not certified by this item. |
| 16.2 | Accessibility certification | XL | 16.0 | Semantics, screen reader, keyboard, focus, contrast, text 200%, reduced motion; KIT-42 sign-off. |
| 16.3 | Localization certification | L | 16.0 | en/vi completeness, plural/date/number formatting, expansion/CJK fixtures, RTL-ready layout and no hardcoded UI copy. |
| 16.4 | Performance/reliability budgets | XL | 16.0 | Startup, frame, DB/query, memory, battery/background and large-library budgets with repeatable benchmarks. |
| 16.5 | Privacy/security review | XL | 16.0 | Data inventory, secret handling, logs, import/backup threats, permissions, retention and deletion behavior. |
| 16.6 | Migration/upgrade rehearsal | L | 16.0 | Upgrade from every released schema, rollback/recovery drill and restore fixture validation on Web/Android. |
| 16.7 | Release observability/support | L | 16.0 | Consent-aware crash reporting decision, redaction, diagnostics export and support runbook. |
| 16.8 | Final kit/guard/release gate | L | 16.1–16.7 | Full verifier passes; 0 P0/P1; P2/P3 owner/target; docs/evidence/changelog complete. |

## 8. Chiến lược test và ma trận evidence

| Layer | Test type | Mandatory examples |
| --- | --- | --- |
| Domain | Pure unit, decision table, property/boundary | Deck state derivation, SRS transitions, mode outcomes, idempotency, local-day boundaries. |
| Data | DAO/repository/in-memory Drift | Transactions, constraints, streams, paging, rollback, concurrent attempt conflicts. |
| Migration | Exported schema + generated migration tests | Every old schema to current, data preservation, corrupt/incompatible recovery. |
| Riverpod | ProviderContainer tests | Loading/data/error, command retry, disposal, narrow invalidation, typed effects. |
| Widget | State/action/accessibility tests | All canonical states, keyboard/back/dismiss, semantics/focus, 1.0/1.3/2.0 text. |
| Golden | Visual parity/adaptive snapshots | 390×780 light/dark under 3% when reference exists; representative widths in each class. |
| Integration | Critical user journeys | First learn, save failure retry, force-close/resume, offline, time rollover, stale writer. |
| Platform | Real/simulated capability tests | File picker, notifications, audio focus, secure storage, database opener and app lifecycle. |
| Performance | Repeatable benchmarks | Large Deck tree, 10k+ cards, dense attempts, index rebuild, session resume and cold startup. |

Canonical mobile behavior executed on desktop must set `MEMOX_E2E_WINDOW_SIZE=412x915` before app window creation. Framework-only surface resizing is insufficient for native window behavior.

## 9. Definition of Done cho từng feature

A feature is complete only when all items below are true:

1. No unresolved business↔design conflict; owning source and cross-object handoffs are named.
2. Decision table and traceability rows exist; every row maps to at least one test.
3. Domain/API/state/error/time/idempotency contracts are typed and documented.
4. Schema/migration/transaction behavior is implemented and tested when data changes.
5. UI imports neither data nor platform infrastructure and contains no business logic.
6. Providers are generated, lifecycle-correct and depend on use cases rather than repositories in presentation commands.
7. UI uses `Mx*`, centralized tokens and centralized responsive behavior; no raw visual values.
8. All user copy is localized; formatting uses locale-aware APIs.
9. Canonical happy/error/offline/concurrent/long-text/large-text/responsive/light/dark states are covered.
10. Accessibility, keyboard, back/dismiss, reduced-motion and focus behavior are verified.
11. Relevant unit/repository/provider/widget/golden/integration tests pass.
12. The consolidated repository verifier passes and no relevant warning is waived without owner/target.
13. Relevant KIT groups are fully checked; no open P0/P1; evidence is reproducible.
14. Navigation, schema, migration, business and WBS traceability docs are updated in the same change.

## 10. Các phần nên bổ sung ngoài danh sách ban đầu

- A versioned clock/timezone abstraction: SRS, Goal, Streak, Reminder and Statistics all fail nondeterministically without it.
- Stable idempotency and deterministic shuffle services: necessary for retry/resume and exactly-once session behavior.
- A formal DB schema/migration program from schema v1, not after the first production release.
- A single verification wrapper shared by developers, hooks and CI to prevent “passes locally but no pass marker” drift.
- Decision-table-driven tests and WBS traceability, because the business corpus contains many branch-heavy contracts and continues to evolve.
- Developer state fixtures and a screen-state gallery in Flutter, so every kit state is reviewable without manually reproducing data.
- Error taxonomy, redacted logging and recovery UX before adding sync/import/backup.
- Platform capability adapters and a support matrix; multi-platform does not mean every plugin behaves identically.
- Accessibility and keyboard/mouse acceptance from foundation day, not a release-end retrofit.
- Performance budgets and dense data fixtures before Library, Statistics and Sync scale up.
- Security/privacy threat models for files, backups, account, sync and logs.
- State restoration tests for window resize, rotation, app backgrounding and process death.
- An explicit analytics decision. Default to no behavioral analytics in this local-first app unless purpose, consent, retention and redaction are approved.

## 11. Nhịp triển khai đề xuất

- Keep one active vertical slice per integration stream. Avoid parallel writes to router, schema, theme, shared widgets or generated provider inputs.
- Never start an implementation row without its reviewed packet; only `1.1` is Ready in the current baseline.
- Begin each slice with FD-01–FD-03 and finish with FD-13–FD-16; do not leave visual/a11y/docs cleanup for a separate indefinite phase.
- Use small PR boundaries: contract/decision table, domain+data, presentation state, UI+evidence, then integration gate when separation improves reviewability.
- Run the quick targeted verifier during the inner loop and the full verifier at the slice gate.
- Demo only committed states using reproducible fixtures. A manually staged happy path is not acceptance evidence.
- Release the first-learning journey after WBS 5.7.5; subsequent waves can ship independently when their own complete-feature gate passes.

## 12. Tài liệu kỹ thuật tham chiếu

- [Flutter adaptive best practices](https://docs.flutter.dev/ui/adaptive-responsive/best-practices): đo không gian khả dụng, rẽ nhánh theo width, giới hạn layout rộng, hỗ trợ nhiều input và không suy layout từ loại thiết bị.
- [Flutter adaptive general approach](https://docs.flutter.dev/ui/adaptive-responsive/general): abstract → measure → branch, dùng `MediaQuery.sizeOf` hoặc `LayoutBuilder` đúng phạm vi.
- [Riverpod code generation](https://riverpod.dev/docs/concepts/about_code_generation): generated provider phù hợp repo đã dùng codegen; auto-dispose là mặc định và keep-alive phải được chọn có chủ đích.
- [Riverpod side effects](https://docs-v2.riverpod.dev/docs/essentials/side_effects): mutation nằm trong method của Notifier; event handler dùng `ref.read`, UI quan sát state bằng `ref.watch`.
- [Drift migrations](https://drift.simonbinder.eu/migrations/) và [migration tests](https://drift.simonbinder.eu/migrations/tests/): export từng schema, tạo migration helper/test và kiểm mọi đường nâng cấp được hỗ trợ.
