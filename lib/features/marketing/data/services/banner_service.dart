import '../../../../shared/services/api_service.dart';
import '../models/banner_model.dart';

/// Banner service for promotional banner management
/// Part of the Marketing System Implementation (Task 3.2.3)
class BannerService {
  final ApiService _apiService;

  /// Cache for dismissed banners (in-memory for session)
  final Set<int> _dismissedBanners = {};

  BannerService(this._apiService);

  /// Get active banners for a specific position
  Future<List<BannerModel>> getBannersByPosition(String position) async {
    try {
      final response = await _apiService.get<dynamic>(
        '${BannerEndpoints.byPosition}/$position',
      );

      final data = _extractData(response.data);
      if (data != null && data['banners'] is List) {
        final banners = (data['banners'] as List)
            .map((e) => BannerModel.fromJson(e as Map<String, dynamic>))
            .where((b) => !_dismissedBanners.contains(b.id))
            .toList();

        // Sort by priority
        banners.sort((a, b) => b.priority.compareTo(a.priority));
        return banners;
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Get all active banners for current user
  Future<List<BannerModel>> getAllBanners() async {
    try {
      final response = await _apiService.get<dynamic>(
        BannerEndpoints.all,
      );

      final data = _extractData(response.data);
      if (data != null && data['banners'] is List) {
        final banners = (data['banners'] as List)
            .map((e) => BannerModel.fromJson(e as Map<String, dynamic>))
            .where((b) => !_dismissedBanners.contains(b.id))
            .toList();

        return banners;
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Track banner impression
  Future<void> trackImpression(int bannerId) async {
    try {
      await _apiService.post<dynamic>(
        BannerEndpoints.trackImpression,
        data: {'banner_id': bannerId},
        fromJson: (json) => json,
      );
    } catch (e) {
      // Silently fail - tracking shouldn't block UX
    }
  }

  /// Track banner click
  Future<void> trackClick(int bannerId) async {
    try {
      await _apiService.post<dynamic>(
        BannerEndpoints.trackClick,
        data: {'banner_id': bannerId},
        fromJson: (json) => json,
      );
    } catch (e) {
      // Silently fail - tracking shouldn't block UX
    }
  }

  /// Dismiss a banner (local + server)
  Future<void> dismissBanner(int bannerId) async {
    // Add to local dismissed set immediately
    _dismissedBanners.add(bannerId);

    try {
      await _apiService.post<dynamic>(
        BannerEndpoints.trackDismissal,
        data: {'banner_id': bannerId},
        fromJson: (json) => json,
      );
    } catch (e) {
      // Silently fail - tracking shouldn't block UX
    }
  }

  /// Track banner conversion
  Future<void> trackConversion(int bannerId) async {
    try {
      await _apiService.post<dynamic>(
        BannerEndpoints.trackConversion,
        data: {'banner_id': bannerId},
        fromJson: (json) => json,
      );
    } catch (e) {
      // Silently fail - tracking shouldn't block UX
    }
  }

  /// Check if a banner is dismissed
  bool isDismissed(int bannerId) => _dismissedBanners.contains(bannerId);

  /// Clear dismissed banners cache (for logout/session reset)
  void clearDismissedCache() {
    _dismissedBanners.clear();
  }

  Map<String, dynamic>? _extractData(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      if (responseData.containsKey('data')) {
        final data = responseData['data'];
        if (data is Map<String, dynamic>) {
          return data;
        }
      }
      return responseData;
    }
    return null;
  }
}

/// Banner API endpoints
class BannerEndpoints {
  static const String byPosition = '/banners/position';
  static const String all = '/banners/all';
  static const String trackImpression = '/banners/track-impression';
  static const String trackClick = '/banners/track-click';
  static const String trackDismissal = '/banners/track-dismissal';
  static const String trackConversion = '/banners/track-conversion';
}
