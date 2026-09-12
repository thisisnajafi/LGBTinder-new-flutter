import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/providers/session_services_provider.dart';
import 'package:lgbtindernew/core/widgets/service_lifecycle_host.dart';

void main() {
  testWidgets('ServiceLifecycleHost builds child and keeps session services alive',
      (tester) async {
    var alive = false;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionServicesProvider.overrideWith((ref) {
            alive = true;
            ref.onDispose(() => alive = false);
          }),
        ],
        child: const MaterialApp(
          home: ServiceLifecycleHost(child: Text('ok')),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('ok'), findsOneWidget);
    expect(find.byType(ServiceLifecycleHost), findsOneWidget);
    expect(alive, isTrue);
  });
}
