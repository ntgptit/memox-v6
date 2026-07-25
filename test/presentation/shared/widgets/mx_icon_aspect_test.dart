import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:memox_v6/core/theme/app_theme.dart';
import 'package:memox_v6/core/theme/tokens/app_icon_sizes.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_icon.dart';

import '../../../support/golden_test_harness.dart';

/// A Material Symbol must render with the aspect ratio it was drawn at.
///
/// `study-result--standard` measured its hero glyph at 28 x 21 logical
/// against the kit's 27 x 27 — a circle painted as an ellipse. Rendering
/// the same glyph natively with the real bundled font reproduced it
/// exactly, so it was never a web-build artifact: `task_alt` paints a
/// 112 x 85 ink box in BOTH the Outlined and Rounded families — the same
/// box in both, which is what a missing glyph falling back to a shared
/// substitute looks like — while `task_alt_sharp` and
/// `check_circle_rounded` paint square.
///
/// This guards the icons the app actually ships on that screen, so a font
/// bump that reintroduces a distorted glyph fails here rather than in a
/// pixel diff nobody reads.
Future<ui.Image> _renderIcon(WidgetTester tester, IconData icon) async {
  final key = GlobalKey();
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: Center(
          child: RepaintBoundary(
            key: key,
            child: ColoredBox(
              color: const Color(0xFFFFFFFF),
              child: MxIcon(
                icon: icon,
                size: AppIconSizes.xl,
                color: const Color(0xFF000000),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  // Rasterizing needs the real async zone: `toImage` only completes once
  // the engine has drawn the layer, which a pumped test frame never does.
  return (await tester.runAsync(() => boundary.toImage(pixelRatio: 4)))!;
}

/// Ink bounding box of a black-on-white render, in device pixels.
Future<(int width, int height)> _inkBox(
  WidgetTester tester,
  ui.Image image,
) async {
  final data = (await tester.runAsync(
    () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
  ))!;
  final bytes = data.buffer.asUint8List();
  var minX = image.width, maxX = -1, minY = image.height, maxY = -1;
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      if (bytes[(y * image.width + x) * 4] < 160) {
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }
    }
  }
  if (maxX < 0) return (0, 0);
  return (maxX - minX + 1, maxY - minY + 1);
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('the study-result hero glyph is round, not elliptical', (
    tester,
  ) async {
    final image = await _renderIcon(tester, Symbols.check_circle_rounded);
    final (width, height) = await _inkBox(tester, image);

    expect(width, greaterThan(0), reason: 'the glyph painted nothing');
    expect(
      (width - height).abs(),
      lessThanOrEqualTo(4),
      reason:
          'painted ${width}x$height device px — a check-in-a-circle must not '
          'render as an ellipse',
    );
  });

  testWidgets('task_alt is still the distorted glyph it was swapped for', (
    tester,
  ) async {
    final image = await _renderIcon(tester, Symbols.task_alt_rounded);
    final (width, height) = await _inkBox(tester, image);

    // Not an assertion that the distortion is desirable — it pins the
    // reason the swap exists. When a font bump makes `task_alt` render
    // square again this fails, and the screen should go back to the glyph
    // the kit actually names.
    expect(
      (width - height).abs(),
      greaterThan(4),
      reason:
          'task_alt now paints ${width}x$height — if it is square again, '
          'restore it on study-result and delete this test',
    );
  });
}
