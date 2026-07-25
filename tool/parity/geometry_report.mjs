import { PNG } from 'pngjs';
import { existsSync, readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

/**
 * Row-band comparison for one state: where each horizontal band of content
 * starts, ends and how tall it is, in the render and in the kit shot.
 *
 * Built after a Match tile turned out to be 72 logical where the kit fixes
 * 116, which pushed every row out of alignment and left four states between
 * 1.4% and 16%. Colour sampling could not find it — with the rows offset,
 * sampling the same coordinates in both images compares *different elements*,
 * so the readings were not just unhelpful but misleading.
 *
 * Bands are found by comparing each row of a vertical strip against the page
 * ground in that same row's gutter. The gutter reference matters: keying off
 * the strip's own modal colour inverts as soon as content fills more of the
 * strip than the background does, which is exactly the case on a full board.
 *
 * A report, never a gate. Different fixture content legitimately changes band
 * counts — five cards where the kit draws twenty is not a defect.
 *
 * Run: `node tool/parity/geometry_report.mjs MX-VIS-062 [light|dark] [x]`
 */
const parityRoot = dirname(fileURLToPath(import.meta.url));
const [id, theme = 'light', strip = '200'] = process.argv.slice(2);

if (!id) {
  process.stderr.write(
    'Usage: node tool/parity/geometry_report.mjs <MX-VIS-id> [light|dark] [x]\n',
  );
  process.exitCode = 1;
} else {
  const dir = join(parityRoot, '..', '..', 'evidence', 'parity', `${id}--${theme}`);
  const actual = join(dir, 'actual.png');
  const expected = join(dir, 'expected.png');

  if (!existsSync(actual) || !existsSync(expected)) {
    process.stderr.write(`No evidence for ${id}--${theme}; measure it first\n`);
    process.exitCode = 1;
  } else {
    const x = Number.parseInt(strip, 10);
    const bands = (image) => {
      const at = (xx, y) => {
        const i = (image.width * y + xx) << 2;
        return [image.data[i], image.data[i + 1], image.data[i + 2]];
      };
      const found = [];
      let start = null;
      for (let y = 0; y < image.height; y += 1) {
        const [r, g, b] = at(x, y);
        const [pr, pg, pb] = at(8, y);
        const isContent =
          Math.abs(r - pr) + Math.abs(g - pg) + Math.abs(b - pb) > 12;
        if (isContent && start === null) start = y;
        if (!isContent && start !== null) {
          if (y - start > 20) found.push([start, y - 1, y - start]);
          start = null;
        }
      }
      if (start !== null && image.height - start > 20) {
        found.push([start, image.height - 1, image.height - start]);
      }
      return found;
    };

    const report = (label, path) => {
      const rows = bands(PNG.sync.read(readFileSync(path)));
      process.stdout.write(`${label}: ${rows.length} band(s) at x=${x}\n`);
      for (const [from, to, height] of rows) {
        process.stdout.write(`    ${from}..${to}  h=${height}\n`);
      }
      if (rows.length > 1) {
        const pitch = rows
          .slice(1)
          .map((row, index) => row[0] - rows[index][0]);
        process.stdout.write(`    pitch: ${pitch.join(', ')}\n`);
      }
      return rows;
    };

    process.stdout.write(`${id}--${theme}\n`);
    const ours = report('  render', actual);
    const kit = report('  kit   ', expected);

    const mismatches = [];
    for (let i = 0; i < Math.min(ours.length, kit.length); i += 1) {
      if (ours[i][2] !== kit[i][2]) {
        mismatches.push(`band ${i}: h=${ours[i][2]} vs kit h=${kit[i][2]}`);
      }
      if (ours[i][0] !== kit[i][0]) {
        mismatches.push(`band ${i}: starts ${ours[i][0]} vs kit ${kit[i][0]}`);
      }
    }
    if (ours.length !== kit.length) {
      mismatches.push(`band count ${ours.length} vs kit ${kit.length}`);
    }
    process.stdout.write(
      mismatches.length === 0
        ? '  bands align\n'
        : `  differences:\n${mismatches.map((m) => `    ${m}`).join('\n')}\n`,
    );
  }
}
