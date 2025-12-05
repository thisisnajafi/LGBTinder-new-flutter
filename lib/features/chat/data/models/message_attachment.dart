/// Message attachment model
enum AttachmentType {
  image,
  video,
  voice,
  file,
  location,
}

class MessageAttachment {
  final int id;
  final String url;
  final String filename;
  final String mimeType;
  final int size; // in bytes
  final AttachmentType type;
  final double? width; // for images/videos
  final double? height; // for images/videos
  final double? duration; // for videos/voice
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  MessageAttachment({
    required this.id,
    required this.url,
    required this.filename,
    required this.mimeType,
    required this.size,
    required this.type,
    this.width,
    this.height,
    this.duration,
    this.metadata,
    required this.createdAt,
  });

  factory MessageAttachment.fromJson(Map<String, dynamic> json) {
    // Validate required fields
    if (json['id'] == null) {
      throw FormatException('MessageAttachment.fromJson: id is required but was null');
    }
    if (json['url'] == null) {
      throw FormatException('MessageAttachment.fromJson: url is required but was null');
    }
    if (json['filename'] == null) {
      throw FormatException('MessageAttachment.fromJson: filename is required but was null');
    }
    
    // Determine attachment type from mime type
    final mimeType = json['mime_type']?.toString() ?? '';
    final type = _determineAttachmentType(mimeType);

    return MessageAttachment(
      id: (json['id'] is int) ? json['id'] as int : int.parse(json['id'].toString()),
      url: json['url'].toString(),
      filename: json['filename'].toString(),
      mimeType: mimeType,
      size: json['size'] != null ? ((json['size'] is int) ? json['size'] as int : int.tryParse(json['size'].toString()) ?? 0) : 0,
      type: type,
      width: json['width'] != null ? (json['width'] as num).toDouble() : null,
      height: json['height'] != null ? (json['height'] as num).toDouble() : null,
      duration: json['duration'] != null ? (json['duration'] as num).toDouble() : null,
      metadata: json['metadata'] != null && json['metadata'] is Map
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : null,
      createdAt: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'filename': filename,
      'mime_type': mimeType,
      'size': size,
      'type': type.toString().split('.').last,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (duration != null) 'duration': duration,
      if (metadata != null) 'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
    };
  }

  static AttachmentType _determineAttachmentType(String mimeType) {
    if (mimeType.startsWith('image/')) {
      return AttachmentType.image;
    } else if (mimeType.startsWith('video/')) {
      return AttachmentType.video;
    } else if (mimeType.startsWith('audio/')) {
      return AttachmentType.voice;
    } else if (mimeType.contains('location') || mimeType.contains('gps')) {
      return AttachmentType.location;
    } else {
      return AttachmentType.file;
    }
  }

  /// Check if attachment is an image
  bool get isImage => type == AttachmentType.image;

  /// Check if attachment is a video
  bool get isVideo => type == AttachmentType.video;

  /// Check if attachment is voice/audio
  bool get isVoice => type == AttachmentType.voice;

  /// Check if attachment is a location
  bool get isLocation => type == AttachmentType.location;

  /// Get formatted file size
  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Get formatted duration for videos/audio
  String get formattedDuration {
    if (duration == null) return '';
    final minutes = (duration! / 60).floor();
    final seconds = (duration! % 60).round();
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

/// Upload attachment request
class UploadAttachmentRequest {
  final String filePath;
  final String filename;
  final String mimeType;

  UploadAttachmentRequest({
    required this.filePath,
    required this.filename,
    required this.mimeType,
  });
}
