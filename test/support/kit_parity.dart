import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Kit visual-parity harness (WBS 3.15).
///
/// Compares a live-rendered Flutter screen against the canonical kit
/// screenshot (`ui_kits/memox-app/shots/*.png`, 390 logical px at 2×)
/// and fails when more than [threshold] of pixels differ — the
/// pre-merge parity rule is **< 3%** per screen state, light and dark.

const String kitShotsRoot =
    'docs/design/MemoX Design System_v4/ui_kits/memox-app/shots';

/// Loads the real app font so parity renders match the kit's text
/// instead of the test framework's block glyphs. Call once per suite.
Future<void> loadAppFonts() async {
  final data = File(
    'assets/fonts/PlusJakartaSans-Variable.ttf',
  ).readAsBytesSync();
  final loader = FontLoader('Plus Jakarta Sans')
    ..addFont(Future.value(ByteData.view(data.buffer)));
  await loader.load();
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
/// Per-channel tolerance absorbs cross-engine anti-aliasing; the
/// returned ratio is the share of pixels beyond it over the compared
/// intersection.
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

  var differing = 0;
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final kitOffset = (y * kitImage.width + x) * 4;
      final renderOffset = (y * captured.width + x) * 4;
      var maxDelta = 0;
      for (var channel = 0; channel < 3; channel++) {
        final delta =
            (kitData.getUint8(kitOffset + channel) -
                    renderData.getUint8(renderOffset + channel))
                .abs();
        if (delta > maxDelta) maxDelta = delta;
      }
      if (maxDelta > channelTolerance) differing++;
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

/// Reads the kit shot's pixel size so the test view can match it.
ui.Size kitShotSize(String shotName) {
  final bytes = File('$kitShotsRoot/$shotName.png').readAsBytesSync();
  // PNG IHDR: width/height are big-endian at fixed offsets 16 and 20.
  final data = ByteData.sublistView(bytes);
  return ui.Size(data.getUint32(16).toDouble(), data.getUint32(20).toDouble());
}
