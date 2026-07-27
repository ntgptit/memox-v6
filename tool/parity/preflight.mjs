import { existsSync, readFileSync, readdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

/**
 * Refuses to run the parity suite on a checkout that does not have the shots.
 *
 * `docs/design/**\/shots/*.png` is gitignored — 36 MB of reference images the
 * build does not need — so a fresh clone, and every CI runner, holds a dozen
 * force-added shots and no more. Without this the suite spends minutes
 * building a web bundle and driving a browser, then fails inside the image
 * comparison with `ENOENT` on a PNG, which reads as a broken spec rather than
 * a checkout that never had the reference to compare against.
 *
 * The count comes from `shots/INDEX.md`, which is generated from the shot
 * registry and *is* tracked — the one thing a checkout without images can
 * still read (the same signal `tool/verify/parity_census.mjs` uses).
 *
 * This exits non-zero rather than skipping. §6.5 says no screen-changing PR
 * merges without parity evidence; a checkout that cannot produce evidence has
 * not satisfied that, and saying so plainly is the point. Making CI able to
 * run this needs the shots tracked, moved to LFS, or fetched — a repository
 * decision, recorded as `int-87`.
 */

const parityRoot = dirname(fileURLToPath(import.meta.url));
const shotsRoot = join(
  parityRoot,
  '..',
  '..',
  'docs/design/MemoX Design System_v4/ui_kits/memox-app/shots',
);
const indexPath = join(shotsRoot, 'INDEX.md');

const onDisk = existsSync(shotsRoot)
  ? readdirSync(shotsRoot).filter((file) => file.endsWith('.png')).length
  : 0;

const declared = existsSync(indexPath)
  ? new Set(
      [
        ...readFileSync(indexPath, 'utf8').matchAll(
          /([\w-]+--(?:light|dark))\.png/g,
        ),
      ].map((match) => match[1]),
    ).size
  : 0;

if (declared > 0 && onDisk < declared) {
  process.stderr.write(
    `Kit shots are missing from this checkout: ${onDisk} of the ${declared} ` +
      `that shots/INDEX.md declares.\n\n` +
      `They are gitignored (.gitignore: docs/design/**/shots/*.png), so a ` +
      `clone or a CI runner does not have them and the parity suite has ` +
      `nothing to compare against. Running it here would fail inside the ` +
      `image diff and blame the specs.\n\n` +
      `Run it on a checkout that has the kit, or resolve int-87 — tracking ` +
      `the shots, moving them to Git LFS, or fetching the kit in CI.\n`,
  );
  process.exit(1);
}

process.stdout.write(
  `Kit shots present: ${onDisk} files covering the ${declared} the index ` +
    `declares.\n`,
);
