# View Card Detail

- Owner: **Flashcard**
- Status: **Canonical read projection**

Card Detail presents one Flashcard and links to owning commands. It is not a new aggregate and does
not duplicate edit, move, hide, delete, audio, translation, tag or Progress rules.

## Projection

- Primary term and meaning, additional translations and language context.
- Deck path, tags, audio availability and hidden/eligible state.
- Read-only Learning Progress summary: Box, due status and last terminal outcome when available.
- Actions route to the owning Flashcard flows; reset routes to Learning Progress.

## States and recovery

| State | Required behavior |
| --- | --- |
| Loading | Preserve route identity and show shared loading semantics. |
| Loaded | Render the latest committed projection; no draft state is created. |
| Not found/deleted | Explain that the Card is unavailable and offer safe return to its prior list/Deck. |
| Offline | Render committed local data; remote-only audio uses an unavailable/retry state. |
| Partial | Broken/missing audio or optional metadata does not hide core text. |
| Error | Typed recovery action; never expose a raw exception. |

## Acceptance and tests

- Deep link and list navigation resolve the same Card ID.
- Returning from a successful command refreshes the projection; cancel preserves it.
- Deletion while open transitions to Not found without a crash.
- Keyboard/focus order, 200% text, Web resize and Android rotation preserve route and scroll intent.
