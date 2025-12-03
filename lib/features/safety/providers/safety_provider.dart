import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/block.dart';
import '../data/models/report.dart';
import '../data/models/favorite.dart';
import '../data/models/emergency_contact.dart';
import '../domain/use_cases/block_user_use_case.dart';
import '../domain/use_cases/unblock_user_use_case.dart';
import '../domain/use_cases/report_user_use_case.dart';
import '../domain/use_cases/add_emergency_contact_use_case.dart';

/// Safety provider - manages safety and user interaction state
final safetyProvider = StateNotifierProvider<SafetyNotifier, SafetyState>((ref) {
  final blockUserUseCase = ref.watch(blockUserUseCaseProvider);
  final unblockUserUseCase = ref.watch(unblockUserUseCaseProvider);
  final reportUserUseCase = ref.watch(reportUserUseCaseProvider);
  final addEmergencyContactUseCase = ref.watch(addEmergencyContactUseCaseProvider);

  return SafetyNotifier(
    blockUserUseCase: blockUserUseCase,
    unblockUserUseCase: unblockUserUseCase,
    reportUserUseCase: reportUserUseCase,
    addEmergencyContactUseCase: addEmergencyContactUseCase,
  );
});

/// Safety state
class SafetyState {
  final List<BlockedUser> blockedUsers;
  final List<Report> reportsHistory;
  final List<FavoriteUser> favoriteUsers;
  final List<EmergencyContact> emergencyContacts;
  final bool isLoading;
  final bool isBlocking;
  final bool isReporting;
  final bool isFavoriting;
  final String? error;
  final Map<int, bool> isUserBlocked; // userId -> blocked status
  final Map<int, bool> isUserFavorited; // userId -> favorited status

  SafetyState({
    this.blockedUsers = const [],
    this.reportsHistory = const [],
    this.favoriteUsers = const [],
    this.emergencyContacts = const [],
    this.isLoading = false,
    this.isBlocking = false,
    this.isReporting = false,
    this.isFavoriting = false,
    this.error,
    this.isUserBlocked = const {},
    this.isUserFavorited = const {},
  });

  SafetyState copyWith({
    List<BlockedUser>? blockedUsers,
    List<Report>? reportsHistory,
    List<FavoriteUser>? favoriteUsers,
    List<EmergencyContact>? emergencyContacts,
    bool? isLoading,
    bool? isBlocking,
    bool? isReporting,
    bool? isFavoriting,
    String? error,
    Map<int, bool>? isUserBlocked,
    Map<int, bool>? isUserFavorited,
  }) {
    return SafetyState(
      blockedUsers: blockedUsers ?? this.blockedUsers,
      reportsHistory: reportsHistory ?? this.reportsHistory,
      favoriteUsers: favoriteUsers ?? this.favoriteUsers,
      emergencyContacts: emergencyContacts ?? this.emergencyContacts,
      isLoading: isLoading ?? this.isLoading,
      isBlocking: isBlocking ?? this.isBlocking,
      isReporting: isReporting ?? this.isReporting,
      isFavoriting: isFavoriting ?? this.isFavoriting,
      error: error ?? this.error,
      isUserBlocked: isUserBlocked ?? this.isUserBlocked,
      isUserFavorited: isUserFavorited ?? this.isUserFavorited,
    );
  }
}

/// Safety notifier
class SafetyNotifier extends StateNotifier<SafetyState> {
  final BlockUserUseCase _blockUserUseCase;
  final UnblockUserUseCase _unblockUserUseCase;
  final ReportUserUseCase _reportUserUseCase;
  final AddEmergencyContactUseCase _addEmergencyContactUseCase;

  SafetyNotifier({
    required BlockUserUseCase blockUserUseCase,
    required UnblockUserUseCase unblockUserUseCase,
    required ReportUserUseCase reportUserUseCase,
    required AddEmergencyContactUseCase addEmergencyContactUseCase,
  }) : _blockUserUseCase = blockUserUseCase,
       _unblockUserUseCase = unblockUserUseCase,
       _reportUserUseCase = reportUserUseCase,
       _addEmergencyContactUseCase = addEmergencyContactUseCase,
       super(SafetyState());

  /// Load blocked users
  Future<void> loadBlockedUsers() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // TODO: Implement blocked users loading
      // final blockedUsers = await _getBlockedUsersUseCase.execute();
      // final blockedMap = {for (var user in blockedUsers) user.blockedUserId: true};
      // state = state.copyWith(
      //   blockedUsers: blockedUsers,
      //   isUserBlocked: blockedMap,
      //   isLoading: false,
      // );
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load favorites
  Future<void> loadFavorites() async {
    try {
      // TODO: Implement favorites loading
      // final favorites = await _getFavoritesUseCase.execute();
      // final favoritesMap = {for (var user in favorites) user.favoriteUserId: true};
      // state = state.copyWith(
      //   favoriteUsers: favorites,
      //   isUserFavorited: favoritesMap,
      // );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Load reports history
  Future<void> loadReportsHistory() async {
    try {
      // TODO: Implement reports history loading
      // final reports = await _getReportsHistoryUseCase.execute();
      // state = state.copyWith(reportsHistory: reports);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Load emergency contacts
  Future<void> loadEmergencyContacts() async {
    try {
      // TODO: Implement emergency contacts loading
      // final contacts = await _getEmergencyContactsUseCase.execute();
      // state = state.copyWith(emergencyContacts: contacts);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Block a user
  Future<BlockedUser?> blockUser(BlockUserRequest request) async {
    state = state.copyWith(isBlocking: true, error: null);

    try {
      final blockedUser = await _blockUserUseCase.execute(request);

      // Update local state
      final updatedBlockedUsers = [...state.blockedUsers, blockedUser];
      final updatedBlockedMap = Map<int, bool>.from(state.isUserBlocked);
      updatedBlockedMap[request.blockedUserId] = true;

      state = state.copyWith(
        blockedUsers: updatedBlockedUsers,
        isUserBlocked: updatedBlockedMap,
        isBlocking: false,
      );

      return blockedUser;
    } catch (e) {
      state = state.copyWith(
        isBlocking: false,
        error: e.toString(),
      );
      return null;
    }
  }

  /// Unblock a user
  Future<bool> unblockUser(int blockedUserId) async {
    try {
      await _unblockUserUseCase.execute(blockedUserId);

      // Update local state
      final updatedBlockedUsers = state.blockedUsers
          .where((user) => user.blockedUserId != blockedUserId)
          .toList();
      final updatedBlockedMap = Map<int, bool>.from(state.isUserBlocked);
      updatedBlockedMap.remove(blockedUserId);

      state = state.copyWith(
        blockedUsers: updatedBlockedUsers,
        isUserBlocked: updatedBlockedMap,
      );

      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Report a user
  Future<Report?> reportUser(ReportUserRequest request) async {
    state = state.copyWith(isReporting: true, error: null);

    try {
      final report = await _reportUserUseCase.execute(request);

      // Update local state
      final updatedReports = [report, ...state.reportsHistory];
      state = state.copyWith(
        reportsHistory: updatedReports,
        isReporting: false,
      );

      return report;
    } catch (e) {
      state = state.copyWith(
        isReporting: false,
        error: e.toString(),
      );
      return null;
    }
  }

  /// Add to favorites
  Future<FavoriteUser?> addToFavorites(AddFavoriteRequest request) async {
    state = state.copyWith(isFavoriting: true, error: null);

    try {
      // TODO: Implement add to favorites
      // final favorite = await _addToFavoritesUseCase.execute(request);
      // final updatedFavorites = [...state.favoriteUsers, favorite];
      // final updatedFavoritesMap = Map<int, bool>.from(state.isUserFavorited);
      // updatedFavoritesMap[request.favoriteUserId] = true;
      //
      // state = state.copyWith(
      //   favoriteUsers: updatedFavorites,
      //   isUserFavorited: updatedFavoritesMap,
      //   isFavoriting: false,
      // );
      // return favorite;
      state = state.copyWith(isFavoriting: false);
      return null;
    } catch (e) {
      state = state.copyWith(
        isFavoriting: false,
        error: e.toString(),
      );
      return null;
    }
  }

  /// Remove from favorites
  Future<bool> removeFromFavorites(int favoriteUserId) async {
    try {
      // TODO: Implement remove from favorites
      // await _removeFromFavoritesUseCase.execute(favoriteUserId);
      //
      // final updatedFavorites = state.favoriteUsers
      //     .where((user) => user.favoriteUserId != favoriteUserId)
      //     .toList();
      // final updatedFavoritesMap = Map<int, bool>.from(state.isUserFavorited);
      // updatedFavoritesMap.remove(favoriteUserId);
      //
      // state = state.copyWith(
      //   favoriteUsers: updatedFavorites,
      //   isUserFavorited: updatedFavoritesMap,
      // );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Add emergency contact
  Future<EmergencyContact?> addEmergencyContact(AddEmergencyContactRequest request) async {
    try {
      final contact = await _addEmergencyContactUseCase.execute(request);

      // Update local state
      final updatedContacts = [...state.emergencyContacts, contact];
      state = state.copyWith(emergencyContacts: updatedContacts);

      return contact;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Check if user is blocked
  bool isUserBlocked(int userId) {
    return state.isUserBlocked[userId] ?? false;
  }

  /// Check if user is favorited
  bool isUserFavorited(int userId) {
    return state.isUserFavorited[userId] ?? false;
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Reset safety state
  void reset() {
    state = SafetyState();
  }
}

// Use case providers
final blockUserUseCaseProvider = Provider<BlockUserUseCase>((ref) {
  throw UnimplementedError('BlockUserUseCase must be overridden in the provider scope');
});

final unblockUserUseCaseProvider = Provider<UnblockUserUseCase>((ref) {
  throw UnimplementedError('UnblockUserUseCase must be overridden in the provider scope');
});

final reportUserUseCaseProvider = Provider<ReportUserUseCase>((ref) {
  throw UnimplementedError('ReportUserUseCase must be overridden in the provider scope');
});

final addEmergencyContactUseCaseProvider = Provider<AddEmergencyContactUseCase>((ref) {
  throw UnimplementedError('AddEmergencyContactUseCase must be overridden in the provider scope');
});
