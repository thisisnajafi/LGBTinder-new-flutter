/// Why two users matched — surfaced on discovery cards and profile sheet.
class MatchReason {
  final String type;
  final String label;

  const MatchReason({
    required this.type,
    required this.label,
  });

  factory MatchReason.fromJson(Map<String, dynamic> json) {
    return MatchReason(
      type: json['type']?.toString() ?? 'unknown',
      label: json['label']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'label': label,
      };
}
