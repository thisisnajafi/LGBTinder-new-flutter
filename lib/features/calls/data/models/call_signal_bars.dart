import '../../../../shared/services/agora_rtc_types.dart';

/// 4-bar network indicator mapping for CALL-UI-007.
class CallSignalBars {
  CallSignalBars._();

  static const int barCount = 4;

  /// How many bars are filled for an [AgoraNetworkQuality] label.
  /// 1 excellent → 4, 2 good → 3, 3 poor → 2, 4–5 bad → 1, unknown → 0.
  static int filledCount(String quality) {
    switch (quality) {
      case AgoraNetworkQuality.excellent:
        return 4;
      case AgoraNetworkQuality.good:
        return 3;
      case AgoraNetworkQuality.poor:
        return 2;
      case AgoraNetworkQuality.bad:
        return 1;
      default:
        return 0;
    }
  }
}
