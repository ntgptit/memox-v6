import assert from 'node:assert/strict';
import test from 'node:test';

import { isDocsOnlyPath, selectScope } from './ci_scope.mjs';

const nonVisualTests = [
  'test/app/app_test.dart',
  'test/domain/deck/deck_name_test.dart',
  'test/presentation/features/deck/deck_screen_test.dart',
  'test/presentation/features/flashcard/card_editor_screen_test.dart',
  'test/presentation/shared/widgets/mx_button_test.dart',
];

test('documentation scope accepts textual docs but not executable design evidence', () => {
  assert.equal(isDocsOnlyPath('AGENTS.md'), true);
  assert.equal(isDocsOnlyPath('docs/business/README.md'), true);
  assert.equal(isDocsOnlyPath('docs/design/kit/shots/state.png'), false);
});

test('documentation-only changes skip Flutter work', () => {
  const scope = selectScope(['docs/business/README.md', 'AGENTS.md'], {
    testFiles: nonVisualTests,
  });
  assert.equal(scope.kind, 'docs');
  assert.equal(scope.docsOnly, true);
  assert.deepEqual(scope.testTargets, []);
});

test('feature changes select only that feature test directory', () => {
  const scope = selectScope(
    ['lib/presentation/features/flashcard/screens/card_editor_screen.dart'],
    { testFiles: nonVisualTests },
  );
  assert.equal(scope.kind, 'targeted');
  assert.deepEqual(scope.testTargets, [
    'test/presentation/features/flashcard/card_editor_screen_test.dart',
  ]);
});

test('domain changes widen to the domain suite', () => {
  const scope = selectScope(['lib/domain/deck/deck_name.dart'], {
    testFiles: nonVisualTests,
  });
  assert.equal(scope.kind, 'targeted');
  assert.deepEqual(scope.testTargets, ['test/domain/deck/deck_name_test.dart']);
});

test('shared and CI infrastructure changes use every non-visual test', () => {
  for (const path of [
    'lib/presentation/shared/widgets/mx_button.dart',
    '.github/workflows/ci.yml',
    'tool/verify/run.mjs',
  ]) {
    const scope = selectScope([path], { testFiles: nonVisualTests });
    assert.equal(scope.kind, 'broad');
    assert.deepEqual(scope.testTargets, nonVisualTests);
  }
});

test('unmapped changes fail safe to the broad suite', () => {
  const scope = selectScope(['web/index.html'], { testFiles: nonVisualTests });
  assert.equal(scope.kind, 'broad');
  assert.deepEqual(scope.testTargets, nonVisualTests);
});
