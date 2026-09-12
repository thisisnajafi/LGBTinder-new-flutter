import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/constants/animation_constants.dart';
import 'package:lgbtindernew/core/theme/app_theme.dart';
import 'package:lgbtindernew/core/utils/app_icons.dart';
import 'package:lgbtindernew/features/calls/presentation/widgets/call_quality_toast.dart';
import 'package:lgbtindernew/features/calls/providers/agora_rtc_session_provider.dart';
import 'package:lgbtindernew/shared/services/agora_rtc_types.dart';

void main() {
  Widget host({
    required AgoraRtcSessionNotifier notifier,
    bool reduceMotion = false,
  }) {
    return ProviderScope(
      overrides: [
        agoraRtcSessionProvider.overrideWith((ref) => notifier),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        builder: reduceMotion
            ? (context, child) {
                return MediaQuery(
                  data: MediaQuery.of(context).copyWith(disableAnimations: true),
                  child: child!,
                );
              }
            : null,
        home: const Scaffold(body: CallQualityToast()),
      ),
    );
  }

  Future<void> setQuality(
    WidgetTester tester,
    AgoraRtcSessionNotifier notifier,
    String quality,
  ) async {
    notifier.setNetworkQuality(quality);
    await tester.pump();
    await tester.pump();
  }

  testWidgets('quality 4–5 shows a Poor connection toast with warning SVG',
      (tester) async {
    final notifier = AgoraRtcSessionNotifier();
    await tester.pumpWidget(host(notifier: notifier));
    await tester.pump();
    expect(find.text('Poor connection'), findsNothing);

    await setQuality(tester, notifier, AgoraNetworkQuality.bad);
    expect(find.text('Poor connection'), findsOneWidget);
    expect(
      tester
          .widgetList<AppSvgIcon>(find.byType(AppSvgIcon))
          .map((icon) => icon.assetPath),
      [AppIcons.warning],
    );
    expect(AppAnimations.callQualityToastHold, const Duration(seconds: 3));
    expect(AppAnimations.callQualityToastDebounce, const Duration(seconds: 5));
  });

  testWidgets('poor (quality 3) does not toast', (tester) async {
    final notifier = AgoraRtcSessionNotifier();
    await tester.pumpWidget(host(notifier: notifier));
    await tester.pump();
    await setQuality(tester, notifier, AgoraNetworkQuality.poor);
    expect(find.text('Poor connection'), findsNothing);
  });

  testWidgets('Reduce Motion uses Duration.zero on the switcher',
      (tester) async {
    final notifier = AgoraRtcSessionNotifier();
    await tester.pumpWidget(host(notifier: notifier, reduceMotion: true));
    await tester.pump();
    await setQuality(tester, notifier, AgoraNetworkQuality.bad);
    expect(
      tester.widget<AnimatedSwitcher>(find.byType(AnimatedSwitcher)).duration,
      Duration.zero,
    );
  });
}
