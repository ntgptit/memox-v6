import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/core/theme/responsive/app_breakpoints.dart';

/// WBS §5.3 required test widths and their documented classes, plus exact
/// boundary edges.
final Map<double, ScreenClass> _widthTable = <double, ScreenClass>{
  320: ScreenClass.compactMobile,
  360: ScreenClass.compactMobile,
  390: ScreenClass.compactMobile,
  412: ScreenClass.compactMobile,
  429.9: ScreenClass.compactMobile,
  430: ScreenClass.compact,
  599: ScreenClass.compact,
  600: ScreenClass.medium,
  768: ScreenClass.medium,
  839: ScreenClass.medium,
  840: ScreenClass.expanded,
  1024: ScreenClass.expanded,
  1199: ScreenClass.expanded,
  1200: ScreenClass.large,
  1440: ScreenClass.large,
  1920: ScreenClass.large,
};

void main() {
  test('fromWidth resolves every contract width to its class', () {
    for (final entry in _widthTable.entries) {
      expect(
        ScreenClass.fromWidth(entry.key),
        entry.value,
        reason: 'width ${entry.key}',
      );
    }
  });

  test('convenience flags partition the classes', () {
    expect(ScreenClass.compactMobile.isCompactAny, isTrue);
    expect(ScreenClass.compact.isCompactAny, isTrue);
    expect(ScreenClass.medium.isCompactAny, isFalse);
    expect(ScreenClass.medium.isMediumOrWider, isTrue);
    expect(ScreenClass.large.isMediumOrWider, isTrue);
  });

  test('ScreenInfo carries width and class with value equality', () {
    final info = ScreenInfo.fromWidth(390);

    expect(info.screenClass, ScreenClass.compactMobile);
    expect(info, ScreenInfo.fromWidth(390));
    expect(info, isNot(equals(ScreenInfo.fromWidth(600))));
  });

  testWidgets('context accessors resolve through MediaQuery at every width', (
    tester,
  ) async {
    for (final entry in _widthTable.entries) {
      late ScreenClass resolved;
      late ScreenInfo info;
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(size: Size(entry.key, 900)),
          child: Builder(
            builder: (context) {
              resolved = context.screenClass;
              info = context.screenInfo;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(resolved, entry.value, reason: 'width ${entry.key}');
      expect(info.width, entry.key);
    }
  });
}
