# Exception register

> Closes audit items **KIT-46-06** (parity exceptions lacked expiry/follow-up; no
> kit-level exception register) and **KIT-40-06** (exceptions recorded in readme caveats
> but missing owner/target/governance metadata).

Every sanctioned exception to a kit rule or gate is recorded here with an **owner**, a
**target/follow-up**, and an **expiry / review date**. An exception without these three
fields is not sanctioned. Seeded from `../readme.md` KNOWN CAVEATS and
`tool/parity/parity-allowlist.json`.

Status values: **Open** (active exception) · **Tracked** (accepted, revisited each
release) · **Closed** (resolved).

| ID | Exception | Rule/gate waived | Reason | Owner | Target / follow-up | Expiry / review | Status |
| --- | --- | --- | --- | --- | --- | --- | --- |
| EXC-01 | `deck-settings--move--light.png` exceeds the 3% parity gate (~10%) | `parity:gate` < 3% | **Semantic, by design.** Kit mock moves a deck *between decks*; shipped domain moves a deck *between language pairs* (`moveDeckUseCase`). Chrome + row anatomy match; only destination-row text differs. | Design System team (governance owner) | Align kit mock fixture copy to the real data model, or accept permanently as a product divergence | Review at v4.1 freeze | Tracked |
| EXC-02 | No bespoke **brand icon** / app-icon asset (typographic wordmark ships in lieu) | Asset export completeness (`asset-export-spec.md`) | The MemoX **wordmark** now ships (`assets/memox-wordmark.svg` + dark variant) with a full clear-space / min-size / light-dark spec (KIT-14-05). What remains missing is a **bespoke brand icon** and an **app-icon**; the wordmark is the current lockup, not the icon. | Design System team (design owner) | Obtain a bespoke MemoX brand icon + app-icon; extend `asset-export-spec.md` §G1 with icon clear-space / min-size / export matrix | Review at v4.1 freeze | Open |
| EXC-03 | Screens use realistic **placeholder** copy/data | Real-content completeness | Per the initialization brief — no real content, navigation, or validation yet. | Design System team (design owner) | Replace with real product content when the product data model is wired | Review at v4.1 freeze | Tracked |
| EXC-04 | Dense-text pairs carry ~2.6–2.8% anti-aliasing residue (below gate) | — (accepted residual, no waiver needed) | Kit shoots at 2× DPR; RN-web rasterizes text differently. Structural geometry aligned; residue is unavoidable AA noise. | Design System team (governance owner) | None — below the 3% gate; documented for transparency | Revisit if rasterization pipeline changes | Tracked |
| EXC-05 | `deck-content-choice--named`, `shell-dashboard--loaded` have no same-named kit reference shot | Parity comparability | No kit counterpart to score against; dashboard is still a placeholder slice (WBS 5.3). | Design System team (governance owner) | Add kit reference shots or dashboard slice, then score | Review at v4.1 freeze | Open |

## Governance rules

- The **parity allowlist** (`tool/parity/parity-allowlist.json`) is the machine-enforced
  side of EXC-01; every allowlist entry must have a matching row here **and** a section in
  `tool/parity/REMAINING-DIVERGENCES.md`. Styling drift is never allowed — only
  genuine semantic/product divergence.
- Every exception is **reviewed each release** (see `versioning.md`). An expired,
  unrenewed exception must be closed or its underlying gap fixed.
- New exceptions are added only with owner + target + expiry, approved by the governance
  owner in `release-signoff.md`.
