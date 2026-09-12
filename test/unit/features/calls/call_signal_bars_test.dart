import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/features/calls/data/models/call_signal_bars.dart';
import 'package:lgbtindernew/shared/services/agora_rtc_types.dart';

void main() {
  group('CallSignalBars.filledCount', () {
    test('maps Agora quality 1 excellent → 4 bars through 5 poor → 1', () {
      expect(CallSignalBars.filledCount(AgoraNetworkQuality.excellent), 4);
      expect(CallSignalBars.filledCount(AgoraNetworkQuality.good), 3);
      expect(CallSignalBars.filledCount(AgoraNetworkQuality.poor), 2);
      expect(CallSignalBars.filledCount(AgoraNetworkQuality.bad), 1);
      expect(CallSignalBars.filledCount(AgoraNetworkQuality.unknown), 0);
    });
  });
}
