/// Profile verification model
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
    final data = json['data'] as Map<String, dynamic>? ?? json;
    final verificationStatus = data['verification_status'] as Map<String, dynamic>? ?? {};

    return ProfileVerification(
      photoVerified: verificationStatus['photo_verified'] as bool? ?? false,
      idVerified: verificationStatus['id_verified'] as bool? ?? false,
      videoVerified: verificationStatus['video_verified'] as bool? ?? false,
      verificationScore: verificationStatus['verification_score'] as int? ?? 0,
      totalVerifications: verificationStatus['total_verifications'] as int? ?? 0,
      pendingVerificationsCount: verificationStatus['pending_verifications'] as int? ?? 0,
      verificationBadge: data['verification_badge'] as String? ?? 'Unverified',
      canSubmitPhoto: data['can_submit_photo'] as bool? ?? false,
      canSubmitId: data['can_submit_id'] as bool? ?? false,
      canSubmitVideo: data['can_submit_video'] as bool? ?? false,
      pendingVerifications: data['pending_verifications_list'] != null
          ? (data['pending_verifications_list'] as List)
              .map((item) => PendingVerification.fromJson(item as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'photo_verified': photoVerified,
      'id_verified': idVerified,
      'video_verified': videoVerified,
      'verification_score': verificationScore,
      'total_verifications': totalVerifications,
      'pending_verifications': pendingVerifications,
      'verification_badge': verificationBadge,
      'can_submit_photo': canSubmitPhoto,
      'can_submit_id': canSubmitId,
      'can_submit_video': canSubmitVideo,
      if (pendingVerifications != null)
        'pending_verifications': pendingVerifications!.map((e) => e.toJson()).toList(),
    };
  }
}

/// Pending verification model
class PendingVerification {
  final int id;
  final String type;
  final String status;
  final String? submittedAt;

  PendingVerification({
    required this.id,
    required this.type,
    required this.status,
    this.submittedAt,
  });

  factory PendingVerification.fromJson(Map<String, dynamic> json) {
    return PendingVerification(
      id: json['id'] as int,
      type: json['type'] as String,
      status: json['status'] as String,
      submittedAt: json['submitted_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'status': status,
      if (submittedAt != null) 'submitted_at': submittedAt,
    };
  }
}
