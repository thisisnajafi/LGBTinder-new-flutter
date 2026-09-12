/// Photo or video sent in a 1:1 chat (used by Chat info).
class SharedMediaItem {
  const SharedMediaItem({
    required this.url,
    required this.isVideo,
    this.messageId,
  });

  final String url;
  final bool isVideo;
  final int? messageId;

  Map<String, dynamic> toJson() => {
        'url': url,
        'is_video': isVideo,
        if (messageId != null) 'message_id': messageId,
      };

  factory SharedMediaItem.fromJson(Map<String, dynamic> json) {
    return SharedMediaItem(
      url: json['url']?.toString() ?? '',
      isVideo: json['is_video'] == true || json['is_video'] == 1,
      messageId: json['message_id'] is int
          ? json['message_id'] as int
          : int.tryParse(json['message_id']?.toString() ?? ''),
    );
  }
}
