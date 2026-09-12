import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/constants/animation_constants.dart';
import 'package:lgbtindernew/core/utils/app_search_debounce.dart';

void main() {
  test('empty query emits immediately', () {
    final debounce = AppSearchDebounce();
    addTearDown(debounce.dispose);
    final out = <String>[];

    debounce.onText('', out.add);
    debounce.onText('   ', out.add);

    expect(out, ['', '   ']);
  });

  test('non-empty query waits 300ms and coalesces keystrokes', () {
    fakeAsync((async) {
      final debounce = AppSearchDebounce();
      final out = <String>[];

      debounce.onText('a', out.add);
      debounce.onText('al', out.add);
      debounce.onText('alex', out.add);
      async.elapse(const Duration(milliseconds: 299));
      expect(out, isEmpty);

      async.elapse(const Duration(milliseconds: 1));
      expect(out, ['alex']);
      expect(AppAnimations.searchDebounce, const Duration(milliseconds: 300));
    });
  });

  test('flush emits the pending value immediately', () {
    fakeAsync((async) {
      final debounce = AppSearchDebounce();
      final out = <String>[];

      debounce.onText('sam', out.add);
      debounce.flush(out.add);
      async.elapse(AppAnimations.searchDebounce);

      expect(out, ['sam']);
    });
  });

  test('cancel drops the pending emit', () {
    fakeAsync((async) {
      final debounce = AppSearchDebounce();
      final out = <String>[];

      debounce.onText('sam', out.add);
      debounce.cancel();
      async.elapse(AppAnimations.searchDebounce);

      expect(out, isEmpty);
    });
  });
}
