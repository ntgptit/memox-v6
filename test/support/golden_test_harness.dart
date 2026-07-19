import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

/// Shared golden/parity font harness.
///
/// The test binding renders every glyph with the Ahem block font unless
/// the real fonts are loaded, so goldens captured without this loader
/// lock in box glyphs instead of typography. Every suite that calls
/// `matchesGoldenFile` (and the kit-parity suites) must run
/// `setUpAll(loadAppFonts)`.

/// Loads the real app font so renders match the kit's text instead of
/// the test framework's block glyphs. Call once per suite.
Future<void> loadAppFonts() async {
  final data = File(
    'assets/fonts/PlusJakartaSans-Variable.ttf',
  ).readAsBytesSync();
  final loader = FontLoader('Plus Jakarta Sans')
    ..addFont(Future.value(ByteData.view(data.buffer)));
  await loader.load();
  await _loadMaterialSymbols();
}

/// Registers the Material Symbols icon font (a package font, which the
/// test binding does not load) so kit icons render as glyphs, not boxes.
Future<void> _loadMaterialSymbols() async {
  final config =
      jsonDecode(File('.dart_tool/package_config.json').readAsStringSync())
          as Map<String, dynamic>;
  final packages = config['packages'] as List<dynamic>;
  final entry = packages.cast<Map<String, dynamic>>().firstWhere(
    (p) => p['name'] == 'material_symbols_icons',
  );
  // rootUri may be absolute (pub cache) or relative to .dart_tool/,
  // and needs a trailing slash so resolve() keeps its last segment.
  final rootUri = entry['rootUri'] as String;
  final root = Directory(
    '.dart_tool',
  ).uri.resolveUri(Uri.parse(rootUri.endsWith('/') ? rootUri : '$rootUri/'));
  // Package fonts resolve under a `packages/<pkg>/` family prefix. The
  // kit renders icons with the Rounded family (`material-symbols-rounded`
  // in `MxButton.jsx`); Outlined stays loaded for legacy call sites.
  for (final family in ['MaterialSymbolsOutlined', 'MaterialSymbolsRounded']) {
    final data = File.fromUri(
      root.resolve('lib/fonts/$family.ttf'),
    ).readAsBytesSync();
    final loader = FontLoader('packages/material_symbols_icons/$family')
      ..addFont(Future.value(ByteData.view(data.buffer)));
    await loader.load();
  }
}
