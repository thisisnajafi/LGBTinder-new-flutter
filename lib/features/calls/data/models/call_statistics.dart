/// Call statistics model for analytics
class CallStatistics {
  final int totalCalls;
  final int totalCallDuration; // in seconds
  final int audioCalls;
  final int videoCalls;
  final int missedCalls;
  final int declinedCalls;
  final int completedCalls;
  final double averageCallDuration; // in seconds
  final int longestCall; // in seconds
  final Map<String, int> callsByDay; // date -> count
  final Map<String, int> callsByHour; // hour -> count
  final Map<String, int> callsByStatus; // status -> count
  final DateTime periodStart;
  final DateTime periodEnd;

  CallStatistics({
    required this.totalCalls,
    required this.totalCallDuration,
    required this.audioCalls,
    required this.videoCalls,
    required this.missedCalls,
    required this.declinedCalls,
    required this.completedCalls,
    required this.averageCallDuration,
    required this.longestCall,
    required this.callsByDay,
    required this.callsByHour,
    required this.callsByStatus,
    required this.periodStart,
    required this.periodEnd,
  });

  factory CallStatistics.fromJson(Map<String, dynamic> json) {
    return CallStatistics(
      totalCalls: json['total_calls'] != null ? ((json['total_calls'] is int) ? json['total_calls'] as int : int.tryParse(json['total_calls'].toString()) ?? 0) : 0,
      totalCallDuration: json['total_call_duration'] != null ? ((json['total_call_duration'] is int) ? json['total_call_duration'] as int : int.tryParse(json['total_call_duration'].toString()) ?? 0) : 0,
      audioCalls: json['audio_calls'] != null ? ((json['audio_calls'] is int) ? json['audio_calls'] as int : int.tryParse(json['audio_calls'].toString()) ?? 0) : 0,
      videoCalls: json['video_calls'] != null ? ((json['video_calls'] is int) ? json['video_calls'] as int : int.tryParse(json['video_calls'].toString()) ?? 0) : 0,
      missedCalls: json['missed_calls'] != null ? ((json['missed_calls'] is int) ? json['missed_calls'] as int : int.tryParse(json['missed_calls'].toString()) ?? 0) : 0,
      declinedCalls: json['declined_calls'] != null ? ((json['declined_calls'] is int) ? json['declined_calls'] as int : int.tryParse(json['declined_calls'].toString()) ?? 0) : 0,
      completedCalls: json['completed_calls'] != null ? ((json['completed_calls'] is int) ? json['completed_calls'] as int : int.tryParse(json['completed_calls'].toString()) ?? 0) : 0,
      averageCallDuration: (json['average_call_duration'] as num?)?.toDouble() ?? 0.0,
      longestCall: json['longest_call'] != null ? ((json['longest_call'] is int) ? json['longest_call'] as int : int.tryParse(json['longest_call'].toString()) ?? 0) : 0,
      callsByDay: json['calls_by_day'] != null && json['calls_by_day'] is Map
          ? Map<String, int>.from((json['calls_by_day'] as Map).map((k, v) => MapEntry(k.toString(), (v is int) ? v : int.tryParse(v.toString()) ?? 0)))
          : {},
      callsByHour: json['calls_by_hour'] != null && json['calls_by_hour'] is Map
          ? Map<String, int>.from((json['calls_by_hour'] as Map).map((k, v) => MapEntry(k.toString(), (v is int) ? v : int.tryParse(v.toString()) ?? 0)))
          : {},
      callsByStatus: json['calls_by_status'] != null && json['calls_by_status'] is Map
          ? Map<String, int>.from((json['calls_by_status'] as Map).map((k, v) => MapEntry(k.toString(), (v is int) ? v : int.tryParse(v.toString()) ?? 0)))
          : {},
      periodStart: json['period_start'] != null
          ? (DateTime.tryParse(json['period_start'].toString()) ?? DateTime.now().subtract(const Duration(days: 30)))
          : DateTime.now().subtract(const Duration(days: 30)),
      periodEnd: json['period_end'] != null
          ? (DateTime.tryParse(json['period_end'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_calls': totalCalls,
      'total_call_duration': totalCallDuration,
      'audio_calls': audioCalls,
      'video_calls': videoCalls,
      'missed_calls': missedCalls,
      'declined_calls': declinedCalls,
      'completed_calls': completedCalls,
      'average_call_duration': averageCallDuration,
      'longest_call': longestCall,
      'calls_by_day': callsByDay,
      'calls_by_hour': callsByHour,
      'calls_by_status': callsByStatus,
      'period_start': periodStart.toIso8601String(),
      'period_end': periodEnd.toIso8601String(),
    };
  }

  /// Get total call duration formatted
  String get totalDurationFormatted {
    final hours = totalCallDuration ~/ 3600;
    final minutes = (totalCallDuration % 3600) ~/ 60;
    final seconds = totalCallDuration % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  /// Get average call duration formatted
  String get averageDurationFormatted {
    final minutes = averageCallDuration ~/ 60;
    final seconds = (averageCallDuration % 60).round();
    return '${minutes}m ${seconds}s';
  }

  /// Get completion rate percentage
  double get completionRate {
    if (totalCalls == 0) return 0.0;
    return (completedCalls / totalCalls) * 100;
  }

  /// Get most active hour
  int get mostActiveHour {
    if (callsByHour.isEmpty) return 0;
    return callsByHour.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key as int;
  }

  /// Get call type distribution
  Map<String, double> get callTypeDistribution {
    if (totalCalls == 0) return {};
    return {
      'audio': (audioCalls / totalCalls) * 100,
      'video': (videoCalls / totalCalls) * 100,
    };
  }
}

/// Call eligibility model
class CallEligibility {
  final bool canCall;
  final String? reason; // if canCall is false
  final bool isPremiumRequired;
  final bool isMatchRequired;
  final int? cooldownMinutes; // if user needs to wait

  CallEligibility({
    required this.canCall,
    this.reason,
    this.isPremiumRequired = false,
    this.isMatchRequired = false,
    this.cooldownMinutes,
  });

  factory CallEligibility.fromJson(Map<String, dynamic> json) {
    return CallEligibility(
      canCall: json['can_call'] == true || json['can_call'] == 1,
      reason: json['reason']?.toString(),
      isPremiumRequired: json['is_premium_required'] == true || json['is_premium_required'] == 1,
      isMatchRequired: json['is_match_required'] == true || json['is_match_required'] == 1,
      cooldownMinutes: json['cooldown_minutes'] != null ? ((json['cooldown_minutes'] is int) ? json['cooldown_minutes'] as int : int.tryParse(json['cooldown_minutes'].toString())) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'can_call': canCall,
      if (reason != null) 'reason': reason,
      'is_premium_required': isPremiumRequired,
      'is_match_required': isMatchRequired,
      if (cooldownMinutes != null) 'cooldown_minutes': cooldownMinutes,
    };
  }
}

/// Call issue report model
class CallIssueReport {
  final String callId;
  final String issueType; // 'audio_quality', 'video_quality', 'connection', 'other'
  final String description;
  final int severity; // 1-5, 5 being most severe
  final Map<String, dynamic> technicalDetails;

  CallIssueReport({
    required this.callId,
    required this.issueType,
    required this.description,
    required this.severity,
    this.technicalDetails = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'call_id': callId,
      'issue_type': issueType,
      'description': description,
      'severity': severity,
      'technical_details': technicalDetails,
    };
  }
}

/// Call quality metrics model
class CallQualityMetrics {
  final String callId;
  final double audioQuality; // 0-100
  final double videoQuality; // 0-100
  final int packetLoss; // percentage
  final int jitter; // milliseconds
  final int latency; // milliseconds
  final DateTime measuredAt;

  CallQualityMetrics({
    required this.callId,
    required this.audioQuality,
    required this.videoQuality,
    required this.packetLoss,
    required this.jitter,
    required this.latency,
    required this.measuredAt,
  });

  factory CallQualityMetrics.fromJson(Map<String, dynamic> json) {
    // Validate required fields
    if (json['call_id'] == null) {
      throw FormatException('CallQualityMetrics.fromJson: call_id is required but was null');
    }
    
    return CallQualityMetrics(
      callId: json['call_id'].toString(),
      audioQuality: (json['audio_quality'] as num?)?.toDouble() ?? 0.0,
      videoQuality: (json['video_quality'] as num?)?.toDouble() ?? 0.0,
      packetLoss: json['packet_loss'] != null ? ((json['packet_loss'] is int) ? json['packet_loss'] as int : int.tryParse(json['packet_loss'].toString()) ?? 0) : 0,
      jitter: json['jitter'] != null ? ((json['jitter'] is int) ? json['jitter'] as int : int.tryParse(json['jitter'].toString()) ?? 0) : 0,
      latency: json['latency'] != null ? ((json['latency'] is int) ? json['latency'] as int : int.tryParse(json['latency'].toString()) ?? 0) : 0,
      measuredAt: json['measured_at'] != null
          ? (DateTime.tryParse(json['measured_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'call_id': callId,
      'audio_quality': audioQuality,
      'video_quality': videoQuality,
      'packet_loss': packetLoss,
      'jitter': jitter,
      'latency': latency,
      'measured_at': measuredAt.toIso8601String(),
    };
  }

  /// Check if quality is good
  bool get isGoodQuality {
    return audioQuality >= 80 && videoQuality >= 80 && latency <= 150;
  }

  /// Check if quality is poor
  bool get isPoorQuality {
    return audioQuality < 60 || videoQuality < 60 || latency > 300;
  }

  /// Get overall quality score
  double get overallQuality {
    // Weighted average: audio 40%, video 40%, latency 20%
    final latencyScore = latency <= 100 ? 100 : (latency >= 500 ? 0 : 100 - ((latency - 100) / 4));
    return (audioQuality * 0.4) + (videoQuality * 0.4) + (latencyScore * 0.2);
  }
}
