# Shared-widget ↔ kit 1:1 parity checklist

> Mục tiêu: mỗi `Mx*` shared widget khớp kit về **theme (light+dark) · màu · size · state/chức năng**.
> Nguồn kit: `docs/design/MemoX Design System_v4/` — `components.css`, `tokens/*.css`, `ui_kits/memox-app/{_features,_shared,kit-helpers.jsx}`.
> Verify mức widget: đọc impl vs kit → so token (hex/px) → `flutter analyze` + `node tool/verify/run.mjs` (+ regen golden nếu đổi render).
> **Token note:** app_colors/typography/spacing/… sinh từ CSS + parity-gated → **màu không bao giờ lệch ở token**. Mismatch nằm ở chỗ widget **chọn sai token/role/size/layout**.

## Legend
✅ verified 1:1 · 🔧 fixed this session (gate xanh) · ⚠️ mismatch (fix/quyết định) · ⬜ chưa check

## A. Foundation / display
| # | Widget | Kit | Status | Ghi chú |
|---|---|---|---|---|
| A1 | `MxText` | type-scale | ⚠️ | thiếu role: term 3xl/**bold**, hero lg/**extrabold**, streak md/**extrabold**, row-title base/**bold**; overline weight 400 vs kit 700 |
| A2 | `MxIcon` | Symbols, `--icon-size-*` | ✅ | primitive 1:1 (18/22/28/32, màu, axes) + `filled` (FILL 1) cho selected-state |
| A3 | `MxCard` | `.card` | ✅ | 1:1 mọi variant 2 theme |
| A4 | `MxIconTile` | `.icon-tile` | ✅ | 1:1 mọi tone/size |
| A5 | `MxBadge` | `.badge` | 🔧 | thêm `tone`; caps-tracking Low còn (guard chặn raw `letterSpacing:0`) |
| A6 | `MxSectionLabel` | `SectionLabel` | ✅ | default khớp; nudge-override Low |
| A7 | `MxDivider` | `.divider` | ✅ | màu divider + hairline 1px, 2 theme |
| A8 | `MxProgress` | `.progress`/ProgressBar | 🔧 | `prominent` 8px+border; spinner 28/stroke-3 |
| A9 | `MxGap` | spacing tokens | ✅ | utility |

## B. Actions
| # | Widget | Kit | Status | Ghi chú |
|---|---|---|---|---|
| B1 | `MxButton` | `.btn` | ✅ | 1:1 mọi variant/size/màu 2 theme |
| B2 | `MxIconButton` | `.icon-btn` | 🔧/⚠️ | disabled 0.55 ✅; **glyph 24/20 hoãn** (kit dùng font-size token, guard chặn) |
| B3 | `MxFab` | `.fab` | 🔧 | icon→lg(28) + press-scale .94 ✅; còn hover→primary-strong (Low); không có `.fab--accent` |
| B4 | `MxLink` | `.link` | ✅ | 1:1 |
| B5 | `MxChip` | `.chip` | 🔧 | idle→`surface`/`text-secondary`/`fieldLabel`(semibold)/padding s4 ✅; height min-touch 48 (a11y) + thiếu variant accent/ghost/disabled còn |
| B6 | `MxTappable` | states | 🔧 | overlay màu khớp + `pressedScale` opt-in (btn .97/fab .94/icon-btn .9) ✅; focus ring vẽ trong thay vì halo ngoài (Low) |

## C. Inputs
| # | Widget | Kit | Status | Ghi chú |
|---|---|---|---|---|
| C1 | `MxFieldScaffold` | `field-group`/`.field` | 🔧/⛔ | label→fieldLabel; boxed padding s3. **⛔ BUG (2026-07-25): the labelled group is wrapped in `Semantics(textField: true)`, so the whole label+input+helper column claims to BE the text field.** The visual label merges into the accessible name (`aria-label="Deck name↵Deck name *"`) and the group node, which carries no value, shadows the real input — a screen reader reads the name twice and never hears the typed text. Caught by the parity gate: `MX-VIS-012/014/015` fail `toHaveValue` because `getByRole('textbox')` resolves to the wrapper. Fix belongs on the input, not the group, and needs an a11y pass over every form |
| C2 | `MxTextField` | `.field`/`InputBox` | ⚠️ | vs `.field` ok; **không phải drop-in fill InputBox** (96/center/xl-extrabold) |
| C3 | `MxTextArea` | `.field--multiline` | ✅ | core 1:1; label-nudge + focus-corner Low |
| C4 | `MxSearchField` | search dock/field | 🔧 | focus ring → foregroundDecoration (không inset content) ✅; nút clear + caret primary còn (Low, product choice) |
| C5 | `MxSelectRow` | select row | ✅ | static 1:1; expand-glyph size + pointer-hover Low |

## D. Navigation / chrome
| # | Widget | Kit | Status | Ghi chú |
|---|---|---|---|---|
| D1 | `MxContextualAppBar` | `.cappbar` | ⚠️ | gap lead→title 8 vs 12; context-line 112 vs 56; caption role; nền/title khớp |
| D2 | `MxBottomNav` | `.bottom-nav` | ✅ | icon→lg(28) + active `FILL 1` ✅ — 1:1 |
| D3 | `MxBreadcrumb` | `.breadcrumb` | ✅ | style tĩnh 1:1; crumb tap-target làm cao hàng ~48px (a11y tradeoff) |
| D4 | `MxContextPill` | deck-context pill | 🔧 | icon→sm(18) + role-label caption/text-tertiary ✅ |
| D5 | `MxSearchDock` | search dock | ✅ | 1:1 (shadow/radius/bg) |

## E. Feedback / content
| # | Widget | Kit | Status | Ghi chú |
|---|---|---|---|---|
| E1 | `MxBanner` | `.banner` | 🔧 | gap tiêu-đề → s05 ✅; action canh giữa còn (cần IntrinsicHeight, chỉ ảnh hưởng banner nhiều dòng) |
| E2 | `MxActionCallout` | `ActionCallout` | 🔧 | tiêu đề → base/bold ✅; body→action gap s3, dismiss gap s3 ✅; single-row icon (verify, chưa) |
| E3 | `MxEmptyState` | `EmptyState` | ✅ | 1:1 (tile lg, title lg/extrabold/tight, gap s4, padding s7) |
| E4 | `MxSectionHeader` | `.section-head` | ✅ | 1:1 (title md/bold/tight, caption, action) |
| E5 | `MxList` | list container | ✅ | 1:1 (separator space-3) |
| E6 | `MxDeckCard` | deck row | 🔧 | status màu → on-warning-soft/on-success-soft ✅; weight 600 vs 700 còn (Low) |
| E7 | `MxSkeleton` | `Skeleton`/`.mxg-skel` | ✅ | mới: `surface-sunken`, pulse opacity .5↔1 @ `duration-pulse` 1300ms, reduced-motion nghỉ ở đáy .5 (đo từ shot kit), `ExcludeSemantics`. Kit `r=8` không có token → dùng pill (mọi chỗ kit dùng default đều `h ≤ 16` nên `8 ≥ h/2`, pixel như nhau) |

## F. Layout / scaffold
| # | Widget | Kit | Status | Ghi chú |
|---|---|---|---|---|
| F1 | `MxScaffold` | `MxScaffold`/`.app` | ⚠️ | slot ok; body-inset qua ContentShell |
| F2 | `MxContentShell` | `.app__body` | ⚠️ | chỉ gutter ngang; thiếu padding top-s4/bottom-(nav+s6)/gap-s6 — mỗi màn tự cuộn |
| F3 | `MxListScaffold`/`Form`/`Study` | shells | ⚠️ | width-caps + list rhythm 1:1; **list thiếu clearance FAB/nav** (Med chức năng) |
| F4 | `MxFormFooter` | SaveBar | 🔧 | nền → surface + padding-top s3 ✅; gutter/gap do parent cấp |

## G. Overlays
| # | Widget | Kit | Status | Ghi chú |
|---|---|---|---|---|
| G1 | `MxSheet` | `.sheet` (frozen) / legacy | ✅⚠️ | **1:1 với `.sheet` FROZEN**; khác shot LEGACY (bg/handle/title) → **cần quyết định target** |
| G2 | `MxSelectSheet` | `SelectSheet`/`MenuItem` | 🔧 | title→SectionLabel(sm/bold); row v-pad s3; icon-gap s4; check `check`/primary ✅; label weight 600 còn (thiếu MxText role base/semibold) |
| G3 | `MxDialog` | `.dialog` (frozen) / legacy | ⚠️ | **title xl(24) vs frozen md(17)/legacy lg(20) + tight** (HIGH); body màu `text` vs `text-secondary` |
| G4 | `MxConfirmDialog` | `ConfirmDialog` legacy | ⚠️ | **shot legacy = centered + `MxIconTile` lg**; Flutter = left + `MxIcon` nhỏ → **cần quyết định frozen vs legacy** |

## Tổng kết
- **✅ 1:1 (17):** A2 A3 A4 A6 A7 A9 B1 B4 C3 C5 D3 D5 E3 E4 E5 + (MxLink) + G1(frozen)
- **🔧 fixed (5):** A5 A8 B2(disabled) C1 + StudyShell (7 commit)
- **⚠️ fix sạch được (nhiều):** B3 B5 D2 D4 E1 E2 E6 F4 G2 (icon-size, màu, gap, role có sẵn) — token-safe
- **⚠️ cần quyết định:** A1 (thêm MxText role), B2 (glyph 24/20), B6 (press-scale, ảnh hưởng mọi consumer), C2/C4 (InputBox/focus-ring), D1 (cappbar), F1/F2/F3 (app__body/shell), G1/G3/G4 (**frozen vs legacy** dialog/sheet — kit có 2 lớp mâu thuẫn)

## Việc tiếp (thứ tự)
1. **Batch icon-size** (sạch, token AppIconSizes): B3 MxFab→lg, D2 MxBottomNav→lg, D4 MxContextPill→sm.
2. **Batch màu/role/gap** (sạch): E6 MxDeckCard status màu+weight, F4 MxFormFooter nền surface, E1 MxBanner action-center+gap, E2 MxActionCallout heading base/bold, D4 role-label, G2 MxSelectSheet rows.
3. **B5 MxChip** idle bg/fg/weight/padding.
4. **MxIcon `fill` param** → D2 active-fill; rồi B6 press-scale (shared, ảnh hưởng rộng).
5. **Quyết định:** A1 MxText roles · G1/G3/G4 frozen-vs-legacy · C2 InputBox · D1 cappbar · F2 app__body.
