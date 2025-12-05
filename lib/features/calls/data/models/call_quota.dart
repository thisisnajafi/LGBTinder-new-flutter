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
      totalMinutes: json['total_minutes'] != null ? ((json['total_minutes'] is int) ? json['total_minutes'] as int : int.tryParse(json['total_minutes'].toString()) ?? 0) : 0,
      usedMinutes: json['used_minutes'] != null ? ((json['used_minutes'] is int) ? json['used_minutes'] as int : int.tryParse(json['used_minutes'].toString()) ?? 0) : 0,
      resetsAt: json['resets_at'] != null
          ? DateTime.tryParse(json['resets_at'].toString())
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
