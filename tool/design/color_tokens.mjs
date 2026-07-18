#!/usr/bin/env node
// Emits lib/core/theme/tokens/app_colors.dart and app_opacities.dart from the
// design kit's colors.css / opacity.css (WBS 2.2). One-shot bootstrap writer:
//   node tool/design/color_tokens.mjs --write
// Continuous parity is enforced by test/core/theme/token_css_parity_test.dart,
// which re-parses the CSS at gate time and compares every value.

import { readFileSync, writeFileSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const repoRoot = join(dirname(fileURLToPath(import.meta.url)), '..', '..');
const tokensDir = join(repoRoot, 'docs', 'design', 'MemoX Design System_v4', 'tokens');

function dartSymbol(tokenName) {
  return tokenName
    .replace(/^--memox-/, '')
    .split('-')
    .map((part, index) => (index === 0 ? part : part.charAt(0).toUpperCase() + part.slice(1)))
    .join('');
}

function parseBlocks(cssPath) {
  const content = readFileSync(cssPath, 'utf8');
  const blocks = new Map(); // selector -> Map(token -> rawValue)
  let context = null;
  for (const rawLine of content.split(/\r?\n/)) {
    const line = rawLine.replace(/\/\*.*?\*\//g, '');
    const selector = line.match(/^\s*([^{}/]*\S)\s*\{/);
    if (selector) context = selector[1].trim();
    const declaration = line.match(/^\s*(--memox-[a-z0-9-]+)\s*:\s*([^;]+);/);
    if (!declaration || !context) continue;
    if (!blocks.has(context)) blocks.set(context, new Map());
    blocks.get(context).set(declaration[1], declaration[2].trim());
  }
  return blocks;
}

function resolveTheme(blocks, selectors) {
  const merged = new Map();
  for (const selector of selectors) {
    for (const [name, value] of blocks.get(selector) ?? []) merged.set(name, value);
  }
  // Resolve var() aliases within the theme.
  const resolve = (value, depth = 0) => {
    const match = value.match(/^var\((--memox-[a-z0-9-]+)\)$/);
    if (!match) return value;
    if (depth > 5) throw new Error(`alias loop at ${value}`);
    const target = merged.get(match[1]);
    if (!target) throw new Error(`unresolved alias ${value}`);
    return resolve(target, depth + 1);
  };
  const out = new Map();
  for (const [name, value] of merged) out.set(name, resolve(value));
  return out;
}

function cssColorToDart(value) {
  const hex = value.match(/^#([0-9a-fA-F]{6})$/);
  if (hex) return `Color(0xFF${hex[1].toUpperCase()})`;
  const rgba = value.match(/^rgba\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*([0-9.]+)\s*\)$/);
  if (rgba) return `Color.fromRGBO(${rgba[1]}, ${rgba[2]}, ${rgba[3]}, ${rgba[4]})`;
  throw new Error(`unsupported color value: ${value}`);
}

const colorBlocks = parseBlocks(join(tokensDir, 'colors.css'));
// The light block's two-line selector (`:root,` newline `[data-theme='light']`)
// registers under the line containing `{`.
const light = resolveTheme(colorBlocks, ["[data-theme='light']", ':root']);
const dark = resolveTheme(colorBlocks, ["[data-theme='light']", ':root', "[data-theme='dark']"]);

// Theme-independent palette tokens live in the plain :root block.
const paletteNames = [...(colorBlocks.get(':root') ?? new Map()).keys()];
const themedNames = [...light.keys()].filter((name) => !paletteNames.includes(name)).sort();
paletteNames.sort();

const opacityBlocks = parseBlocks(join(tokensDir, 'opacity.css'));
const opacities = [...(opacityBlocks.get(':root') ?? new Map()).entries()].sort(([a], [b]) => a.localeCompare(b));

function colorField(name) {
  return `  /// \`${name}\``+ `\n  final Color ${dartSymbol(name)};`;
}

const header = `// GENERATED from the design kit — do not edit by hand.\n//\n// Source: docs/design/MemoX Design System_v4/tokens/colors.css (+ opacity.css)\n// Regenerate: node tool/design/color_tokens.mjs --write\n// Parity gate: test/core/theme/token_css_parity_test.dart re-parses the CSS\n// on every verifier run and fails on any value or coverage drift.\n// Token NAMES are a frozen contract (additive-only); values follow the kit.\n`;

const appColors = `${header}\nimport 'dart:ui';\n\n/// Semantic color roles for one theme (WBS 2.2).\nfinal class AppColorTokens {\n  const AppColorTokens({\n${themedNames.map((n) => `    required this.${dartSymbol(n)},`).join('\n')}\n  });\n\n${themedNames.map(colorField).join('\n\n')}\n\n  /// Every themed token keyed by its frozen CSS name.\n  Map<String, Color> get byToken => <String, Color>{\n${themedNames.map((n) => `    '${n}': ${dartSymbol(n)},`).join('\n')}\n  };\n\n  /// Field-wise override; used by the high-contrast profile (WBS 2.9).\n  AppColorTokens copyWith({\n${themedNames.map((n) => `    Color? ${dartSymbol(n)},`).join('\n')}\n  }) {\n    return AppColorTokens(\n${themedNames.map((n) => `      ${dartSymbol(n)}: ${dartSymbol(n)} ?? this.${dartSymbol(n)},`).join('\n')}\n    );\n  }\n}\n\n/// Canonical MemoX palette (deep violet); light/dark instances plus the\n/// theme-independent selectable accent palette.\nabstract final class AppColors {\n  static const AppColorTokens light = AppColorTokens(\n${themedNames.map((n) => `    ${dartSymbol(n)}: ${cssColorToDart(light.get(n))},`).join('\n')}\n  );\n\n  static const AppColorTokens dark = AppColorTokens(\n${themedNames.map((n) => `    ${dartSymbol(n)}: ${cssColorToDart(dark.get(n))},`).join('\n')}\n  );\n\n${paletteNames.map((n) => `  /// \`${n}\`\n  static const Color ${dartSymbol(n)} = ${cssColorToDart(light.get(n))};`).join('\n\n')}\n\n  /// Theme-independent palette tokens keyed by frozen CSS name.\n  static const Map<String, Color> paletteByToken = <String, Color>{\n${paletteNames.map((n) => `    '${n}': ${dartSymbol(n)},`).join('\n')}\n  };\n}\n`;

const appOpacities = `${header}\n/// Opacity scale (WBS 2.2); theme-independent.\nabstract final class AppOpacities {\n${opacities.map(([n, v]) => `  /// \`${n}\`\n  static const double ${dartSymbol(n)} = ${v};`).join('\n\n')}\n\n  /// Every opacity token keyed by its frozen CSS name.\n  static const Map<String, double> byToken = <String, double>{\n${opacities.map(([n]) => `    '${n}': ${dartSymbol(n)},`).join('\n')}\n  };\n}\n`;

if (process.argv[2] !== '--write') {
  console.error('Usage: node tool/design/color_tokens.mjs --write');
  process.exit(2);
}

writeFileSync(join(repoRoot, 'lib', 'core', 'theme', 'tokens', 'app_colors.dart'), appColors, 'utf8');
writeFileSync(join(repoRoot, 'lib', 'core', 'theme', 'tokens', 'app_opacities.dart'), appOpacities, 'utf8');
console.log(`Wrote ${themedNames.length} themed + ${paletteNames.length} palette color tokens and ${opacities.length} opacity tokens.`);
