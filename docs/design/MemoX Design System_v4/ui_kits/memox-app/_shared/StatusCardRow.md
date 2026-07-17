# StatusCardRow — shared composite

A term + meaning row (optional `deck` line) with a trailing status badge. Owns
the single `new` / `due` / `mastered` → label+tone map that `flashcard-list`
(the Flashcard List) and `search` (ResultRow) previously duplicated verbatim.

```jsx
// flashcard-list: tight term + one-line ellipsised meaning
<window.StatusCardRow term="안녕하세요" meaning="Hello (formal)" status="due"
  node="flashcard-list/card-0" tightTerm truncateMeaning />

// search: adds a deck line, default term/meaning
<window.StatusCardRow term="공부하다" meaning="to study" deck="TOPIK I — Vocabulary"
  status="due" node="search/result-0" />
```

## Props
- `term` / `meaning` — primary + secondary text.
- `deck` — optional third line (search only).
- `status` — `new` | `due` | `mastered` → badge label + tone (internal map).
- `hidden` — dims the row to 50% and shows a `visibility_off` glyph.
- `node` / `onClick` — `data-mx-node` id + optional tap handler.
- `tightTerm` — tightens the term letter-spacing (flashcard-list).
- `truncateMeaning` — clips the meaning to one line with ellipsis (flashcard-list).

## Rules
- The two boolean variants encode the ONLY visual differences between callers;
  do not add per-screen styles here — add a variant flag or keep it local.
- Status taxonomy lives here once; change it in one place.

## Flutter target
- Component → an `MxStatusCardRow` widget (wrap in `MxCard` at the call site).
- `status` → `MxBadge` tone · `tightTerm` → `MxTypography.trackingTight` ·
  `truncateMeaning` → `TextOverflow.ellipsis` · `node` → `ValueKey`.
