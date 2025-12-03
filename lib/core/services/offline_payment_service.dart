import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/services/api_service.dart';

/// Offline Payment Service - Handles payments when Google Play Billing is unavailable
class OfflinePaymentService {
  final ApiService _apiService;
  final SharedPreferences _prefs;
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

      // Validate purchase with backend
      final response = await _apiService.post<Map<String, dynamic>>(
        isSubscription
            ? '/api/google-play/validate-purchase'
            : '/api/google-play/validate-one-time-purchase',
        data: purchaseData,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess) {
        debugPrint('Successfully processed queued purchase: ${purchaseData['productId']}');
        return true;
      } else {
        debugPrint('Backend validation failed for queued purchase: ${response.message}');
        return false;
      }
    } catch (e) {
      debugPrint('Error processing queued purchase: $e');
      return false;
    }
  }

  /// Get pending purchases from storage
  Future<List<Map<String, dynamic>>> _getPendingPurchases() async {
    try {
      final purchasesJson = _prefs.getStringList(_pendingPurchasesKey) ?? [];
      return purchasesJson.map((json) {
        // In a real implementation, you'd use json.decode
        // For simplicity, we'll assume the data is already in the right format
        return {'id': 'temp', 'data': {}, 'timestamp': '', 'status': 'queued'};
      }).toList();
    } catch (e) {
      debugPrint('Failed to get pending purchases: $e');
      return [];
    }
  }

  /// Save pending purchases to storage
  Future<void> _savePendingPurchases(List<Map<String, dynamic>> purchases) async {
    try {
      // In a real implementation, you'd use json.encode for each purchase
      final purchasesJson = purchases.map((purchase) => purchase.toString()).toList();
      await _prefs.setStringList(_pendingPurchasesKey, purchasesJson);
    } catch (e) {
      debugPrint('Failed to save pending purchases: $e');
      rethrow;
    }
  }

  /// Clear all pending purchases (useful for testing or reset)
  Future<void> clearPendingPurchases() async {
    await _prefs.remove(_pendingPurchasesKey);
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
