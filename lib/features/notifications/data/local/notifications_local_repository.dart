import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../chat/data/local/app_database.dart';
import '../models/notification.dart' as app_models;
import 'notifications_list_snapshot.dart';

export 'notifications_list_snapshot.dart';

/// Drift-backed notification feed (PERF-INFRA-005).
class NotificationsLocalRepository {
  NotificationsLocalRepository(this._db);

  final AppDatabase _db;

  Future<NotificationsLocalSnapshot?> load(int ownerUserId) async {
    if (ownerUserId <= 0) return null;

    final rows = await (_db.select(_db.localNotifications)
          ..where((t) => t.ownerUserId.equals(ownerUserId))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
    if (rows.isEmpty) return null;

    final meta = await (_db.select(_db.localNotificationLists)
          ..where((t) => t.ownerUserId.equals(ownerUserId)))
        .getSingleOrNull();

    final notifications = rows
        .map(_rowToNotification)
        .where((n) => n.id > 0)
        .toList(growable: false);
    if (notifications.isEmpty) return null;

    return NotificationsLocalSnapshot(
      notifications: withoutChatMessageNotifications(notifications),
      currentPage: meta?.currentPage ?? 2,
      hasMore: meta?.hasMore ?? notifications.length >= kNotificationsPageSize,
      unreadCount: meta?.unreadCount,
    );
  }

  Future<void> replace({
    required int ownerUserId,
    required List<app_models.Notification> notifications,
    required int currentPage,
    required bool hasMore,
    int? unreadCount,
  }) async {
    if (ownerUserId <= 0) return;
    final filtered = withoutChatMessageNotifications(notifications);

    await _db.transaction(() async {
      await (_db.delete(_db.localNotifications)
            ..where((t) => t.ownerUserId.equals(ownerUserId)))
          .go();
      for (var i = 0; i < filtered.length; i++) {
        await _db.into(_db.localNotifications).insertOnConflictUpdate(
              _companion(ownerUserId, filtered[i], i),
            );
      }
      await _upsertMeta(
        ownerUserId: ownerUserId,
        currentPage: currentPage,
        hasMore: hasMore,
        unreadCount: unreadCount,
      );
    });
  }

  Future<void> upsertMeta({
    required int ownerUserId,
    required int currentPage,
    required bool hasMore,
    int? unreadCount,
  }) async {
    if (ownerUserId <= 0) return;
    await _upsertMeta(
      ownerUserId: ownerUserId,
      currentPage: currentPage,
      hasMore: hasMore,
      unreadCount: unreadCount,
    );
  }

  Future<void> markAsRead(int ownerUserId, int serverId) async {
    if (ownerUserId <= 0 || serverId <= 0) return;
    await (_db.update(_db.localNotifications)
          ..where(
            (t) =>
                t.ownerUserId.equals(ownerUserId) & t.serverId.equals(serverId),
          ))
        .write(const LocalNotificationsCompanion(isRead: Value(true)));
  }

  Future<void> markAllAsRead(int ownerUserId) async {
    if (ownerUserId <= 0) return;
    await (_db.update(_db.localNotifications)
          ..where((t) => t.ownerUserId.equals(ownerUserId)))
        .write(const LocalNotificationsCompanion(isRead: Value(true)));
    await _upsertMeta(
      ownerUserId: ownerUserId,
      currentPage: null,
      hasMore: null,
      unreadCount: 0,
    );
  }

  Future<void> remove(int ownerUserId, int serverId) async {
    if (ownerUserId <= 0 || serverId <= 0) return;
    await (_db.delete(_db.localNotifications)
          ..where(
            (t) =>
                t.ownerUserId.equals(ownerUserId) & t.serverId.equals(serverId),
          ))
        .go();
  }

  Future<void> clear(int ownerUserId) async {
    if (ownerUserId <= 0) return;
    await _db.transaction(() async {
      await (_db.delete(_db.localNotifications)
            ..where((t) => t.ownerUserId.equals(ownerUserId)))
          .go();
      await (_db.delete(_db.localNotificationLists)
            ..where((t) => t.ownerUserId.equals(ownerUserId)))
          .go();
    });
  }

  Future<void> _upsertMeta({
    required int ownerUserId,
    int? currentPage,
    bool? hasMore,
    int? unreadCount,
  }) async {
    final existing = await (_db.select(_db.localNotificationLists)
          ..where((t) => t.ownerUserId.equals(ownerUserId)))
        .getSingleOrNull();

    await _db.into(_db.localNotificationLists).insertOnConflictUpdate(
          LocalNotificationListsCompanion(
            ownerUserId: Value(ownerUserId),
            currentPage: Value(currentPage ?? existing?.currentPage ?? 1),
            hasMore: Value(hasMore ?? existing?.hasMore ?? true),
            unreadCount: Value(unreadCount ?? existing?.unreadCount),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  LocalNotificationsCompanion _companion(
    int ownerUserId,
    app_models.Notification notification,
    int sortOrder,
  ) {
    return LocalNotificationsCompanion.insert(
      ownerUserId: ownerUserId,
      serverId: notification.id,
      type: notification.type,
      title: notification.title,
      message: notification.message,
      createdAt: notification.createdAt,
      isRead: Value(notification.isRead),
      payloadJson: Value(_encodePayload(notification.data)),
      actorUserId: Value(notification.userId),
      actorName: Value(notification.userName),
      actorImageUrl: Value(notification.userImageUrl),
      actionUrl: Value(notification.actionUrl),
      isPlanRestricted: Value(notification.isPlanRestricted),
      upgradeRequired: Value(notification.upgradeRequired),
      sortOrder: Value(sortOrder),
    );
  }

  app_models.Notification _rowToNotification(LocalNotification row) {
    return app_models.Notification(
      id: row.serverId,
      type: row.type,
      title: row.title,
      message: row.message,
      createdAt: row.createdAt,
      isRead: row.isRead,
      data: _decodePayload(row.payloadJson),
      userId: row.actorUserId,
      userName: row.actorName,
      userImageUrl: row.actorImageUrl,
      actionUrl: row.actionUrl,
      isPlanRestricted: row.isPlanRestricted,
      upgradeRequired: row.upgradeRequired,
    );
  }

  String? _encodePayload(Map<String, dynamic>? data) {
    if (data == null || data.isEmpty) return null;
    return jsonEncode(data);
  }

  Map<String, dynamic>? _decodePayload(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return null;
  }
}
