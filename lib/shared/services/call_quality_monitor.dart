import 'dart:async';

import '../../core/services/app_logger.dart';
import 'agora_rtc_types.dart';
import 'agora_service.dart';

/// Call quality metrics and monitoring
class CallQualityMetrics {
  final String callId;
  final int callerId;
  final int receiverId;
  final String callType; // 'video' or 'voice'
  final DateTime startTime;
  DateTime? endTime;
  int durationSeconds = 0;

  // Quality metrics
  int packetLoss = 0;
  int bitrate = 0;
  int fps = 0; // For video calls
  int audioLevel = 0;
  String networkQuality = 'unknown'; // 'excellent', 'good', 'poor', 'bad'
  bool callSuccessful = false;

  // Error tracking
  int connectionDrops = 0;
  List<String> errors = [];
  String? failureReason;

  CallQualityMetrics({
    required this.callId,
    required this.callerId,
    required this.receiverId,
    required this.callType,
    required this.startTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'call_id': callId,
      'caller_id': callerId,
      'receiver_id': receiverId,
      'call_type': callType,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'duration_seconds': durationSeconds,
      'packet_loss': packetLoss,
      'bitrate': bitrate,
      'fps': fps,
      'audio_level': audioLevel,
      'network_quality': networkQuality,
      'call_successful': callSuccessful,
      'connection_drops': connectionDrops,
      'errors': errors,
      'failure_reason': failureReason,
    };
  }
}

/// Service for monitoring call quality and tracking metrics
class CallQualityMonitor {
  CallQualityMetrics? _currentCallMetrics;
  Timer? _metricsTimer;
  Timer? _durationTimer;
  final AgoraService _agoraService;

  // Callbacks
  Function(CallQualityMetrics)? onCallEnded;
  Function(Map<String, dynamic>)? onQualityUpdate;

  CallQualityMonitor(this._agoraService);

  /// Start monitoring a call
  void startMonitoring({
    required String callId,
    required int callerId,
    required int receiverId,
    required String callType,
  }) {
    _currentCallMetrics = CallQualityMetrics(
      callId: callId,
      callerId: callerId,
      receiverId: receiverId,
      callType: callType,
      startTime: DateTime.now(),
    );

    // Start duration tracking
    _startDurationTracking();

    // Start quality metrics monitoring
    _startQualityMonitoring();

    AppLogger.info('Started quality monitoring for call $callId', tag: 'CallQuality');
  }

  /// Stop monitoring and finalize metrics
  void stopMonitoring({bool callSuccessful = true, String? failureReason}) {
    if (_currentCallMetrics == null) return;

    _currentCallMetrics!.endTime = DateTime.now();
    _currentCallMetrics!.durationSeconds = _currentCallMetrics!.endTime!
        .difference(_currentCallMetrics!.startTime)
        .inSeconds;
    _currentCallMetrics!.callSuccessful = callSuccessful;

    if (failureReason != null) {
      _currentCallMetrics!.failureReason = failureReason;
    }

    // Stop timers
    _metricsTimer?.cancel();
    _durationTimer?.cancel();

    // Notify completion
    onCallEnded?.call(_currentCallMetrics!);

    AppLogger.info(
      'Stopped quality monitoring duration=${_currentCallMetrics!.durationSeconds}s success=$callSuccessful',
      tag: 'CallQuality',
    );

    // Clear current metrics
    _currentCallMetrics = null;
  }

  /// Record a connection drop
  void recordConnectionDrop() {
    if (_currentCallMetrics != null) {
      _currentCallMetrics!.connectionDrops++;
      AppLogger.warning(
        'Connection drop recorded total=${_currentCallMetrics!.connectionDrops}',
        tag: 'CallQuality',
      );
    }
  }

  /// Record an error
  void recordError(String error) {
    if (_currentCallMetrics != null) {
      _currentCallMetrics!.errors.add(error);
      AppLogger.error('Quality error recorded: $error', tag: 'CallQuality');
    }
  }

  /// Update network quality from Agora [QualityType] mapping.
  void updateNetworkQuality(String quality) {
    if (_currentCallMetrics != null) {
      _currentCallMetrics!.networkQuality = quality;
    }
  }

  /// Apply real [RtcStats] bitrate / loss (do not invent zeros).
  void applyRtcStats({required int bitrateKbps, required int packetLossPercent}) {
    if (_currentCallMetrics == null) return;
    _currentCallMetrics!.bitrate = bitrateKbps;
    _currentCallMetrics!.packetLoss = packetLossPercent;
  }

  /// Get current call metrics
  CallQualityMetrics? getCurrentMetrics() {
    return _currentCallMetrics;
  }

  /// Start tracking call duration
  void _startDurationTracking() {
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentCallMetrics != null) {
        _currentCallMetrics!.durationSeconds++;
      }
    });
  }

  /// Start monitoring quality metrics
  void _startQualityMonitoring() {
    _metricsTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (_currentCallMetrics == null) return;

      try {
        final stats = await _agoraService.getCallStats();

        if (stats.containsKey('bitrate')) {
          _currentCallMetrics!.bitrate = stats['bitrate'] as int? ?? 0;
        }

        if (stats.containsKey('packetLoss')) {
          _currentCallMetrics!.packetLoss = stats['packetLoss'] as int? ?? 0;
        }

        if (_currentCallMetrics!.callType == 'video' && stats.containsKey('fps')) {
          _currentCallMetrics!.fps = stats['fps'] as int? ?? 0;
        }

        if (stats.containsKey('audioLevel')) {
          _currentCallMetrics!.audioLevel = stats['audioLevel'] as int? ?? 0;
        }

        _updateNetworkQuality();

        // Notify quality update
        onQualityUpdate?.call({
          'duration': _currentCallMetrics!.durationSeconds,
          'bitrate': _currentCallMetrics!.bitrate,
          'packet_loss': _currentCallMetrics!.packetLoss,
          'fps': _currentCallMetrics!.fps,
          'audio_level': _currentCallMetrics!.audioLevel,
          'network_quality': _currentCallMetrics!.networkQuality,
        });

      } catch (e) {
        AppLogger.error(
          'Error updating quality metrics',
          tag: 'CallQuality',
          error: e,
        );
      }
    });
  }

  /// Update network quality based on current metrics.
  /// Never overwrites an Agora [onNetworkQuality] label, and never treats
  /// missing 0/0 stats as `'bad'`.
  void _updateNetworkQuality() {
    if (_currentCallMetrics == null) return;

    final next = AgoraNetworkQuality.fromRtcStats(
      bitrateKbps: _currentCallMetrics!.bitrate,
      packetLossPercent: _currentCallMetrics!.packetLoss,
      currentQuality: _currentCallMetrics!.networkQuality,
    );
    if (next == null) return;
    _currentCallMetrics!.networkQuality = next;
  }

  /// Check if monitoring is active
  bool get isMonitoring => _currentCallMetrics != null;

  /// Dispose resources
  void dispose() {
    _metricsTimer?.cancel();
    _durationTimer?.cancel();
    _currentCallMetrics = null;
  }
}
