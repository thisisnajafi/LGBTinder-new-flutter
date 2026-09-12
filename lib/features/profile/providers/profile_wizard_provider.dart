import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../reference_data/data/models/reference_item.dart';
import '../data/models/user_image.dart';
import '../data/models/user_profile.dart';

const _unset = Object();

/// Form draft for the profile completion wizard (PERF-PAGE-WIZARD-002).
class ProfileWizardState {
  const ProfileWizardState({
    this.avatarUrl,
    this.primaryImageFile,
    this.additionalImageFiles = const [],
    this.uploadedImages = const [],
    this.name = '',
    this.age,
    this.bio = '',
    this.selectedInterestTitles = const [],
    this.phoneNumber = '',
    this.countryCode,
    this.countryId,
    this.cityId,
    this.selectedCountry,
    this.locationMarketNotice,
    this.genderId,
    this.birthDate,
    this.minAgePreference = 18,
    this.maxAgePreference = 30,
    this.height = 170,
    this.weight = 70,
    this.smoke = false,
    this.drink = false,
    this.gym = false,
    this.musicGenres = const [],
    this.educations = const [],
    this.jobs = const [],
    this.languages = const [],
    this.interestsIds = const [],
    this.preferredGenders = const [],
    this.relationGoals = const [],
  });

  final String? avatarUrl;
  final File? primaryImageFile;
  final List<File> additionalImageFiles;
  final List<UserImage> uploadedImages;
  final String name;
  final int? age;
  final String bio;
  final List<String> selectedInterestTitles;
  final String phoneNumber;
  final String? countryCode;
  final int? countryId;
  final int? cityId;
  final ReferenceItem? selectedCountry;
  final String? locationMarketNotice;
  final int? genderId;
  final DateTime? birthDate;
  final int minAgePreference;
  final int maxAgePreference;
  final int height;
  final int weight;
  final bool smoke;
  final bool drink;
  final bool gym;
  final List<int> musicGenres;
  final List<int> educations;
  final List<int> jobs;
  final List<int> languages;
  final List<int> interestsIds;
  final List<int> preferredGenders;
  final List<int> relationGoals;

  bool get hasProfilePhoto =>
      primaryImageFile != null ||
      (avatarUrl != null && avatarUrl!.trim().isNotEmpty);

  static int get maxAdditionalPhotos => AppConstants.maxGalleryPhotos;

  int get existingGalleryCount => uploadedImages
      .where(
        (img) =>
            img.type == 'gallery' || (!img.isPrimary && img.type != 'profile'),
      )
      .length;

  int get totalGalleryCount =>
      existingGalleryCount + additionalImageFiles.length;

  bool get galleryFull => totalGalleryCount >= maxAdditionalPhotos;

  bool get primaryAlreadyUploaded =>
      uploadedImages.any((img) => img.isPrimary || img.type == 'profile');

  int get remainingGallerySlots =>
      (maxAdditionalPhotos - totalGalleryCount).clamp(0, maxAdditionalPhotos);

  ProfileWizardState copyWith({
    Object? avatarUrl = _unset,
    Object? primaryImageFile = _unset,
    List<File>? additionalImageFiles,
    List<UserImage>? uploadedImages,
    String? name,
    Object? age = _unset,
    String? bio,
    List<String>? selectedInterestTitles,
    String? phoneNumber,
    Object? countryCode = _unset,
    Object? countryId = _unset,
    Object? cityId = _unset,
    Object? selectedCountry = _unset,
    Object? locationMarketNotice = _unset,
    Object? genderId = _unset,
    Object? birthDate = _unset,
    int? minAgePreference,
    int? maxAgePreference,
    int? height,
    int? weight,
    bool? smoke,
    bool? drink,
    bool? gym,
    List<int>? musicGenres,
    List<int>? educations,
    List<int>? jobs,
    List<int>? languages,
    List<int>? interestsIds,
    List<int>? preferredGenders,
    List<int>? relationGoals,
  }) {
    return ProfileWizardState(
      avatarUrl: identical(avatarUrl, _unset)
          ? this.avatarUrl
          : avatarUrl as String?,
      primaryImageFile: identical(primaryImageFile, _unset)
          ? this.primaryImageFile
          : primaryImageFile as File?,
      additionalImageFiles: additionalImageFiles ?? this.additionalImageFiles,
      uploadedImages: uploadedImages ?? this.uploadedImages,
      name: name ?? this.name,
      age: identical(age, _unset) ? this.age : age as int?,
      bio: bio ?? this.bio,
      selectedInterestTitles:
          selectedInterestTitles ?? this.selectedInterestTitles,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      countryCode: identical(countryCode, _unset)
          ? this.countryCode
          : countryCode as String?,
      countryId: identical(countryId, _unset)
          ? this.countryId
          : countryId as int?,
      cityId: identical(cityId, _unset) ? this.cityId : cityId as int?,
      selectedCountry: identical(selectedCountry, _unset)
          ? this.selectedCountry
          : selectedCountry as ReferenceItem?,
      locationMarketNotice: identical(locationMarketNotice, _unset)
          ? this.locationMarketNotice
          : locationMarketNotice as String?,
      genderId: identical(genderId, _unset) ? this.genderId : genderId as int?,
      birthDate: identical(birthDate, _unset)
          ? this.birthDate
          : birthDate as DateTime?,
      minAgePreference: minAgePreference ?? this.minAgePreference,
      maxAgePreference: maxAgePreference ?? this.maxAgePreference,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      smoke: smoke ?? this.smoke,
      drink: drink ?? this.drink,
      gym: gym ?? this.gym,
      musicGenres: musicGenres ?? this.musicGenres,
      educations: educations ?? this.educations,
      jobs: jobs ?? this.jobs,
      languages: languages ?? this.languages,
      interestsIds: interestsIds ?? this.interestsIds,
      preferredGenders: preferredGenders ?? this.preferredGenders,
      relationGoals: relationGoals ?? this.relationGoals,
    );
  }
}

class ProfileWizardNotifier extends StateNotifier<ProfileWizardState> {
  ProfileWizardNotifier() : super(const ProfileWizardState());

  void apply(ProfileWizardState next) => state = next;

  void setName(String value) {
    if (state.name == value) return;
    state = state.copyWith(name: value);
  }

  void setBio(String value) {
    if (state.bio == value) return;
    state = state.copyWith(bio: value);
  }

  void setPhone({required String phoneNumber, String? countryCode}) {
    state = state.copyWith(phoneNumber: phoneNumber, countryCode: countryCode);
  }

  void setCountry({
    required int? countryId,
    ReferenceItem? selectedCountry,
    String? countryCode,
  }) {
    state = state.copyWith(
      countryId: countryId,
      cityId: null,
      selectedCountry: selectedCountry,
      locationMarketNotice: null,
      countryCode: countryCode,
    );
  }

  void setCity(int? cityId) {
    state = state.copyWith(cityId: cityId, locationMarketNotice: null);
  }

  void setGender(int? genderId) {
    state = state.copyWith(genderId: genderId);
  }

  void setBirthDate(DateTime picked) {
    final today = DateTime.now();
    var age = today.year - picked.year;
    if (today.month < picked.month ||
        (today.month == picked.month && today.day < picked.day)) {
      age -= 1;
    }
    state = state.copyWith(birthDate: picked, age: age);
  }

  void setHeight(int value) => state = state.copyWith(height: value);

  void setWeight(int value) => state = state.copyWith(weight: value);

  void setEducations(List<int> ids) => state = state.copyWith(educations: ids);

  void setJobs(List<int> ids) => state = state.copyWith(jobs: ids);

  void setLanguages(List<int> ids) => state = state.copyWith(languages: ids);

  void setAgePreference({required int min, required int max}) {
    state = state.copyWith(minAgePreference: min, maxAgePreference: max);
  }

  void setPreferredGenders(List<int> ids) =>
      state = state.copyWith(preferredGenders: ids);

  void setRelationGoals(List<int> ids) =>
      state = state.copyWith(relationGoals: ids);

  void setSmoke(bool value) => state = state.copyWith(smoke: value);

  void setDrink(bool value) => state = state.copyWith(drink: value);

  void setGym(bool value) => state = state.copyWith(gym: value);

  void setMusicGenres(List<int> ids) =>
      state = state.copyWith(musicGenres: ids);

  void setInterests({required List<String> titles, required List<int> ids}) {
    state = state.copyWith(selectedInterestTitles: titles, interestsIds: ids);
  }

  void setPrimaryPhoto(File file) {
    state = state.copyWith(primaryImageFile: file, avatarUrl: file.path);
  }

  void addGalleryFiles(Iterable<File> files, {required int maxPhotos}) {
    final next = List<File>.from(state.additionalImageFiles);
    for (final file in files) {
      if (state.existingGalleryCount + next.length >= maxPhotos) break;
      next.add(file);
    }
    state = state.copyWith(additionalImageFiles: next);
  }

  void removeGalleryAt(int index) {
    final next = List<File>.from(state.additionalImageFiles)..removeAt(index);
    state = state.copyWith(additionalImageFiles: next);
  }

  void clearLocalImages() {
    state = state.copyWith(
      primaryImageFile: null,
      additionalImageFiles: const [],
    );
  }

  void clearUnsupportedCountry() {
    state = state.copyWith(
      countryId: null,
      cityId: null,
      selectedCountry: null,
      locationMarketNotice:
          'Your previous location is no longer available. Please choose a supported country and city.',
    );
  }

  void clearUnsupportedCity() {
    state = state.copyWith(
      cityId: null,
      locationMarketNotice:
          'Your previous city is no longer available. Please choose a supported city.',
    );
  }

  void applyFromProfile(UserProfile profile, {required bool nameAlreadySet}) {
    var next = state;

    if (!nameAlreadySet) {
      final first = profile.firstName.trim();
      final last = profile.lastName.trim();
      if (first.isNotEmpty && first != 'User') {
        next = next.copyWith(name: last.isNotEmpty ? '$first $last' : first);
      }
    }

    if (profile.profileBio != null && profile.profileBio!.isNotEmpty) {
      next = next.copyWith(bio: profile.profileBio);
    }
    if (profile.countryId != null) {
      next = next.copyWith(countryId: profile.countryId);
    }
    if (profile.cityId != null) {
      next = next.copyWith(cityId: profile.cityId);
    }
    if (profile.genderId != null) {
      next = next.copyWith(genderId: profile.genderId);
    }
    if (profile.height != null) {
      next = next.copyWith(height: profile.height);
    }
    if (profile.weight != null) {
      next = next.copyWith(weight: profile.weight);
    }
    if (profile.smoke != null) {
      next = next.copyWith(smoke: profile.smoke);
    }
    if (profile.drink != null) {
      next = next.copyWith(drink: profile.drink);
    }
    if (profile.gym != null) {
      next = next.copyWith(gym: profile.gym);
    }
    if (profile.minAgePreference != null) {
      next = next.copyWith(minAgePreference: profile.minAgePreference);
    }
    if (profile.maxAgePreference != null) {
      next = next.copyWith(maxAgePreference: profile.maxAgePreference);
    }
    if (profile.musicGenres != null && profile.musicGenres!.isNotEmpty) {
      next = next.copyWith(musicGenres: profile.musicGenres);
    }
    if (profile.educations != null && profile.educations!.isNotEmpty) {
      next = next.copyWith(educations: [profile.educations!.first]);
    }
    if (profile.jobs != null && profile.jobs!.isNotEmpty) {
      next = next.copyWith(jobs: [profile.jobs!.first]);
    }
    if (profile.languages != null && profile.languages!.isNotEmpty) {
      next = next.copyWith(languages: profile.languages);
    }
    if (profile.interests != null && profile.interests!.isNotEmpty) {
      next = next.copyWith(
        interestsIds: profile.interests,
        selectedInterestTitles:
            profile.interestTitles ?? next.selectedInterestTitles,
      );
    }
    if (profile.preferredGenders != null &&
        profile.preferredGenders!.isNotEmpty) {
      next = next.copyWith(preferredGenders: profile.preferredGenders);
    }
    if (profile.relationGoals != null && profile.relationGoals!.isNotEmpty) {
      next = next.copyWith(relationGoals: profile.relationGoals);
    }

    if (profile.birthDate != null && profile.birthDate!.isNotEmpty) {
      try {
        final birth = DateTime.parse(profile.birthDate!);
        final today = DateTime.now();
        var age = today.year - birth.year;
        if (today.month < birth.month ||
            (today.month == birth.month && today.day < birth.day)) {
          age -= 1;
        }
        next = next.copyWith(birthDate: birth, age: age);
      } catch (_) {}
    }

    if (profile.images != null && profile.images!.isNotEmpty) {
      final uploaded = List<UserImage>.from(next.uploadedImages);
      String? avatar = next.avatarUrl;
      for (final image in profile.images!) {
        if (!uploaded.any((img) => img.id == image.id)) {
          uploaded.add(image);
        }
        if (image.isPrimary || image.type == 'profile') {
          avatar = image.imageUrl;
        }
      }
      next = next.copyWith(uploadedImages: uploaded, avatarUrl: avatar);
    }

    state = next;
  }

  void seedCompleteForTests({
    required File photo,
    required String name,
    required String phoneNumber,
    required String countryCode,
    required String bio,
  }) {
    setPrimaryPhoto(photo);
    setName(name);
    setPhone(phoneNumber: phoneNumber, countryCode: countryCode);
    setCountry(countryId: 1, countryCode: countryCode);
    setCity(10);
    setGender(2);
    setBirthDate(DateTime(1995, 6, 15));
    setBio(bio);
    setEducations(const [4]);
    setJobs(const [3]);
    setLanguages(const [5]);
    setPreferredGenders(const [2]);
    setRelationGoals(const [9]);
    setInterests(titles: const ['Music'], ids: const [6]);
    setMusicGenres(const [8]);
    setAgePreference(min: 18, max: 30);
  }

  /// First wizard step that still needs user input.
  int resolveResumeStep() {
    if (!state.hasProfilePhoto) return 0;
    if (state.countryId == null ||
        state.cityId == null ||
        state.genderId == null ||
        state.birthDate == null ||
        state.phoneNumber.isEmpty) {
      return 1;
    }
    if (state.bio.isEmpty ||
        state.educations.isEmpty ||
        state.jobs.isEmpty ||
        state.languages.isEmpty) {
      return 2;
    }
    if (state.preferredGenders.isEmpty ||
        state.relationGoals.isEmpty ||
        state.minAgePreference >= state.maxAgePreference) {
      return 3;
    }
    if (state.musicGenres.isEmpty || state.interestsIds.isEmpty) {
      return 4;
    }
    return 6;
  }
}

final profileWizardProvider =
    StateNotifierProvider.autoDispose<
      ProfileWizardNotifier,
      ProfileWizardState
    >((ref) => ProfileWizardNotifier());
