import 'package:flutter/material.dart';
import 'package:memox_v6/app/router/app_router.dart';
import 'package:memox_v6/app/router/router_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox_v6/app/bootstrap/app_bootstrap.dart';

/// Foundation responsive snapshots (WBS 2.10): the themed app root at a
/// representative width of every §5.3 class, light and dark. These lock
/// the token→theme→responsive composition; `Mx*` component goldens are
/// owned by WBS 3.11/3.12.
void main() {
  const widths = <String, Size>{
    'compact-mobile-390': Size(390, 780),
    'compact-599': Size(599, 900),
    'medium-768': Size(768, 1024),
    'expanded-1024': Size(1024, 800),
    'large-1440': Size(1440, 900),
  };

  for (final brightness in Brightness.values) {
    for (final entry in widths.entries) {
      testWidgets('foundation ${entry.key} ${brightness.name}', (tester) async {
        tester.view.devicePixelRatio = 1.0;
        tester.platformDispatcher.platformBrightnessTestValue = brightness;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

        tester.view.physicalSize = entry.value;
        await tester.pumpWidget(
          buildRoot(
            overrides: [
              appRouterInstanceProvider.overrideWithValue(createAppRouter()),
            ],
          ),
        );
        await tester.pumpAndSettle();

        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile(
            'goldens/foundation_${entry.key}_${brightness.name}.png',
          ),
        );
      });
    }
  }
}
