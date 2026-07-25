/**
 * A second opinion on every measured state, sensitive to *arrangement* where
 * the pixel ratio is sensitive to *area*.
 *
 * The ratio is what §6.5 gates on, and on a sparse screen it is close to
 * blind: reversing both columns of the Match board moved it 0.00pp, and
 * replacing all ten words on that board moved it 0.07pp. Anything mostly
 * whitespace can differ structurally and still pass.
 *
 * This reports, per state, the correlation between the actual and expected
 * *ink profiles* — the share of non-background pixels in each column and each
 * row. A swapped column, a missing control or a shifted block changes those
 * profiles even when it barely moves the area. Low correlation with a passing
 * ratio is the signature worth looking at by eye.
 *
 * Deliberately a report, not a gate. The correlation has no defensible
 * threshold: a legitimately different fixture (a longer deck name, five cards
 * instead of twenty) lowers it without anything being wrong. It ranks states
 * for attention; a human decides.
 *
 * Run: `node tool/parity/structure_report.mjs`
 */
import { PNG } from 'pngjs';
import { readFileSync, existsSync, readdirSync } from 'node:fs';
import { join } from 'node:path';
const root = join('..','..','evidence','parity');
// Ink profile: per-column and per-row share of non-background pixels.
function profiles(img) {
  const w = img.width, h = img.height;
  const counts = new Map();
  for (let i = 0; i < img.data.length; i += 4) {
    const k = (img.data[i]<<16)|(img.data[i+1]<<8)|img.data[i+2];
    counts.set(k, (counts.get(k)||0)+1);
  }
  let bg = 0, best = -1;
  for (const [k,v] of counts) if (v > best) { best = v; bg = k; }
  const br=(bg>>16)&255, bgc=(bg>>8)&255, bb=bg&255;
  const col = new Float64Array(w), row = new Float64Array(h);
  for (let y=0;y<h;y++) for (let x=0;x<w;x++) {
    const i=(w*y+x)<<2;
    if (Math.abs(img.data[i]-br)+Math.abs(img.data[i+1]-bgc)+Math.abs(img.data[i+2]-bb) > 24) { col[x]++; row[y]++; }
  }
  return { col, row };
}
function corr(a, b) {
  const n = Math.min(a.length, b.length);
  let ma=0, mb=0;
  for (let i=0;i<n;i++){ma+=a[i];mb+=b[i];} ma/=n; mb/=n;
  let num=0, da=0, db=0;
  for (let i=0;i<n;i++){const x=a[i]-ma, y=b[i]-mb; num+=x*y; da+=x*x; db+=y*y;}
  return num/Math.sqrt(da*db||1);
}
const out=[];
for (const dir of readdirSync(root)) {
  if (!dir.endsWith('--light')) continue;
  const a=join(root,dir,'actual.png'), e=join(root,dir,'expected.png'), r=join(root,dir,'result.json');
  if(!existsSync(a)||!existsSync(e)||!existsSync(r)) continue;
  const meta=JSON.parse(readFileSync(r,'utf8'));
  const pa=profiles(PNG.sync.read(readFileSync(a))), pe=profiles(PNG.sync.read(readFileSync(e)));
  out.push({id:meta.wbsId, pct:meta.differencePercentage, res:meta.result,
            col:corr(pa.col,pe.col), row:corr(pa.row,pe.row), name:`${meta.screen}/${meta.state}`});
}
out.sort((x,y)=>Math.min(x.col,x.row)-Math.min(y.col,y.row));
console.log('id          diff%  res    colCorr rowCorr  screen/state');
for(const o of out) console.log(`${o.id}  ${String(o.pct).padStart(5)}  ${o.res.padEnd(5)}  ${o.col.toFixed(3).padStart(6)}  ${o.row.toFixed(3).padStart(6)}  ${o.name}`);
