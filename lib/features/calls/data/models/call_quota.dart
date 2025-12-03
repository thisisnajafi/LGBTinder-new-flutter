/// Call quota model - represents user's call limits and usage
class CallQuota {
  final int totalMinutes;
  final int usedMinutes;
  final DateTime? resetsAt;

  CallQuota({
    required this.totalMinutes,
    required this.usedMinutes,
    this.resetsAt,
  });

  factory CallQuota.fromJson(Map<String, dynamic> json) {
    return CallQuota(
      totalMinutes: json['total_minutes'] as int? ?? 0,
      usedMinutes: json['used_minutes'] as int? ?? 0,
      resetsAt: json['resets_at'] != null
          ? DateTime.parse(json['resets_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_minutes': totalMinutes,
      'used_minutes': usedMinutes,
      'resets_at': resetsAt?.toIso8601String(),
    };
  }
}
