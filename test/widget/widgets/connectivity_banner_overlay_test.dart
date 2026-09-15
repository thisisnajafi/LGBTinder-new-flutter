import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/providers/api_providers.dart';
import 'package:lgbtindernew/core/providers/connectivity_provider.dart';
import 'package:lgbtindernew/core/services/connectivity_service.dart';
import 'package:lgbtindernew/core/widgets/connectivity_banner.dart';

void main() {
  testWidgets('offline banner does not rebuild the wrapped child',
      (tester) async {
    var childBuilds = 0;
    final states = StreamController<NetworkConnectionState>.broadcast();
    addTearDown(states.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          connectivityServiceBindingProvider.overrideWith((ref) {}),
          connectivityProvider.overrideWith((ref) async* {
            yield NetworkConnectionState.connected;
            yield* states.stream;
          }),
        ],
        child: MaterialApp(
          home: ConnectivityBanner(
            child: Builder(
              builder: (context) {
                childBuilds++;
                return const Text('App body');
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('App body'), findsOneWidget);
    expect(find.text('No internet connection'), findsNothing);
    final buildsBefore = childBuilds;

    states.add(NetworkConnectionState.disconnected);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('No internet connection'), findsOneWidget);
    expect(find.text('App body'), findsOneWidget);
    expect(childBuilds, buildsBefore);
  });
}
