import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/cache/cache_invalidator.dart';
import '../../../core/providers/api_providers.dart';
import '../../../shared/services/token_storage_service.dart';
import '../../../core/network/dio_client.dart';
import '../domain/services/profile_service.dart' as domain;
import '../data/repositories/profile_repository.dart';
import '../data/models/user_profile.dart';
import '../data/models/update_profile_request.dart';
import '../data/models/user_image.dart';
import '../data/models/profile_verification.dart';
import '../data/models/profile_completion.dart';
import '../domain/use_cases/get_profile_use_case.dart';
import '../domain/use_cases/update_profile_use_case.dart';
import '../domain/use_cases/upload_image_use_case.dart';
import '../domain/use_cases/delete_image_use_case.dart';
import '../domain/use_cases/verify_profile_use_case.dart';
import '../domain/use_cases/complete_profile_use_case.dart';

/// Profile provider - manages profile state and operations
final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  final getProfileUseCase = ref.watch(getProfileUseCaseProvider);
  final updateProfileUseCase = ref.watch(updateProfileUseCaseProvider);
  final uploadImageUseCase = ref.watch(uploadImageUseCaseProvider);
  final deleteImageUseCase = ref.watch(deleteImageUseCaseProvider);
  final verifyProfileUseCase = ref.watch(verifyProfileUseCaseProvider);
  final completeProfileUseCase = ref.watch(completeProfileUseCaseProvider);

  return ProfileNotifier(
    getProfileUseCase: getProfileUseCase,
    updateProfileUseCase: updateProfileUseCase,
    uploadImageUseCase: uploadImageUseCase,
    deleteImageUseCase: deleteImageUseCase,
    verifyProfileUseCase: verifyProfileUseCase,
    completeProfileUseCase: completeProfileUseCase,
    onProfileUpdated: (userId) =>
        ref.read(cacheInvalidatorProvider).purgeProfile(userId),
  );
});

/// Upload progress for a verification type submission.
class VerificationUploadState {
  final String? activeType;
  final double progress;
  final bool isUploading;

  const VerificationUploadState({
    this.activeType,
    this.progress = 0,
    this.isUploading = false,
  });

  VerificationUploadState copyWith({
    String? activeType,
    double? progress,
    bool? isUploading,
  }) {
    return VerificationUploadState(
      activeType: activeType ?? this.activeType,
      progress: progress ?? this.progress,
      isUploading: isUploading ?? this.isUploading,
    );
  }
}

/// Profile state
class ProfileState {
  final UserProfile? profile;
  final List<UserImage> images;
  final ProfileVerification? verification;
  final VerificationGuidelines? verificationGuidelines;
  final List<VerificationHistoryItem> verificationHistory;
  final VerificationUploadState verificationUpload;
  final bool isVerificationLoading;
  final bool isVerificationHistoryLoading;
  final ProfileCompletion? completion;
  final bool isLoading;
  final String? error;
  final bool isUpdating;
  final bool isUploadingImage;

  ProfileState({
    this.profile,
    this.images = const [],
    this.verification,
    this.verificationGuidelines,
    this.verificationHistory = const [],
    this.verificationUpload = const VerificationUploadState(),
    this.isVerificationLoading = false,
    this.isVerificationHistoryLoading = false,
    this.completion,
    this.isLoading = false,
    this.error,
    this.isUpdating = false,
    this.isUploadingImage = false,
  });

  ProfileState copyWith({
    UserProfile? profile,
    List<UserImage>? images,
    ProfileVerification? verification,
    VerificationGuidelines? verificationGuidelines,
    List<VerificationHistoryItem>? verificationHistory,
    VerificationUploadState? verificationUpload,
    bool? isVerificationLoading,
    bool? isVerificationHistoryLoading,
    ProfileCompletion? completion,
    bool? isLoading,
    String? error,
    bool? isUpdating,
    bool? isUploadingImage,
    bool clearError = false,
  }) {
    return ProfileState(
      profile: profile ?? this.profile,
      images: images ?? this.images,
      verification: verification ?? this.verification,
      verificationGuidelines:
          verificationGuidelines ?? this.verificationGuidelines,
      verificationHistory: verificationHistory ?? this.verificationHistory,
      verificationUpload: verificationUpload ?? this.verificationUpload,
      isVerificationLoading:
          isVerificationLoading ?? this.isVerificationLoading,
      isVerificationHistoryLoading:
          isVerificationHistoryLoading ?? this.isVerificationHistoryLoading,
      completion: completion ?? this.completion,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isUpdating: isUpdating ?? this.isUpdating,
      isUploadingImage: isUploadingImage ?? this.isUploadingImage,
    );
  }
}

/// Profile notifier
class ProfileNotifier extends StateNotifier<ProfileState> {
  final GetProfileUseCase _getProfileUseCase;
  final UpdateProfileUseCase _updateProfileUseCase;
  final UploadImageUseCase _uploadImageUseCase;
  final DeleteImageUseCase _deleteImageUseCase;
  final VerifyProfileUseCase _verifyProfileUseCase;
  final CompleteProfileUseCase _completeProfileUseCase;
  final Future<void> Function(String userId) _onProfileUpdated;

  ProfileNotifier({
    required GetProfileUseCase getProfileUseCase,
    required UpdateProfileUseCase updateProfileUseCase,
    required UploadImageUseCase uploadImageUseCase,
    required DeleteImageUseCase deleteImageUseCase,
    required VerifyProfileUseCase verifyProfileUseCase,
    required CompleteProfileUseCase completeProfileUseCase,
    required Future<void> Function(String userId) onProfileUpdated,
  }) : _getProfileUseCase = getProfileUseCase,
       _updateProfileUseCase = updateProfileUseCase,
       _uploadImageUseCase = uploadImageUseCase,
       _deleteImageUseCase = deleteImageUseCase,
       _verifyProfileUseCase = verifyProfileUseCase,
       _completeProfileUseCase = completeProfileUseCase,
       _onProfileUpdated = onProfileUpdated,
       super(ProfileState());

  /// Load user profile
  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final profile = await _getProfileUseCase.execute();
      state = state.copyWith(
        profile: profile,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Update user profile
  Future<void> updateProfile(UpdateProfileRequest request) async {
    state = state.copyWith(isUpdating: true, error: null);

    try {
      final updatedProfile = await _updateProfileUseCase.execute(request);
      state = state.copyWith(
        profile: updatedProfile,
        isUpdating: false,
      );
      await _onProfileUpdated(updatedProfile.id.toString());
    } catch (e) {
      state = state.copyWith(
        isUpdating: false,
        error: e.toString(),
      );
    }
  }

  /// Upload profile image
  Future<void> uploadImage(String imagePath) async {
    state = state.copyWith(isUploadingImage: true, error: null);

    try {
      final image = await _uploadImageUseCase.execute(imagePath);
      final updatedImages = [...state.images, image];
      state = state.copyWith(
        images: updatedImages,
        isUploadingImage: false,
      );
      final profileId = state.profile?.id;
      if (profileId != null) {
        await _onProfileUpdated(profileId.toString());
      }
    } catch (e) {
      state = state.copyWith(
        isUploadingImage: false,
        error: e.toString(),
      );
    }
  }

  /// Delete profile image
  Future<void> deleteImage(int imageId) async {
    try {
      await _deleteImageUseCase.execute(imageId);
      final updatedImages = state.images.where((image) => image.id != imageId).toList();
      state = state.copyWith(images: updatedImages);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Load verification status
  Future<void> loadVerificationStatus() async {
    state = state.copyWith(isVerificationLoading: true, clearError: true);
    try {
      final verification = await _verifyProfileUseCase.getVerificationStatus();
      state = state.copyWith(
        verification: verification,
        isVerificationLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isVerificationLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load verification guidelines
  Future<void> loadVerificationGuidelines() async {
    try {
      final guidelines =
          await _verifyProfileUseCase.getVerificationGuidelines();
      state = state.copyWith(verificationGuidelines: guidelines);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Load verification history
  Future<void> loadVerificationHistory() async {
    state = state.copyWith(isVerificationHistoryLoading: true);
    try {
      final history = await _verifyProfileUseCase.getVerificationHistory();
      state = state.copyWith(
        verificationHistory: history,
        isVerificationHistoryLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isVerificationHistoryLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> _submitWithProgress(
    String type,
    Future<ProfileVerification> Function(void Function(double) onProgress)
        submit,
  ) async {
    state = state.copyWith(
      verificationUpload: VerificationUploadState(
        activeType: type,
        isUploading: true,
        progress: 0,
      ),
      clearError: true,
    );
    try {
      final verification = await submit((progress) {
        state = state.copyWith(
          verificationUpload: state.verificationUpload.copyWith(
            progress: progress,
          ),
        );
      });
      state = state.copyWith(
        verification: verification,
        verificationUpload: const VerificationUploadState(),
      );
    } catch (e) {
      state = state.copyWith(
        verificationUpload: const VerificationUploadState(),
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Submit photo verification
  Future<void> submitPhotoVerification(String photoPath) async {
    await _submitWithProgress(
      'photo',
      (onProgress) => _verifyProfileUseCase.submitPhotoVerification(
        photoPath,
        onUploadProgress: onProgress,
      ),
    );
  }

  /// Submit ID verification
  Future<void> submitIdVerification(String idPath) async {
    await _submitWithProgress(
      'id',
      (onProgress) => _verifyProfileUseCase.submitIdVerification(
        idPath,
        onUploadProgress: onProgress,
      ),
    );
  }

  /// Submit video verification
  Future<void> submitVideoVerification(String videoPath) async {
    await _submitWithProgress(
      'video',
      (onProgress) => _verifyProfileUseCase.submitVideoVerification(
        videoPath,
        onUploadProgress: onProgress,
      ),
    );
  }

  /// Cancel a pending verification
  Future<void> cancelVerification(int verificationId) async {
    try {
      final verification =
          await _verifyProfileUseCase.cancelVerification(verificationId);
      state = state.copyWith(verification: verification, clearError: true);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// Load profile completion status
  Future<void> loadProfileCompletionStatus() async {
    try {
      final completion = await _completeProfileUseCase.execute();
      state = state.copyWith(completion: completion);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Domain profile API service (used by repository + use cases).
final domainProfileServiceProvider = Provider<domain.ProfileService>((ref) {
  return domain.ProfileService(
    ref.watch(apiServiceProvider),
    ref.watch(tokenStorageServiceProvider),
    ref.watch(dioClientProvider),
  );
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(domainProfileServiceProvider));
});

final getProfileUseCaseProvider = Provider<GetProfileUseCase>((ref) {
  return GetProfileUseCase(ref.watch(profileRepositoryProvider));
});

final updateProfileUseCaseProvider = Provider<UpdateProfileUseCase>((ref) {
  return UpdateProfileUseCase(ref.watch(profileRepositoryProvider));
});

final uploadImageUseCaseProvider = Provider<UploadImageUseCase>((ref) {
  return UploadImageUseCase(ref.watch(profileRepositoryProvider));
});

final deleteImageUseCaseProvider = Provider<DeleteImageUseCase>((ref) {
  return DeleteImageUseCase(ref.watch(profileRepositoryProvider));
});

final verifyProfileUseCaseProvider = Provider<VerifyProfileUseCase>((ref) {
  return VerifyProfileUseCase(ref.watch(profileRepositoryProvider));
});

final completeProfileUseCaseProvider = Provider<CompleteProfileUseCase>((ref) {
  return CompleteProfileUseCase(ref.watch(profileRepositoryProvider));
});
