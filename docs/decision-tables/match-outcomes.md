# SM-MATCH-v1 — Match outcome classification

`normalizeForMatchV1(text, locale)` = Unicode NFC → locale-aware case fold → trim outer whitespace → collapse internal Unicode whitespace. Không bỏ dấu, không dịch, không bỏ punctuation.

| ID | Given | When | Canonical evidence | Round effect |
| --- | --- | --- | --- | --- |
| SM-MATCH-001 | Selected term pair id = selected meaning pair id | Resolve | `correct` | Lock pair; không add failed nếu pair chưa lapse |
| SM-MATCH-002 | Pair ids khác và normalized meanings khác | Resolve | `wrong` | Add term-owner Card vào failed set |
| SM-MATCH-003 | Pair ids khác nhưng normalized meanings bằng nhau | Resolve | `almost`, reason `duplicateNormalizedMeaning` | Add term-owner Card vào failed set; show ambiguity feedback |
| SM-MATCH-004 | Pair đã wrong/almost rồi sau đó correct cùng round | Complete pair | Lapse evidence vẫn giữ | Pair vẫn vào round kế |
| SM-MATCH-005 | Duplicate tap/retry cùng event id/payload | Commit | Return prior evidence | Không duplicate Attempt/failed id |
| SM-MATCH-006 | Same event id, different payload | Commit | Typed conflict | Không mutate checkpoint |
| SM-MATCH-007 | Selection thiếu/missing/stale tile | Resolve | Invalid interaction | Không Attempt, không advance |

`almost` không dựa animation, khoảng cách kéo hoặc thời gian; nó chỉ dùng row SM-MATCH-003. Mọi other mismatch là `wrong`.
