import 'dart:async';
import 'package:flutter/foundation.dart';
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

    debugPrint('Started call quality monitoring for call: $callId');
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

    debugPrint('Stopped call quality monitoring. Duration: ${_currentCallMetrics!.durationSeconds}s, Successful: $callSuccessful');

    // Clear current metrics
    _currentCallMetrics = null;
  }

  /// Record a connection drop
  void recordConnectionDrop() {
    if (_currentCallMetrics != null) {
      _currentCallMetrics!.connectionDrops++;
      debugPrint('Connection drop recorded. Total drops: ${_currentCallMetrics!.connectionDrops}');
    }
  }

  /// Record an error
  void recordError(String error) {
    if (_currentCallMetrics != null) {
      _currentCallMetrics!.errors.add(error);
      debugPrint('Error recorded: $error');
    }
  }

  /// Update network quality
  void updateNetworkQuality(String quality) {
    if (_currentCallMetrics != null) {
      _currentCallMetrics!.networkQuality = quality;
    }
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
        // Get Agora stats (this would be enhanced with actual Agora SDK stats)
        final stats = await _agoraService.getCallStats();

        // Update metrics based on Agora data
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

        // Determine network quality based on metrics
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
        debugPrint('Error updating quality metrics: $e');
      }
    });
  }

  /// Update network quality based on current metrics
  void _updateNetworkQuality() {
    if (_currentCallMetrics == null) return;

    final packetLoss = _currentCallMetrics!.packetLoss;
    final bitrate = _currentCallMetrics!.bitrate;

    // Simple quality assessment (would be more sophisticated in production)
    if (packetLoss < 1 && bitrate > 500) {
      _currentCallMetrics!.networkQuality = 'excellent';
    } else if (packetLoss < 3 && bitrate > 200) {
      _currentCallMetrics!.networkQuality = 'good';
    } else if (packetLoss < 10 && bitrate > 50) {
      _currentCallMetrics!.networkQuality = 'poor';
    } else {
      _currentCallMetrics!.networkQuality = 'bad';
    }
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
