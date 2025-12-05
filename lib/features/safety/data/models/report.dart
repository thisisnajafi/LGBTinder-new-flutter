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
    // Validate required fields
    if (json['id'] == null) {
      throw FormatException('Report.fromJson: id is required but was null');
    }
    if (json['reason'] == null) {
      throw FormatException('Report.fromJson: reason is required but was null');
    }
    
    // Get user ID - validate it exists
    int reportedUserId;
    if (json['reported_user_id'] != null) {
      reportedUserId = (json['reported_user_id'] is int) ? json['reported_user_id'] as int : int.parse(json['reported_user_id'].toString());
    } else if (json['user_id'] != null) {
      reportedUserId = (json['user_id'] is int) ? json['user_id'] as int : int.parse(json['user_id'].toString());
    } else {
      throw FormatException('Report.fromJson: reported_user_id (or user_id) is required but was null');
    }
    
    return Report(
      id: (json['id'] is int) ? json['id'] as int : int.parse(json['id'].toString()),
      reportedUserId: reportedUserId,
      reason: json['reason'].toString(),
      description: json['description']?.toString(),
      reportedAt: json['reported_at'] != null
          ? (DateTime.tryParse(json['reported_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
      status: json['status']?.toString(),
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
