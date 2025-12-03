import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  );
});

/// Profile state
class ProfileState {
  final UserProfile? profile;
  final List<UserImage> images;
  final ProfileVerification? verification;
  final ProfileCompletion? completion;
  final bool isLoading;
  final String? error;
  final bool isUpdating;
  final bool isUploadingImage;

  ProfileState({
    this.profile,
    this.images = const [],
    this.verification,
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
    ProfileCompletion? completion,
    bool? isLoading,
    String? error,
    bool? isUpdating,
    bool? isUploadingImage,
  }) {
    return ProfileState(
      profile: profile ?? this.profile,
      images: images ?? this.images,
      verification: verification ?? this.verification,
      completion: completion ?? this.completion,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
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

  ProfileNotifier({
    required GetProfileUseCase getProfileUseCase,
    required UpdateProfileUseCase updateProfileUseCase,
    required UploadImageUseCase uploadImageUseCase,
    required DeleteImageUseCase deleteImageUseCase,
    required VerifyProfileUseCase verifyProfileUseCase,
    required CompleteProfileUseCase completeProfileUseCase,
  }) : _getProfileUseCase = getProfileUseCase,
       _updateProfileUseCase = updateProfileUseCase,
       _uploadImageUseCase = uploadImageUseCase,
       _deleteImageUseCase = deleteImageUseCase,
       _verifyProfileUseCase = verifyProfileUseCase,
       _completeProfileUseCase = completeProfileUseCase,
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
    try {
      final verification = await _verifyProfileUseCase.getVerificationStatus();
      state = state.copyWith(verification: verification);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Submit photo verification
  Future<void> submitPhotoVerification(String photoPath) async {
    try {
      final verification = await _verifyProfileUseCase.submitPhotoVerification(photoPath);
      state = state.copyWith(verification: verification);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Submit ID verification
  Future<void> submitIdVerification(String idPath) async {
    try {
      final verification = await _verifyProfileUseCase.submitIdVerification(idPath);
      state = state.copyWith(verification: verification);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Submit video verification
  Future<void> submitVideoVerification(String videoPath) async {
    try {
      final verification = await _verifyProfileUseCase.submitVideoVerification(videoPath);
      state = state.copyWith(verification: verification);
    } catch (e) {
      state = state.copyWith(error: e.toString());
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

// Use case providers
final getProfileUseCaseProvider = Provider<GetProfileUseCase>((ref) {
  throw UnimplementedError('GetProfileUseCase must be overridden in the provider scope');
});

final updateProfileUseCaseProvider = Provider<UpdateProfileUseCase>((ref) {
  throw UnimplementedError('UpdateProfileUseCase must be overridden in the provider scope');
});

final uploadImageUseCaseProvider = Provider<UploadImageUseCase>((ref) {
  throw UnimplementedError('UploadImageUseCase must be overridden in the provider scope');
});

final deleteImageUseCaseProvider = Provider<DeleteImageUseCase>((ref) {
  throw UnimplementedError('DeleteImageUseCase must be overridden in the provider scope');
});

final verifyProfileUseCaseProvider = Provider<VerifyProfileUseCase>((ref) {
  throw UnimplementedError('VerifyProfileUseCase must be overridden in the provider scope');
});

final completeProfileUseCaseProvider = Provider<CompleteProfileUseCase>((ref) {
  throw UnimplementedError('CompleteProfileUseCase must be overridden in the provider scope');
});
