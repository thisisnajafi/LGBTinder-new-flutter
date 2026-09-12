import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/shared/services/agora_rtc_types.dart';

void main() {
  group('AgoraNetworkQuality.fromType', () {
    test('maps every QualityType by enum name', () {
      expect(
        AgoraNetworkQuality.fromType(QualityType.qualityUnknown),
        AgoraNetworkQuality.unknown,
      );
      expect(
        AgoraNetworkQuality.fromType(QualityType.qualityExcellent),
        AgoraNetworkQuality.excellent,
      );
      expect(
        AgoraNetworkQuality.fromType(QualityType.qualityGood),
        AgoraNetworkQuality.good,
      );
      expect(
        AgoraNetworkQuality.fromType(QualityType.qualityPoor),
        AgoraNetworkQuality.poor,
      );
      expect(
        AgoraNetworkQuality.fromType(QualityType.qualityBad),
        AgoraNetworkQuality.bad,
      );
      expect(
        AgoraNetworkQuality.fromType(QualityType.qualityVbad),
        AgoraNetworkQuality.bad,
      );
      expect(
        AgoraNetworkQuality.fromType(QualityType.qualityDown),
        AgoraNetworkQuality.bad,
      );
      expect(
        AgoraNetworkQuality.fromType(QualityType.qualityUnsupported),
        AgoraNetworkQuality.unknown,
      );
      expect(
        AgoraNetworkQuality.fromType(QualityType.qualityDetecting),
        AgoraNetworkQuality.unknown,
      );
    });

    test('excellent and good are not degraded (no poor-connection chip)', () {
      expect(
        AgoraNetworkQuality.isDegraded(
          AgoraNetworkQuality.fromType(QualityType.qualityExcellent),
        ),
        isFalse,
      );
      expect(
        AgoraNetworkQuality.isDegraded(
          AgoraNetworkQuality.fromType(QualityType.qualityGood),
        ),
        isFalse,
      );
      expect(
        AgoraNetworkQuality.isDegraded(
          AgoraNetworkQuality.fromType(QualityType.qualityUnknown),
        ),
        isFalse,
      );
      expect(
        AgoraNetworkQuality.isDegraded(
          AgoraNetworkQuality.fromType(QualityType.qualityPoor),
        ),
        isTrue,
      );
      expect(
        AgoraNetworkQuality.isDegraded(
          AgoraNetworkQuality.fromType(QualityType.qualityBad),
        ),
        isTrue,
      );
    });

    test('toasts only quality 4–5, not poor', () {
      expect(
        AgoraNetworkQuality.shouldToast(AgoraNetworkQuality.bad),
        isTrue,
      );
      expect(
        AgoraNetworkQuality.shouldToast(AgoraNetworkQuality.poor),
        isFalse,
      );
    });
  });

  group('AgoraNetworkQuality.fromScore', () {
    test('does not invert Agora QualityType integers', () {
      // Regression: old map used score <= 1 → good, so 2 (good) became poor.
      expect(AgoraNetworkQuality.fromScore(0), AgoraNetworkQuality.unknown);
      expect(AgoraNetworkQuality.fromScore(1), AgoraNetworkQuality.excellent);
      expect(AgoraNetworkQuality.fromScore(2), AgoraNetworkQuality.good);
      expect(AgoraNetworkQuality.fromScore(3), AgoraNetworkQuality.poor);
      expect(AgoraNetworkQuality.fromScore(4), AgoraNetworkQuality.bad);
      expect(AgoraNetworkQuality.fromScore(5), AgoraNetworkQuality.bad);
      expect(AgoraNetworkQuality.fromScore(6), AgoraNetworkQuality.bad);
      expect(AgoraNetworkQuality.fromScore(7), AgoraNetworkQuality.unknown);
      expect(AgoraNetworkQuality.fromScore(8), AgoraNetworkQuality.unknown);
    });

    test('fromScore matches fromType for documented values', () {
      for (final type in QualityType.values) {
        expect(
          AgoraNetworkQuality.fromScore(type.value()),
          AgoraNetworkQuality.fromType(type),
          reason: '$type value=${type.value()} index=${type.index}',
        );
      }
    });
  });

  group('AgoraNetworkQuality.fromRtcStats', () {
    test('does not force bad when bitrate is missing (0/0)', () {
      expect(
        AgoraNetworkQuality.fromRtcStats(
          bitrateKbps: 0,
          packetLossPercent: 0,
          currentQuality: AgoraNetworkQuality.unknown,
        ),
        isNull,
      );
    });

    test('does not overwrite an Agora excellent/good label', () {
      expect(
        AgoraNetworkQuality.fromRtcStats(
          bitrateKbps: 10,
          packetLossPercent: 50,
          currentQuality: AgoraNetworkQuality.excellent,
        ),
        isNull,
      );
      expect(
        AgoraNetworkQuality.fromRtcStats(
          bitrateKbps: 10,
          packetLossPercent: 50,
          currentQuality: AgoraNetworkQuality.good,
        ),
        isNull,
      );
    });
  });
}
