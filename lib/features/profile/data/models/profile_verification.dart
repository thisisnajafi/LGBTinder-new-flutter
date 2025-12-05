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
    final data = json['data'] != null && json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : json;
    final verificationStatus = data['verification_status'] != null && data['verification_status'] is Map
        ? Map<String, dynamic>.from(data['verification_status'] as Map)
        : <String, dynamic>{};

    return ProfileVerification(
      photoVerified: verificationStatus['photo_verified'] == true || verificationStatus['photo_verified'] == 1,
      idVerified: verificationStatus['id_verified'] == true || verificationStatus['id_verified'] == 1,
      videoVerified: verificationStatus['video_verified'] == true || verificationStatus['video_verified'] == 1,
      verificationScore: verificationStatus['verification_score'] != null 
          ? ((verificationStatus['verification_score'] is int) ? verificationStatus['verification_score'] as int : int.tryParse(verificationStatus['verification_score'].toString()) ?? 0)
          : 0,
      totalVerifications: verificationStatus['total_verifications'] != null 
          ? ((verificationStatus['total_verifications'] is int) ? verificationStatus['total_verifications'] as int : int.tryParse(verificationStatus['total_verifications'].toString()) ?? 0)
          : 0,
      pendingVerificationsCount: verificationStatus['pending_verifications'] != null 
          ? ((verificationStatus['pending_verifications'] is int) ? verificationStatus['pending_verifications'] as int : int.tryParse(verificationStatus['pending_verifications'].toString()) ?? 0)
          : 0,
      verificationBadge: data['verification_badge']?.toString() ?? 'Unverified',
      canSubmitPhoto: data['can_submit_photo'] == true || data['can_submit_photo'] == 1,
      canSubmitId: data['can_submit_id'] == true || data['can_submit_id'] == 1,
      canSubmitVideo: data['can_submit_video'] == true || data['can_submit_video'] == 1,
      pendingVerifications: data['pending_verifications_list'] != null && data['pending_verifications_list'] is List
          ? (data['pending_verifications_list'] as List)
              .map((item) => PendingVerification.fromJson(Map<String, dynamic>.from(item as Map)))
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
    // Get ID - use 0 as fallback
    int verificationId = 0;
    if (json['id'] != null) {
      verificationId = (json['id'] is int) ? json['id'] as int : int.tryParse(json['id'].toString()) ?? 0;
    } else if (json['verification_id'] != null) {
      verificationId = (json['verification_id'] is int) ? json['verification_id'] as int : int.tryParse(json['verification_id'].toString()) ?? 0;
    }
    
    // Get type - default to 'photo' if missing
    String verificationType = json['type']?.toString() ?? 
                               json['verification_type']?.toString() ?? 
                               'photo';
    
    // Get status - default to 'pending' if missing
    String verificationStatus = json['status']?.toString() ?? 
                                 json['verification_status']?.toString() ?? 
                                 'pending';
    
    return PendingVerification(
      id: verificationId,
      type: verificationType,
      status: verificationStatus,
      submittedAt: json['submitted_at']?.toString() ?? json['submittedAt']?.toString(),
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
