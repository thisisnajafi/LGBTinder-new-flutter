import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/constants/animation_constants.dart';
import 'package:lgbtindernew/core/theme/app_colors.dart';
import 'package:lgbtindernew/features/calls/presentation/widgets/call_network_signal.dart';
import 'package:lgbtindernew/features/calls/providers/agora_rtc_session_provider.dart';
import 'package:lgbtindernew/shared/services/agora_rtc_types.dart';

void main() {
  testWidgets('bars fill and use success color for excellent quality',
      (tester) async {
    await tester.pumpWidget(_harness());
    final container = ProviderScope.containerOf(
      tester.element(find.byType(CallNetworkSignal)),
    );
    container.read(agoraRtcSessionProvider.notifier).setNetworkQuality(
          AgoraNetworkQuality.excellent,
        );
    await tester.pump();

    final bars = tester.widgetList<AnimatedContainer>(
      find.byType(AnimatedContainer),
    );
    expect(bars.length, 4);
    expect(
      (bars.first.decoration as BoxDecoration).color,
      AppColors.feedbackSuccess,
    );
    expect(
      tester.widget<AnimatedContainer>(find.byType(AnimatedContainer).first).duration,
      AppAnimations.callSignalBar,
    );
  });

  testWidgets('poor quality uses warning token; Reduce Motion is instant',
      (tester) async {
    await tester.pumpWidget(
      _harness(disableAnimations: true, quality: AgoraNetworkQuality.poor),
    );
    await tester.pump();

    final bars = tester
        .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
        .toList();
    expect(bars.length, 4);
    expect((bars.first.decoration as BoxDecoration).color, AppColors.feedbackWarning);
    expect(bars.first.duration, Duration.zero);
    expect(bars.last.duration, Duration.zero);
  });

  testWidgets('bad quality uses error token', (tester) async {
    await tester.pumpWidget(_harness(quality: AgoraNetworkQuality.bad));
    await tester.pump();

    final bars = tester
        .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
        .toList();
    expect((bars.first.decoration as BoxDecoration).color, AppColors.feedbackError);
  });
}

Widget _harness({
  bool disableAnimations = false,
  String? quality,
}) {
  return ProviderScope(
    child: MaterialApp(
      builder: disableAnimations
          ? (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(disableAnimations: true),
                child: child!,
              );
            }
          : null,
      home: Scaffold(
        body: _QualitySeed(
          quality: quality,
          child: const Center(child: CallNetworkSignal()),
        ),
      ),
    ),
  );
}

class _QualitySeed extends ConsumerStatefulWidget {
  final String? quality;
  final Widget child;

  const _QualitySeed({required this.child, this.quality});

  @override
  ConsumerState<_QualitySeed> createState() => _QualitySeedState();
}

class _QualitySeedState extends ConsumerState<_QualitySeed> {
  @override
  void initState() {
    super.initState();
    final quality = widget.quality;
    if (quality != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(agoraRtcSessionProvider.notifier).setNetworkQuality(quality);
      });
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
