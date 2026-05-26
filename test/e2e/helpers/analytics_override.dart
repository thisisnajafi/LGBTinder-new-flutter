import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lgbtindernew/features/analytics/data/models/user_analytics.dart';
import 'package:lgbtindernew/features/analytics/domain/use_cases/get_analytics_use_case.dart';
import 'package:lgbtindernew/features/analytics/domain/use_cases/track_activity_use_case.dart';
import 'package:lgbtindernew/features/analytics/providers/analytics_provider.dart';
import 'package:mocktail/mocktail.dart';

class MockTrackActivityUseCase extends Mock implements TrackActivityUseCase {}

class MockGetAnalyticsUseCase extends Mock implements GetAnalyticsUseCase {}

final UserAnalytics _emptyAnalytics = UserAnalytics.fromJson(const {});

/// Prevents login/auth tests from hanging on analytics reload after track().
List<Override> noopAnalyticsOverrides() {
  final track = MockTrackActivityUseCase();
  when(
    () => track.execute(
      action: any(named: 'action'),
      metadata: any(named: 'metadata'),
    ),
  ).thenAnswer((_) async {});

  final getAnalytics = MockGetAnalyticsUseCase();
  when(() => getAnalytics.execute(days: any(named: 'days')))
      .thenAnswer((_) async => _emptyAnalytics);

  return [
    trackActivityUseCaseProvider.overrideWithValue(track),
    getAnalyticsUseCaseProvider.overrideWithValue(getAnalytics),
  ];
}
