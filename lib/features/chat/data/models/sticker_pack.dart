/// Sticker pack catalog model from GET /api/chat/sticker-packs
class StickerPack {
  final int id;
  final String name;
  final String thumbnailUrl;
  final bool isFree;
  final bool isUnlocked;
  final int sortOrder;
  final int stickerCount;

  const StickerPack({
    required this.id,
    required this.name,
    required this.thumbnailUrl,
    required this.isFree,
    required this.isUnlocked,
    required this.sortOrder,
    this.stickerCount = 0,
  });

  factory StickerPack.fromJson(Map<String, dynamic> json) {
    return StickerPack(
      id: _parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      thumbnailUrl: json['thumbnail_url']?.toString() ?? '',
      isFree: _parseBool(json['is_free'], defaultValue: true),
      isUnlocked: _parseBool(json['is_unlocked'], defaultValue: true),
      sortOrder: _parseInt(json['sort_order']),
      stickerCount: _parseInt(json['sticker_count']),
    );
  }
}

/// Individual sticker from GET /api/chat/sticker-packs/{id}/stickers
class StickerItem {
  final int id;
  final int packId;
  final String imageUrl;
  final String? altText;
  final int sortOrder;

  const StickerItem({
    required this.id,
    required this.packId,
    required this.imageUrl,
    this.altText,
    required this.sortOrder,
  });

  factory StickerItem.fromJson(Map<String, dynamic> json) {
    return StickerItem(
      id: _parseInt(json['id']),
      packId: _parseInt(json['pack_id']),
      imageUrl: json['image_url']?.toString() ?? '',
      altText: json['alt_text']?.toString(),
      sortOrder: _parseInt(json['sort_order']),
    );
  }
}

int _parseInt(dynamic value, {int defaultValue = 0}) {
  if (value == null) return defaultValue;
  if (value is int) return value;
  return int.tryParse(value.toString()) ?? defaultValue;
}

bool _parseBool(dynamic value, {bool defaultValue = false}) {
  if (value == null) return defaultValue;
  if (value is bool) return value;
  if (value is int) return value == 1;
  if (value is String) {
    return value.toLowerCase() == 'true' || value == '1';
  }
  return defaultValue;
}
