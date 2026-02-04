import '../../../../core/constants/api_endpoints.dart';
import '../../../../shared/services/api_service.dart';
import '../models/superlike_pack.dart';

/// Superlike pack service
class SuperlikePackService {
  final ApiService _apiService;

  SuperlikePackService(this._apiService);

  /// Get available superlike packs
  Future<List<SuperlikePack>> getAvailablePacks() async {
    try {
      final response = await _apiService.get<dynamic>(
        ApiEndpoints.superlikePacksAvailable,
      );

      List<dynamic>? dataList;
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data['data'] != null && data['data'] is List) {
          dataList = data['data'] as List;
        }
      } else if (response.data is List) {
        dataList = response.data as List;
      }

      if (dataList != null) {
        return dataList
            .map((item) => SuperlikePack.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Purchase a superlike pack
  Future<UserSuperlikePack> purchasePack(PurchaseSuperlikePackRequest request) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.superlikePacksPurchase,
        data: request.toJson(),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return UserSuperlikePack.fromJson(response.data!);
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get user's superlike packs
  Future<List<UserSuperlikePack>> getUserPacks() async {
    try {
      final response = await _apiService.get<dynamic>(
        ApiEndpoints.superlikePacksUserPacks,
      );

      // Handle response format: { data: { total_superlikes: X, packs: [...] } }
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        final responseData = data['data'] as Map<String, dynamic>?;
        
        if (responseData != null) {
          final totalSuperlikes = responseData['total_superlikes'] as int? ?? 0;
          final packsList = responseData['packs'] as List?;
          
          if (packsList != null && packsList.isNotEmpty) {
            return packsList
                .map((item) {
                  final packData = item as Map<String, dynamic>;
                  // Add total_superlikes to each pack for reference
                  return UserSuperlikePack.fromJson({
                    ...packData,
                    'total_superlikes': totalSuperlikes,
                  });
                })
                .toList();
          } else {
            // If no packs but we have total, create a virtual pack
            if (totalSuperlikes > 0) {
              return [
                UserSuperlikePack(
                  id: 0,
                  packId: 0,
                  packName: 'Available Superlikes',
                  remainingCount: totalSuperlikes,
                  totalCount: totalSuperlikes,
                  purchasedAt: DateTime.now(),
                ),
              ];
            }
          }
        }
      }
      
      // Fallback: try to parse as list
      if (response.data is List) {
        final dataList = response.data as List;
        return dataList
            .map((item) => UserSuperlikePack.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      
      return [];
    } catch (e) {
      rethrow;
    }
  }

}

