import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/core/theme/app_theme.dart';

/// Smallest phone the Discover redesign has to fit.
const Size kSmallPhone = Size(360, 640);

/// Pumps [child] in a themed app at [surface] size.
///
/// [textScale] and [direction] are applied the way the system applies them
/// (through `MediaQuery` and `Directionality`), so the widget under test
/// sees a real large-text or RTL environment.
Future<void> pumpDiscoverHost(
  WidgetTester tester,
  Widget child, {
  Size surface = kSmallPhone,
  double textScale = 1.0,
  TextDirection direction = TextDirection.ltr,
  Brightness brightness = Brightness.light,
  bool reduceMotion = false,
}) async {
  tester.view.physicalSize = surface;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: brightness == Brightness.dark
            ? AppTheme.darkTheme
            : AppTheme.lightTheme,
        builder: (context, app) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale),
              disableAnimations: reduceMotion,
            ),
            child: Directionality(textDirection: direction, child: app!),
          );
        },
        home: Scaffold(body: child),
      ),
    ),
  );
}

/// Fails with every layout or paint error raised so far (overflow stripes
/// are reported as exceptions in tests).
void expectNoLayoutErrors(WidgetTester tester) {
  final errors = <Object>[];
  Object? error;
  while ((error = tester.takeException()) != null) {
    errors.add(error!);
  }
  // Name the offending widget, not just "a RenderFlex overflowed".
  final details = [
    for (final e in errors) e is FlutterError ? e.toStringDeep() : '$e',
  ].join('\n');
  expect(errors, isEmpty, reason: 'layout errors:\n$details');
}
