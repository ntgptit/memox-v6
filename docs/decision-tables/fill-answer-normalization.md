# SM-FILL-v1 — Fill answer normalization and comparison

## Comparison policy `fill-compare-v1`

1. Reject blank after Unicode whitespace trim.
2. Normalize Unicode NFC.
3. Trim outer whitespace và collapse internal Unicode whitespace thành một ASCII space.
4. Locale-aware case fold theo language pair answer locale.
5. Giữ diacritics, punctuation và word order; không transliterate, stem, fuzzy-match hoặc auto-translate.
6. Normalize canonical alternatives riêng rồi exact-compare. Alternatives đến từ immutable Card snapshot (`primaryMeaning` + explicit accepted translations), không từ search index.

| ID | Given | When | Then |
| --- | --- | --- | --- |
| SM-FILL-001 | Empty/whitespace-only input | Submit | Validation error; không Attempt |
| SM-FILL-002 | Input khác answer chỉ bởi NFC/case/outer hoặc repeated whitespace | Compare | `correct` |
| SM-FILL-003 | Input khác dấu, punctuation hoặc word order | Compare | `wrong` |
| SM-FILL-004 | Input match một explicit accepted alternative | Compare | `correct`; persist matched alternative id |
| SM-FILL-005 | Input gần đúng nhưng không exact normalized match | Compare | `wrong`; không fuzzy pass |
| SM-FILL-006 | IME composition chưa commit | Submit | Không submit; giữ draft |
| SM-FILL-007 | Same attempt id retried | Commit | Return prior result; không duplicate |
| SM-FILL-008 | Unsupported/unknown comparison version | Compare | Typed policy error; giữ draft, không Attempt |

Evidence persist `comparisonPolicyId`, input hash hoặc normalized value theo privacy policy, matched alternative id, hint-used flag và outcome.
