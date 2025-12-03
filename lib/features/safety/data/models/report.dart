/// Report model
class Report {
  final int id;
  final int reportedUserId;
  final String reason;
  final String? description;
  final DateTime reportedAt;
  final String? status; // 'pending', 'reviewed', 'resolved'

  Report({
    required this.id,
    required this.reportedUserId,
    required this.reason,
    this.description,
    required this.reportedAt,
    this.status,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'] as int,
      reportedUserId: json['reported_user_id'] as int? ?? json['user_id'] as int,
      reason: json['reason'] as String,
      description: json['description'] as String?,
      reportedAt: json['reported_at'] != null
          ? DateTime.parse(json['reported_at'] as String)
          : DateTime.now(),
      status: json['status'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reported_user_id': reportedUserId,
      'reason': reason,
      if (description != null) 'description': description,
      'reported_at': reportedAt.toIso8601String(),
      if (status != null) 'status': status,
    };
  }
}

/// Report user request
class ReportUserRequest {
  final int reportedUserId;
  final String reason;
  final String? description;

  ReportUserRequest({
    required this.reportedUserId,
    required this.reason,
    this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'reported_user_id': reportedUserId,
      'reason': reason,
      if (description != null && description!.isNotEmpty) 'description': description,
    };
  }
}
