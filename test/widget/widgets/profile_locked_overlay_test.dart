import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/theme/app_theme.dart';
import 'package:lgbtindernew/core/utils/app_icons.dart';
import 'package:lgbtindernew/core/widgets/premium/premium_hub.dart';
import 'package:lgbtindernew/core/widgets/premium/profile_locked_overlay.dart';
import 'package:lgbtindernew/routes/app_router.dart';
import 'package:lgbtindernew/screens/feature_locked_screen.dart';
import 'package:lgbtindernew/shared/models/user_tier.dart';

void main() {
  testWidgets('locked overlay hides the child behind a lock badge',
      (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      _app(
        ProfileLockedOverlay(
          locked: true,
          label: 'Upgrade',
          onUnlock: () => tapped = true,
          child: const SizedBox(
            width: 120,
            height: 80,
            child: Text('secret-count'),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(ProfileLockedOverlay.overlayKey), findsOneWidget);
    expect(find.byKey(ProfileLockedOverlay.lockIconKey), findsOneWidget);
    expect(find.text('Upgrade'), findsOneWidget);

    await tester.tap(find.byKey(ProfileLockedOverlay.overlayKey));
    expect(tapped, isTrue);
  });

  testWidgets('unlocked overlay is a passthrough', (tester) async {
    await tester.pumpWidget(
      _app(
        const ProfileLockedOverlay(
          locked: false,
          child: Text('visible-child'),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('visible-child'), findsOneWidget);
    expect(find.byKey(ProfileLockedOverlay.overlayKey), findsNothing);
    expect(find.byKey(ProfileLockedOverlay.lockIconKey), findsNothing);
  });

  testWidgets('reduce motion still shows a static lock overlay',
      (tester) async {
    await tester.pumpWidget(
      _app(
        ProfileLockedOverlay(
          locked: true,
          compact: true,
          onUnlock: () {},
          child: const SizedBox(width: 80, height: 48, child: Text('42')),
        ),
        disableAnimations: true,
      ),
    );
    await tester.pump();

    expect(find.byKey(ProfileLockedOverlay.lockIconKey), findsOneWidget);
  });

  testWidgets('locked hub card shows the frosted overlay', (tester) async {
    await tester.pumpWidget(
      _app(
        PremiumHubCard(
          data: PremiumHubActionData(
            iconPath: AppIcons.flash,
            title: 'Boost',
            subtitle: 'Golden feature',
            locked: true,
            onTap: () {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Boost'), findsOneWidget);
    expect(find.byKey(ProfileLockedOverlay.overlayKey), findsOneWidget);
    expect(find.byKey(ProfileLockedOverlay.lockIconKey), findsOneWidget);
    expect(find.text('Upgrade'), findsOneWidget);
  });

  testWidgets('unlocked hub card has no lock overlay', (tester) async {
    await tester.pumpWidget(
      _app(
        PremiumHubCard(
          data: PremiumHubActionData(
            iconPath: AppIcons.flash,
            title: 'Boost',
            subtitle: 'Get more views',
            onTap: () {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Boost'), findsOneWidget);
    expect(find.byKey(ProfileLockedOverlay.overlayKey), findsNothing);
  });

  test('feature locked location encodes title and min tier', () {
    final uri = Uri.parse(
      FeatureLockedScreen.location(
        title: 'See who liked you',
        description: 'Unlock likes',
        minTier: UserTier.silder,
      ),
    );
    expect(uri.path, AppRoutes.featureLocked);
    expect(uri.queryParameters['title'], 'See who liked you');
    expect(uri.queryParameters['desc'], 'Unlock likes');
    expect(uri.queryParameters['minTier'], UserTier.silder.key);

    final boost = Uri.parse(
      FeatureLockedScreen.location(
        title: 'Boost',
        minTier: UserTier.golden,
      ),
    );
    expect(boost.queryParameters['minTier'], UserTier.golden.key);
    expect(boost.queryParameters.containsKey('desc'), isFalse);
  });
}

Widget _app(Widget child, {bool disableAnimations = false}) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    builder: (context, appChild) {
      final media = MediaQuery.of(context);
      return MediaQuery(
        data: media.copyWith(disableAnimations: disableAnimations),
        child: appChild!,
      );
    },
    home: Scaffold(body: Center(child: child)),
  );
}
