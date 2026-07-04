/// Profile verification models
class ProfileVerification {
  final bool photoVerified;
  final bool idVerified;
  final bool videoVerified;
  final int verificationScore;
  final int totalVerifications;
  final int pendingVerificationsCount;
  final String verificationBadge;
  final bool canSubmitPhoto;
  final bool canSubmitId;
  final bool canSubmitVideo;
  final List<PendingVerification>? pendingVerifications;

  ProfileVerification({
    required this.photoVerified,
    required this.idVerified,
    required this.videoVerified,
    required this.verificationScore,
    required this.totalVerifications,
    required this.pendingVerificationsCount,
    required this.verificationBadge,
    required this.canSubmitPhoto,
    required this.canSubmitId,
    required this.canSubmitVideo,
    this.pendingVerifications,
  });

  factory ProfileVerification.fromJson(Map<String, dynamic> json) {
    final data = json['data'] != null && json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : json;
    final verificationStatus = data['verification_status'] != null &&
            data['verification_status'] is Map
        ? Map<String, dynamic>.from(data['verification_status'] as Map)
        : <String, dynamic>{};

    final pendingArray = data['pending_verifications'];
    List<PendingVerification>? pendingList;
    if (pendingArray is List) {
      pendingList = pendingArray
          .whereType<Map>()
          .map((item) =>
              PendingVerification.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }

    return ProfileVerification(
      photoVerified: verificationStatus['photo_verified'] == true ||
          verificationStatus['photo_verified'] == 1,
      idVerified: verificationStatus['id_verified'] == true ||
          verificationStatus['id_verified'] == 1,
      videoVerified: verificationStatus['video_verified'] == true ||
          verificationStatus['video_verified'] == 1,
      verificationScore: _parseInt(verificationStatus['verification_score']) ?? 0,
      totalVerifications:
          _parseInt(verificationStatus['total_verifications']) ?? 0,
      pendingVerificationsCount:
          _parseInt(verificationStatus['pending_verifications']) ?? 0,
      verificationBadge: data['verification_badge']?.toString() ?? 'Unverified',
      canSubmitPhoto:
          data['can_submit_photo'] == true || data['can_submit_photo'] == 1,
      canSubmitId: data['can_submit_id'] == true || data['can_submit_id'] == 1,
      canSubmitVideo:
          data['can_submit_video'] == true || data['can_submit_video'] == 1,
      pendingVerifications: pendingList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'photo_verified': photoVerified,
      'id_verified': idVerified,
      'video_verified': videoVerified,
      'verification_score': verificationScore,
      'total_verifications': totalVerifications,
      'pending_verifications': pendingVerificationsCount,
      'verification_badge': verificationBadge,
      'can_submit_photo': canSubmitPhoto,
      'can_submit_id': canSubmitId,
      'can_submit_video': canSubmitVideo,
      if (pendingVerifications != null)
        'pending_verifications':
            pendingVerifications!.map((e) => e.toJson()).toList(),
    };
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}

/// Identity verification block on user profile API responses.
class ProfileIdentityVerification {
  final int score;
  final String badge;
  final bool photoVerified;
  final bool idVerified;
  final bool videoVerified;
  final DateTime? photoVerifiedAt;
  final DateTime? idVerifiedAt;
  final DateTime? videoVerifiedAt;

  const ProfileIdentityVerification({
    this.score = 0,
    this.badge = 'Unverified',
    this.photoVerified = false,
    this.idVerified = false,
    this.videoVerified = false,
    this.photoVerifiedAt,
    this.idVerifiedAt,
    this.videoVerifiedAt,
  });

  factory ProfileIdentityVerification.fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) {
      return const ProfileIdentityVerification();
    }
    return ProfileIdentityVerification(
      score: ProfileVerification._parseInt(json['score']) ?? 0,
      badge: json['badge']?.toString() ?? 'Unverified',
      photoVerified:
          json['photo_verified'] == true || json['photo_verified'] == 1,
      idVerified: json['id_verified'] == true || json['id_verified'] == 1,
      videoVerified:
          json['video_verified'] == true || json['video_verified'] == 1,
      photoVerifiedAt: _parseDate(json['photo_verified_at']),
      idVerifiedAt: _parseDate(json['id_verified_at']),
      videoVerifiedAt: _parseDate(json['video_verified_at']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  bool get hasAnyVerified => photoVerified || idVerified || videoVerified;

  bool get isFullyVerified => badge == 'Fully Verified' || score >= 100;
}

/// Pending verification model
class PendingVerification {
  final int id;
  final String type;
  final String status;
  final DateTime? submittedAt;

  PendingVerification({
    required this.id,
    required this.type,
    required this.status,
    this.submittedAt,
  });

  factory PendingVerification.fromJson(Map<String, dynamic> json) {
    int verificationId = 0;
    if (json['id'] != null) {
      verificationId = ProfileVerification._parseInt(json['id']) ?? 0;
    } else if (json['verification_id'] != null) {
      verificationId =
          ProfileVerification._parseInt(json['verification_id']) ?? 0;
    }

    return PendingVerification(
      id: verificationId,
      type: json['type']?.toString() ??
          json['verification_type']?.toString() ??
          'photo',
      status: json['status']?.toString() ??
          json['verification_status']?.toString() ??
          'pending',
      submittedAt: json['submitted_at'] != null
          ? DateTime.tryParse(json['submitted_at'].toString())
          : (json['submittedAt'] != null
              ? DateTime.tryParse(json['submittedAt'].toString())
              : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'status': status,
      if (submittedAt != null) 'submitted_at': submittedAt!.toIso8601String(),
    };
  }
}

/// Submit response from verification upload endpoints.
class VerificationSubmitResult {
  final int verificationId;
  final DateTime submittedAt;

  VerificationSubmitResult({
    required this.verificationId,
    required this.submittedAt,
  });

  factory VerificationSubmitResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : json;
    return VerificationSubmitResult(
      verificationId: ProfileVerification._parseInt(data['verification_id']) ?? 0,
      submittedAt: DateTime.tryParse(
            data['submitted_at']?.toString() ?? '',
          ) ??
          DateTime.now(),
    );
  }
}

/// History item from GET /verification/history
class VerificationHistoryItem {
  final int id;
  final String type;
  final String typeLabel;
  final String status;
  final String statusLabel;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final String? adminNotes;
  final String? reviewerName;
  final String? fileUrl;

  VerificationHistoryItem({
    required this.id,
    required this.type,
    required this.typeLabel,
    required this.status,
    required this.statusLabel,
    this.submittedAt,
    this.reviewedAt,
    this.adminNotes,
    this.reviewerName,
    this.fileUrl,
  });

  factory VerificationHistoryItem.fromJson(Map<String, dynamic> json) {
    return VerificationHistoryItem(
      id: ProfileVerification._parseInt(json['id']) ?? 0,
      type: json['type']?.toString() ?? 'photo',
      typeLabel: json['type_label']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      statusLabel: json['status_label']?.toString() ?? '',
      submittedAt: json['submitted_at'] != null
          ? DateTime.tryParse(json['submitted_at'].toString())
          : null,
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.tryParse(json['reviewed_at'].toString())
          : null,
      adminNotes: json['admin_notes']?.toString(),
      reviewerName: json['reviewer_name']?.toString(),
      fileUrl: json['file_url']?.toString(),
    );
  }
}

/// Guidelines per verification type from GET /verification/guidelines
class VerificationGuidelines {
  final Map<String, dynamic> photo;
  final Map<String, dynamic> id;
  final Map<String, dynamic> video;

  VerificationGuidelines({
    required this.photo,
    required this.id,
    required this.video,
  });

  factory VerificationGuidelines.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : json;
    return VerificationGuidelines(
      photo: data['photo_verification'] is Map
          ? Map<String, dynamic>.from(data['photo_verification'] as Map)
          : {},
      id: data['id_verification'] is Map
          ? Map<String, dynamic>.from(data['id_verification'] as Map)
          : {},
      video: data['video_verification'] is Map
          ? Map<String, dynamic>.from(data['video_verification'] as Map)
          : {},
    );
  }

  String descriptionFor(String type) {
    final map = switch (type) {
      'id' => id,
      'video' => video,
      _ => photo,
    };
    return map['description']?.toString() ?? '';
  }
}
