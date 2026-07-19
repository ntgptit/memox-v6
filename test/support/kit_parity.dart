import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

export 'golden_test_harness.dart' show loadAppFonts;

/// Kit visual-parity harness (WBS 3.15).
///
/// Compares a live-rendered Flutter screen against the canonical kit
/// screenshot (`ui_kits/memox-app/shots/*.png`, 390 logical px at 2×)
/// and fails when more than [threshold] of pixels differ — the
/// pre-merge parity rule is **< 3%** per screen state, light and dark.
/// The shared font loader lives in `golden_test_harness.dart`.

const String kitShotsRoot =
    'docs/design/MemoX Design System_v4/ui_kits/memox-app/shots';

/// The status-bar inset the kit reserves above every app bar
/// (`--memox-safe-area-top`: max(env, 24px) — 24 logical in shots).
const double kitStatusBarInset = 24;

/// Sizes the test view to the kit shot (2× DPR) and simulates the
/// kit's status-bar inset so chrome sits where a device would put it.
void applyKitViewport(WidgetTester tester, String shotName) {
  final shot = kitShotSize(shotName);
  tester.view.devicePixelRatio = 2.0;
  tester.view.physicalSize = shot;
  tester.view.padding = FakeViewPadding(
    top: kitStatusBarInset * tester.view.devicePixelRatio,
  );
  addTearDown(tester.view.reset);
}

/// Result of one comparison; [ratio] is the differing-pixel share.
class KitParityResult {
  const KitParityResult({
    required this.ratio,
    required this.comparedPixels,
    required this.kitSize,
    required this.renderedSize,
  });

  final double ratio;
  final int comparedPixels;
  final ui.Size kitSize;
  final ui.Size renderedSize;
}

/// Sizes the test view to the kit shot (2× DPR), captures [finder]'s
/// render and diffs it against `shots/<shotName>.png`.
///
/// Per-channel tolerance absorbs anti-aliasing blend differences, and a
/// ±1-logical-px spatial slack (pixelmatch-style) absorbs the sub-pixel
/// glyph-advance drift between the kit's browser rasterizer and
/// Flutter's — a pixel counts as differing only when nothing within a
/// 2-physical-px radius of the kit image matches it. Wrong colors and
/// layout offsets of 2+ logical px stay fully visible to the gate.
Future<KitParityResult> compareWithKitShot(
  WidgetTester tester,
  Finder finder, {
  required String shotName,
  int channelTolerance = 24,
}) async {
  final bytes = File('$kitShotsRoot/$shotName.png').readAsBytesSync();
  late final ui.Image kitImage;
  await tester.runAsync(() async {
    final codec = await ui.instantiateImageCodec(bytes);
    kitImage = (await codec.getNextFrame()).image;
  });

  final captured = await captureImage(finder.evaluate().single);

  late final ByteData kitData;
  late final ByteData renderData;
  await tester.runAsync(() async {
    kitData = (await kitImage.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    renderData = (await captured.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    ))!;
  });

  final width = kitImage.width < captured.width
      ? kitImage.width
      : captured.width;
  final height = kitImage.height < captured.height
      ? kitImage.height
      : captured.height;
  // ±1 logical px (2 physical at the 2× shot scale).
  const slack = 2;

  bool matchesNear(int x, int y) {
    final renderOffset = (y * captured.width + x) * 4;
    for (var dy = -slack; dy <= slack; dy++) {
      final ky = y + dy;
      if (ky < 0 || ky >= height) continue;
      for (var dx = -slack; dx <= slack; dx++) {
        final kx = x + dx;
        if (kx < 0 || kx >= width) continue;
        final kitOffset = (ky * kitImage.width + kx) * 4;
        var maxDelta = 0;
        for (var channel = 0; channel < 3; channel++) {
          final delta =
              (kitData.getUint8(kitOffset + channel) -
                      renderData.getUint8(renderOffset + channel))
                  .abs();
          if (delta > maxDelta) maxDelta = delta;
        }
        if (maxDelta <= channelTolerance) return true;
      }
    }
    return false;
  }

  var differing = 0;
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      if (!matchesNear(x, y)) differing++;
    }
  }

  final compared = width * height;
  return KitParityResult(
    ratio: compared == 0 ? 1 : differing / compared,
    comparedPixels: compared,
    kitSize: ui.Size(kitImage.width.toDouble(), kitImage.height.toDouble()),
    renderedSize: ui.Size(
      captured.width.toDouble(),
      captured.height.toDouble(),
    ),
  );
}

/// The pre-merge parity threshold (owner rule, 2026-07-19): a screen
/// state passes only under 3% differing pixels against its kit shot.
const double kitParityThreshold = 0.03;

/// Pumps [app], settles its streams and asserts the rendered screen
/// stays under [kitParityThreshold] against `shots/<shotName>.png`.
/// On failure the render is dumped to `build/parity/` for inspection.
Future<void> expectKitParity(
  WidgetTester tester, {
  required Widget app,
  required String shotName,
  Future<void> Function(WidgetTester tester)? prepare,
}) async {
  applyKitViewport(tester, shotName);

  await tester.pumpWidget(app);
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.pump(const Duration(seconds: 1));
  if (prepare != null) {
    await prepare(tester);
    await tester.pump(const Duration(seconds: 1));
  }

  final result = await compareWithKitShot(
    tester,
    find.byType(MaterialApp),
    shotName: shotName,
  );

  if (result.ratio >= kitParityThreshold) {
    await tester.runAsync(() async {
      final captured = await captureImage(
        find.byType(MaterialApp).evaluate().single,
      );
      final png = await captured.toByteData(format: ui.ImageByteFormat.png);
      Directory('build/parity').createSync(recursive: true);
      File(
        'build/parity/$shotName.rendered.png',
      ).writeAsBytesSync(png!.buffer.asUint8List());
    });
  }

  expect(
    result.ratio,
    lessThan(kitParityThreshold),
    reason:
        '$shotName differs by '
        '${(result.ratio * 100).toStringAsFixed(2)}% (gate: <3%); '
        'render dumped to build/parity/$shotName.rendered.png',
  );

  // Dispose, then let drift's stream-retention timer fire.
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 1));
}

/// Reads the kit shot's pixel size so the test view can match it.
ui.Size kitShotSize(String shotName) {
  final bytes = File('$kitShotsRoot/$shotName.png').readAsBytesSync();
  // PNG IHDR: width/height are big-endian at fixed offsets 16 and 20.
  final data = ByteData.sublistView(bytes);
  return ui.Size(data.getUint32(16).toDouble(), data.getUint32(20).toDouble());
}
