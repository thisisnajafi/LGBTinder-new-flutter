import '../../../../core/constants/api_endpoints.dart';
import '../../../../shared/services/api_service.dart';
import '../models/sticker_pack.dart';

/// Fetches sticker packs and stickers from the chat API.
class StickerService {
  final ApiService _apiService;

  StickerService(this._apiService);

  /// GET /api/chat/sticker-packs
  Future<List<StickerPack>> getStickerPacks() async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiEndpoints.chatStickerPacks,
      fromJson: (json) => json as Map<String, dynamic>,
    );

    if (!response.isSuccess) {
      throw Exception(response.message);
    }

    final raw = response.data;
    final dataList = raw?['data'];
    final list = dataList is List ? dataList : <dynamic>[];

    return list
        .map((item) => StickerPack.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/chat/sticker-packs/{packId}/stickers
  Future<List<StickerItem>> getStickersForPack(int packId) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiEndpoints.chatStickerPackStickers(packId),
      fromJson: (json) => json as Map<String, dynamic>,
    );

    if (!response.isSuccess) {
      throw Exception(response.message);
    }

    final raw = response.data;
    final dataList = raw?['data'];
    final list = dataList is List ? dataList : <dynamic>[];

    return list
        .map((item) => StickerItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
