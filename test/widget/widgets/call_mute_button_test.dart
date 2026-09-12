import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/constants/animation_constants.dart';
import 'package:lgbtindernew/core/theme/app_theme.dart';
import 'package:lgbtindernew/core/utils/app_icons.dart';
import 'package:lgbtindernew/features/calls/presentation/widgets/call_live_chrome.dart';
import 'package:lgbtindernew/features/calls/providers/live_call_ui_provider.dart';

void main() {
  testWidgets('mute icon crossfades and tints with error when muted',
      (tester) async {
    await tester.pumpWidget(_harness());

    expect(_iconPaths(tester), [AppIcons.microphone]);
    expect(_circleColor(tester), isNot(_errorTint(tester)));

    await tester.tap(find.byType(CallMuteButton));
    await tester.pump();
    expect(
      tester.widget<AnimatedSwitcher>(find.byType(AnimatedSwitcher)).duration,
      AppAnimations.callMuteIconCrossfade,
    );
    expect(
      tester.widget<AnimatedContainer>(find.byType(AnimatedContainer)).duration,
      AppAnimations.callMuteTint,
    );

    await tester.pumpAndSettle();
    expect(_iconPaths(tester), [AppIcons.microphoneSlash]);
    expect(_circleColor(tester), _errorTint(tester));
  });

  testWidgets('mute animation is skipped when Reduce Motion is on',
      (tester) async {
    await tester.pumpWidget(_harness(disableAnimations: true));

    expect(
      tester.widget<AnimatedSwitcher>(find.byType(AnimatedSwitcher)).duration,
      Duration.zero,
    );
    expect(
      tester.widget<AnimatedContainer>(find.byType(AnimatedContainer)).duration,
      Duration.zero,
    );
    expect(
      tester.widget<AnimatedScale>(find.byType(AnimatedScale)).duration,
      Duration.zero,
    );

    await tester.tap(find.byType(CallMuteButton));
    await tester.pump();
    expect(_iconPaths(tester), [AppIcons.microphoneSlash]);
    expect(_circleColor(tester), _errorTint(tester));
  });

  testWidgets('press scales mute button to buttonPressScale', (tester) async {
    await tester.pumpWidget(_harness());

    final center = tester.getCenter(find.byType(CallMuteButton));
    final gesture = await tester.startGesture(center);
    await tester.pump();
    await tester.pump(AppAnimations.tapDuration);

    expect(
      tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale,
      AppAnimations.buttonPressScale,
    );

    await gesture.up();
    await tester.pumpAndSettle();
    expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1.0);
  });
}

Widget _harness({bool disableAnimations = false}) {
  return ProviderScope(
    child: MaterialApp(
      theme: AppTheme.darkTheme,
      builder: disableAnimations
          ? (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(disableAnimations: true),
                child: child!,
              );
            }
          : null,
      home: const Scaffold(
        body: Center(child: _MuteHarness()),
      ),
    ),
  );
}

class _MuteHarness extends ConsumerWidget {
  const _MuteHarness();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CallMuteButton(
      onTap: () {
        final muted = ref.read(isMutedProvider);
        ref.read(liveCallUiProvider.notifier).setMuted(!muted);
      },
    );
  }
}

List<String> _iconPaths(WidgetTester tester) {
  return tester
      .widgetList<AppSvgIcon>(find.byType(AppSvgIcon))
      .map((icon) => icon.assetPath)
      .toList();
}

Color? _circleColor(WidgetTester tester) {
  final decoration = tester
      .widget<AnimatedContainer>(find.byType(AnimatedContainer))
      .decoration as BoxDecoration;
  return decoration.color;
}

Color _errorTint(WidgetTester tester) {
  final context = tester.element(find.byType(CallMuteButton));
  return Theme.of(context).colorScheme.error.withValues(alpha: 0.20);
}
