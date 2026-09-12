import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/theme/app_theme.dart';
import 'package:lgbtindernew/main.dart';

void main() {
  test('deferred push init waits 3s after first frame', () {
    expect(deferredPushInitDelay, const Duration(seconds: 3));
  });

  test('Android page transitions use predictive back', () {
    expect(
      AppTheme.pageTransitionsTheme.builders[TargetPlatform.android],
      isA<PredictiveBackPageTransitionsBuilder>(),
    );
    expect(
      AppTheme.lightTheme.pageTransitionsTheme.builders[TargetPlatform.android],
      isA<PredictiveBackPageTransitionsBuilder>(),
    );
  });
}
