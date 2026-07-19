# MemoX implementation packet contract

- Status: **Current**
- Owner: Delivery / QA / owning feature

Một WBS row mô tả delivery boundary; implementation packet biến boundary đó
thành một đơn vị có thể giao cho developer/agent mà không phải tự phát minh
architecture, file placement, test scope hoặc completion evidence.

## Promotion rule

- Mọi implementation item phải có packet trước khi chuyển sang `Ready`.
- Packet phải được review lại khi input contract thay đổi.
- Chỉ item có toàn bộ dependency `Done` mới được `Ready`; packet hoàn chỉnh
  không tự vượt qua dependency.
- Item `XL` phải có bảng child boundaries A/B/C…; mỗi child có file scope,
  test scope và evidence độc lập. Không bắt đầu một XL item chỉ từ WBS row.
- Chỉ item-specific register override được thay đổi status. Prefix default luôn
  là `Blocked`.

## Required packet schema

1. Identity, owner, status, dependency và decision gates.
2. Canonical inputs với exact paths/decision-table row ranges/KIT groups.
3. In-scope và explicitly out-of-scope.
4. Exact files: create/modify/delete/generated-do-not-edit.
5. Exact symbols/APIs và dependency direction.
6. State/action/error/concurrency/migration matrix khi áp dụng.
7. Child boundaries cho item XL.
8. Acceptance ID và concrete assertions.
9. Test IDs, exact test files, fixtures và row-to-test mapping.
10. Canonical verifier command và durable evidence paths.
11. Completion procedure: update register to Done and unlock immediate children.

Không dùng glob thay cho exact file list trong packet Ready. Một folder được
phép khi packet đồng thời liệt kê exact files đầu tiên và rule cho các file được
generator tạo; generated `*.g.dart`, `*.freezed.dart`, Drift output và
`lib/l10n/generated/**` không bao giờ là edit target.

## Path ownership

| Concern | Production root | Test/evidence root |
| --- | --- | --- |
| Bootstrap/router/DI | `lib/app/**` | `test/app/**` |
| Theme/tokens/responsive | `lib/core/theme/**` | `test/core/theme/**` |
| Deterministic infrastructure | `lib/core/{time,ids,errors,logging}/**` | `test/core/**` |
| Domain | `lib/domain/**` | `test/domain/**` |
| Drift/data | `lib/data/**` | `test/data/**`, `drift_schemas/**` |
| Shared `Mx*` | `lib/presentation/shared/**` | `test/presentation/shared/**`, design evidence register |
| Feature UI/providers | `lib/presentation/features/<feature>/**` | `test/presentation/features/<feature>/**` |
| Localization | `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb` | localized widget/E2E tests |

## Active packet index

| WBS | Packet | Current status |
| --- | --- | --- |
| `1.1` | [Dependency baseline](./WBS-1.1-dependency-baseline.md) | Done (2026-07-19) |
| `1.3` | [App bootstrap](./WBS-1.3-app-bootstrap.md) | Done (2026-07-19) |
| `1.4` | [Router skeleton](./WBS-1.4-router-skeleton.md) | Done (2026-07-19) |
| `1.5` | [Error and observability pipeline](./WBS-1.5-error-observability.md) | Done (2026-07-19) |
| `1.6` | [Deterministic infrastructure](./WBS-1.6-deterministic-infrastructure.md) | Done (2026-07-19) |
| `1.7` | [Developer fixtures](./WBS-1.7-dev-fixtures.md) | Done (2026-07-19) |
| `1.8` | [Raise guard profile](./WBS-1.8-guard-profile.md) | Done (2026-07-19) |
| `1.10` | [Shared test infrastructure](./WBS-1.10-test-infrastructure.md) | Done (2026-07-19) |
| `1.11` | [Riverpod foundation](./WBS-1.11-riverpod-foundation.md) | Done (2026-07-19) |
| `1.9` | [Localization foundation](./WBS-1.9-localization-foundation.md) | Done (2026-07-19) |
| `2.1` | [Token inventory/mapping manifest](./WBS-2.1-token-manifest.md) | Done (2026-07-19) |
| `2.2` | [Color and opacity tokens](./WBS-2.2-color-opacity-tokens.md) | Done (2026-07-19) |
| `2.3` | [Typography/font tokens](./WBS-2.3-typography-tokens.md) | Done (2026-07-19) |
| `2.4` | [Spacing/size/radius/stroke/elevation tokens](./WBS-2.4-dimension-tokens.md) | Done (2026-07-19) |
| `2.5` | [Motion/icon tokens](./WBS-2.5-motion-icon-tokens.md) | Done (2026-07-19) |
| `2.6` | [Theme extensions/accessors](./WBS-2.6-theme-extensions.md) | Done (2026-07-19) |
| `2.7` | [Theme assembly](./WBS-2.7-theme-assembly.md) | Done (2026-07-19) |
| `2.8` | [Responsive foundation (XL)](./WBS-2.8-responsive-foundation.md) | Done (2026-07-19) — children A–C |
| `2.9` | [High-contrast readiness](./WBS-2.9-high-contrast-readiness.md) | Done (2026-07-19) — readiness + explicit deferral |
| `2.10` | [Foundation contract tests](./WBS-2.10-foundation-contract-tests.md) | Done (2026-07-19) — wave-2 gate closed |
| `3.1` | [Shared text/icon/tappable foundation](./WBS-3.1-shared-foundation.md) | Done (2026-07-19) |
| `3.2` | [`MxButton` family](./WBS-3.2-mx-button.md) | Done (2026-07-19) |
| `3.3` | [`MxTextField` and form foundation (XL)](./WBS-3.3-mx-text-field.md) | Done (2026-07-19) — children A–C |
| `3.4` | [`MxCard`, list and surface primitives (XL)](./WBS-3.4-card-list-surfaces.md) | Done (2026-07-19) — children A–C |
| `3.5` | [`MxScaffold` and content shells (XL)](./WBS-3.5-scaffold-shells.md) | Done (2026-07-19) — children A–C |
| `3.6` | [Navigation primitives](./WBS-3.6-navigation-primitives.md) | Done (2026-07-19) |
| `3.7` | [First-learning feedback primitives](./WBS-3.7-feedback-primitives.md) | Done (2026-07-19) |
| `3.9` | [Async/action infrastructure](./WBS-3.9-async-infrastructure.md) | Done (2026-07-19) |
| `3.10` | [First-learning shared composites](./WBS-3.10-shared-composites.md) | Done (2026-07-19) |
| `3.12` | [Minimal Mx gate](./WBS-3.12-minimal-mx-gate.md) | Done — gate PASSED (2026-07-19) |
| `4.1` | [Database runtime](./WBS-4.1-database-runtime.md) | Done (2026-07-19) |
| `4.2` | [Schema v1 (XL)](./WBS-4.2-schema-v1.md) | Done (2026-07-19) |
| `4.3` | [Schema constraints](./WBS-4.3-schema-constraints.md) | Done (2026-07-19) |
| `4.4` | [DAO layer (XL)](./WBS-4.4-dao-layer.md) | Done (2026-07-19) |
| `4.5` | [Mapper/model layer](./WBS-4.5-mappers.md) | Done (2026-07-19) |
| `4.6` | [Repositories (XL)](./WBS-4.6-repositories.md) | Done (2026-07-19) |
| `4.7` | [Migration system](./WBS-4.7-migrations.md) | Done (2026-07-19) |
| `4.8` | [App DI graph](./WBS-4.8-di-graph.md) | Done (2026-07-19) |
| `4.9` | [Performance baseline](./WBS-4.9-performance-baseline.md) | Done (2026-07-19) |
| `4.10` | [Foundation gate](./WBS-4.10-foundation-gate.md) | Done — gate PASSED (2026-07-19) |
| `5.1.1` | [Language Pair domain/data](./WBS-5.1.1-language-pair-domain.md) | Done (2026-07-19) |
| `5.1.2` | [First-run language UI](./WBS-5.1.2-first-run-language-ui.md) | Done (2026-07-19) |
| `5.1.3` | [Language Pair evidence](./WBS-5.1.3-language-pair-evidence.md) | Done (2026-07-19) |
| `5.2.1` | [Deck entity/state derivation](./WBS-5.2.1-deck-domain.md) | Done (2026-07-19) |
| `5.2.2` | [Create Deck transaction](./WBS-5.2.2-create-deck.md) | Done (2026-07-19) |
| `5.2.3` | [First-run landing/setup (XL)](./WBS-5.2.3-first-run-setup.md) | In progress — children A, B Done (2026-07-19) |

Packets cho các item kế tiếp được tạo just-in-time theo dependency order. Không
đánh dấu trước chúng là Ready.
