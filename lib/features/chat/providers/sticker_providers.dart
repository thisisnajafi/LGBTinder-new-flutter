import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/api_providers.dart';
import '../data/models/sticker_pack.dart';
import '../data/services/sticker_service.dart';

final stickerServiceProvider = Provider<StickerService>((ref) {
  return StickerService(ref.watch(apiServiceProvider));
});

final stickerPacksProvider = FutureProvider.autoDispose<List<StickerPack>>((ref) async {
  return ref.watch(stickerServiceProvider).getStickerPacks();
});

final stickerPackStickersProvider =
    FutureProvider.autoDispose.family<List<StickerItem>, int>((ref, packId) async {
  return ref.watch(stickerServiceProvider).getStickersForPack(packId);
});
