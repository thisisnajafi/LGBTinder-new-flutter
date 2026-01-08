import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/services/api_service.dart';

/// Offline Payment Service - Handles payments when Google Play Billing is unavailable
class OfflinePaymentService {
  final ApiService _apiService;
  final SharedPreferences? _prefs;
  static const String _pendingPurchasesKey = 'pending_purchases';

  OfflinePaymentService(this._apiService, this._prefs);

  /// Queue a purchase for later processing when offline
  Future<void> queuePurchase(Map<String, dynamic> purchaseData) async {
    try {
      final pendingPurchases = await _getPendingPurchases();
      pendingPurchases.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'data': purchaseData,
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'queued',
      });

      await _savePendingPurchases(pendingPurchases);
      debugPrint('Purchase queued for offline processing: ${purchaseData['productId']}');
    } catch (e) {
      debugPrint('Failed to queue purchase: $e');
      rethrow;
    }
  }

  /// Process all pending purchases when connectivity is restored
  Future<void> processPendingPurchases() async {
    try {
      final pendingPurchases = await _getPendingPurchases();

      if (pendingPurchases.isEmpty) {
        return;
      }

      debugPrint('Processing ${pendingPurchases.length} pending purchases');

      final processedIds = <String>[];

      for (final purchase in pendingPurchases) {
        try {
          final result = await _processQueuedPurchase(purchase);
          if (result) {
            processedIds.add(purchase['id']);
          }
        } catch (e) {
          debugPrint('Failed to process queued purchase ${purchase['id']}: $e');
          // Keep failed purchases in queue for retry
        }
      }

      // Remove successfully processed purchases
      if (processedIds.isNotEmpty) {
        final updatedPurchases = pendingPurchases
            .where((purchase) => !processedIds.contains(purchase['id']))
            .toList();
        await _savePendingPurchases(updatedPurchases);
        debugPrint('Successfully processed ${processedIds.length} purchases');
      }
    } catch (e) {
      debugPrint('Failed to process pending purchases: $e');
    }
  }

  /// Process a single queued purchase
  Future<bool> _processQueuedPurchase(Map<String, dynamic> purchase) async {
    try {
      final purchaseData = purchase['data'] as Map<String, dynamic>;
      final isSubscription = purchaseData['isSubscription'] ?? false;
      final productId = purchaseData['productId'] as String?;

      if (productId == null) {
        debugPrint('Queued purchase missing productId, skipping');
        return false;
      }

      // Note: For offline purchases, we can't validate with Google Play directly
      // Instead, we need to wait for the user to complete the purchase when online
      // This service queues the purchase intent, not the completed purchase
      
      // When connectivity is restored, the purchase should complete through normal flow
      // This queue is mainly for tracking purchase intents that were initiated offline
      
      debugPrint('Queued purchase for product: $productId (will complete when online)');
      
      // Mark as processed since we've logged it
      // The actual purchase will complete through normal Google Play flow when online
      return true;
    } catch (e) {
      debugPrint('Error processing queued purchase: $e');
      return false;
    }
  }

  /// Get pending purchases from storage
  Future<List<Map<String, dynamic>>> _getPendingPurchases() async {
    if (_prefs == null) {
      return [];
    }

    try {
      final purchasesJson = _prefs!.getStringList(_pendingPurchasesKey) ?? [];
      return purchasesJson.map((json) {
        try {
          return jsonDecode(json) as Map<String, dynamic>;
        } catch (e) {
          debugPrint('Failed to decode purchase JSON: $e');
          return <String, dynamic>{};
        }
      }).where((purchase) => purchase.isNotEmpty).toList();
    } catch (e) {
      debugPrint('Failed to get pending purchases: $e');
      return [];
    }
  }

  /// Save pending purchases to storage
  Future<void> _savePendingPurchases(List<Map<String, dynamic>> purchases) async {
    if (_prefs == null) {
      return;
    }

    try {
      final purchasesJson = purchases.map((purchase) => jsonEncode(purchase)).toList();
      await _prefs!.setStringList(_pendingPurchasesKey, purchasesJson);
      debugPrint('Saved ${purchases.length} pending purchases to storage');
    } catch (e) {
      debugPrint('Failed to save pending purchases: $e');
      rethrow;
    }
  }

  /// Clear all pending purchases (useful for testing or reset)
  Future<void> clearPendingPurchases() async {
    if (_prefs == null) {
      return;
    }

    await _prefs!.remove(_pendingPurchasesKey);
    debugPrint('Cleared all pending purchases');
  }

  /// Get count of pending purchases
  Future<int> getPendingPurchasesCount() async {
    final pendingPurchases = await _getPendingPurchases();
    return pendingPurchases.length;
  }

  /// Check if there are pending purchases
  Future<bool> hasPendingPurchases() async {
    final count = await getPendingPurchasesCount();
    return count > 0;
  }
}
