import { readFileSync, readdirSync, statSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

/**
 * Fails on a localized string no code references.
 *
 * An unreferenced string is not harmless. `moreOptionsLabel` sat in the ARB
 * unused while the disclosure it named went unbuilt, and reading the ARB
 * suggested a feature that did not exist. The reverse is worse: copy written
 * for a control that was later unwired looks live to translators, who pay to
 * localize it, and to anyone auditing what the app can do.
 *
 * Retained-but-unused keys are declared below with the reason, so the file
 * records intent instead of accumulating silence. Anything unreferenced and
 * undeclared fails.
 */
const verifyRoot = dirname(fileURLToPath(import.meta.url));
const repoRoot = join(verifyRoot, '..', '..');
const arbPath = join(repoRoot, 'lib', 'l10n', 'app_en.arb');
const libRoot = join(repoRoot, 'lib');

/**
 * Unreferenced on purpose. Each entry says why the string outlives its caller;
 * an entry that stops being unreferenced is reported too, so the list cannot
 * quietly go stale.
 */
const RETAINED = {
  firstRunLanguageSubtitle: 'first-run step 1 subtitle, dropped when the kit step lost its subtitle row',
  stepOneOfTwo: 'wizard step counter the kit renders as a progress bar instead',
  stepTwoOfTwo: 'as stepOneOfTwo',
  emptyLibraryMessage: 'superseded by the kit empty state copy (MX-VIS-018)',
  openDeckLabel: 'first-deck callout action, superseded by owner ruling 2026-07-21 (MX-VIS-021/022)',
  dismissLabel: 'as openDeckLabel — the dismissed callout state went with it',
  nestedDeckCountSummary: 'parent-branch scope totals; SubdeckList.jsx has no place for them (MX-VIS-036)',
  decksSectionLabel: 'as nestedDeckCountSummary — the DECKS section label the JSX drops',
  deckScopeSummary: 'as nestedDeckCountSummary',
  parentDeckSummary: 'as nestedDeckCountSummary',
  cardCountLabel: 'leaf-branch count summary, same JSX-vs-shot removal',
  studyDeckLabel: 'deck-detail Study CTA, dropped by owner decision (full-width CTA removed)',
  moveDeckTitle: 'cross-pair move confirm (move-deck.md §5/§6); destinations are same-pair only, so the branch is unbuilt',
  moveDeckToRootBody: 'as moveDeckTitle',
  moveDeckConfirmLabel: 'as moveDeckTitle',
  addTagLabel: 'tag-management surface of WBS 6.4, not yet built',
  removeTagLabel: 'as addTagLabel',
  studyFinalizeErrorMessage: 'finalize-error body; the screen currently shows the title alone',
};

const arb = JSON.parse(readFileSync(arbPath, 'utf8'));
const keys = Object.keys(arb).filter((key) => !key.startsWith('@'));

// Any member access, not just `l10n.<key>`: strings are also read through
// `AppLocalizations.of(context).<key>`, and matching only the first form
// reports live strings as dead — which it did, on the first run of this audit.
const member = /\.([a-zA-Z0-9_]+)/g;
const referenced = new Set();

const walk = (dir) => {
  for (const entry of readdirSync(dir)) {
    const path = join(dir, entry);
    if (statSync(path).isDirectory()) {
      if (entry !== 'generated') walk(path);
      continue;
    }
    if (!entry.endsWith('.dart') || entry.endsWith('.g.dart')) continue;
    const source = readFileSync(path, 'latin1');
    for (const match of source.matchAll(member)) referenced.add(match[1]);
  }
};
walk(libRoot);

const undeclared = keys.filter(
  (key) => !referenced.has(key) && !(key in RETAINED),
);
const staleRetained = Object.keys(RETAINED).filter(
  (key) => referenced.has(key) || !keys.includes(key),
);

const bullet = (entries) => entries.map((entry) => `  - ${entry}`).join('\n');

if (undeclared.length === 0 && staleRetained.length === 0) {
  process.stdout.write(
    `l10n usage: ${keys.length} strings; ` +
      `${Object.keys(RETAINED).length} retained unreferenced, each with a reason.\n`,
  );
} else {
  if (undeclared.length > 0) {
    process.stderr.write(
      '\nLocalized strings nothing references:\n' +
        `${bullet(undeclared)}\n` +
        'Wire it up, delete it, or declare it in RETAINED with the reason.\n',
    );
  }
  if (staleRetained.length > 0) {
    process.stderr.write(
      '\nRETAINED entries that are no longer unreferenced strings:\n' +
        `${bullet(staleRetained)}\n` +
        'Remove the entry — the reason it records no longer applies.\n',
    );
  }
  process.exitCode = 1;
}
