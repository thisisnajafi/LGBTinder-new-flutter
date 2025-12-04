import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import '../../../../shared/services/api_service.dart';
import '../../../../core/services/offline_payment_service.dart';

/// Google Play Billing Service for handling in-app purchases and subscriptions
class GooglePlayBillingService {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  final ApiService _apiService;
  final OfflinePaymentService _offlinePaymentService;

  // Stream controllers for reactive updates
  final StreamController<bool> _billingAvailabilityController = StreamController<bool>.broadcast();
  final StreamController<List<PurchaseDetails>> _purchaseUpdatesController = StreamController<List<PurchaseDetails>>.broadcast();
  final StreamController<String> _errorController = StreamController<String>.broadcast();

  // Stream subscriptions
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  GooglePlayBillingService(this._apiService, this._offlinePaymentService) {
    _initialize();
  }

  // Public streams
  Stream<bool> get billingAvailability => _billingAvailabilityController.stream;
  Stream<List<PurchaseDetails>> get purchaseUpdates => _purchaseUpdatesController.stream;
  Stream<String> get errors => _errorController.stream;

  /// Initialize the billing service
  Future<void> _initialize() async {
    try {
      // Check if billing is available
      final bool available = await _inAppPurchase.isAvailable();
      _billingAvailabilityController.add(available);

      if (!available) {
        _errorController.add('Google Play Billing is not available on this device');
        return;
      }

      // Set up purchase stream listener
      _purchaseSubscription = _inAppPurchase.purchaseStream.listen(
        _onPurchaseUpdate,
        onError: (error) {
          _errorController.add('Purchase stream error: $error');
        },
        onDone: () {
          debugPrint('Purchase stream closed');
        },
      );

      // Enable pending purchases for Android
      if (Platform.isAndroid) {
        final InAppPurchaseAndroidPlatformAddition androidPlatformAddition =
            _inAppPurchase.getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
        // Note: setPendingPurchaseUpdateListener is not available in current version
        // This functionality may need to be implemented differently
      }

      // Process any pending purchases that were queued offline
      await processPendingPurchases();

      debugPrint('Google Play Billing initialized successfully');
    } catch (e) {
      _errorController.add('Failed to initialize billing: $e');
      debugPrint('Billing initialization error: $e');
    }
  }

  /// Handle purchase updates from the stream
  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    debugPrint('Purchase update received: ${purchaseDetailsList.length} purchases');

    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      _handlePurchaseUpdate(purchaseDetails);
    }

    // Emit the full list to listeners
    _purchaseUpdatesController.add(purchaseDetailsList);
  }

  /// Handle individual purchase updates
  void _handlePurchaseUpdate(PurchaseDetails purchaseDetails) async {
    debugPrint('Handling purchase: ${purchaseDetails.productID}, status: ${purchaseDetails.status}');

    switch (purchaseDetails.status) {
      case PurchaseStatus.pending:
        debugPrint('Purchase pending: ${purchaseDetails.productID}');
        break;

      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        await _handleSuccessfulPurchase(purchaseDetails);
        break;

      case PurchaseStatus.error:
        await _handlePurchaseError(purchaseDetails);
        break;

      case PurchaseStatus.canceled:
        debugPrint('Purchase cancelled: ${purchaseDetails.productID}');
        break;
    }
  }

  /// Handle successful purchases
  Future<void> _handleSuccessfulPurchase(PurchaseDetails purchaseDetails) async {
    try {
      debugPrint('Processing successful purchase: ${purchaseDetails.productID}');

      // Validate purchase with backend
      final validationResult = await _validatePurchaseWithBackend(purchaseDetails);

      if (validationResult['success'] == true) {
        // Acknowledge the purchase
        await _acknowledgePurchase(purchaseDetails);
        debugPrint('Purchase validated and acknowledged: ${purchaseDetails.productID}');
      } else {
        debugPrint('Purchase validation failed: ${purchaseDetails.productID}');
        _errorController.add('Purchase validation failed: ${validationResult['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      debugPrint('Error handling successful purchase: $e');
      _errorController.add('Error processing purchase: $e');
    }
  }

  /// Handle purchase errors
  Future<void> _handlePurchaseError(PurchaseDetails purchaseDetails) async {
    final errorMessage = purchaseDetails.error?.message ?? 'Unknown error';
    debugPrint('Purchase error for ${purchaseDetails.productID}: $errorMessage');

    _errorController.add('Purchase failed: $errorMessage');
  }

  /// Validate purchase with backend API
  Future<Map<String, dynamic>> _validatePurchaseWithBackend(PurchaseDetails purchaseDetails) async {
    try {
      final isSubscription = _isSubscriptionProduct(purchaseDetails.productID);

      final requestData = {
        'purchaseToken': purchaseDetails.purchaseID ?? purchaseDetails.verificationData.serverVerificationData,
        'productId': purchaseDetails.productID,
        'isSubscription': isSubscription,
        'packageName': 'com.lgbtinder.app', // Replace with actual package name
      };

      debugPrint('Validating purchase with backend: ${purchaseDetails.productID}');

      final response = await _apiService.post<Map<String, dynamic>>(
        isSubscription ? '/api/google-play/validate-purchase' : '/api/google-play/validate-one-time-purchase',
        data: requestData,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return {
          'success': true,
          'data': response.data,
        };
      } else {
        return {
          'success': false,
          'message': response.message,
        };
      }
    } catch (e) {
      debugPrint('Backend validation error: $e');
      return {
        'success': false,
        'message': 'Backend validation failed: $e',
      };
    }
  }

  /// Acknowledge purchase with backend
  Future<void> _acknowledgePurchase(PurchaseDetails purchaseDetails) async {
    try {
      final isSubscription = _isSubscriptionProduct(purchaseDetails.productID);

      final requestData = {
        'purchaseToken': purchaseDetails.purchaseID ?? purchaseDetails.verificationData.serverVerificationData,
        'productId': purchaseDetails.productID,
        'isSubscription': isSubscription,
      };

      debugPrint('Acknowledging purchase: ${purchaseDetails.productID}');

      final response = await _apiService.post<Map<String, dynamic>>(
        '/api/google-play/acknowledge-purchase',
        data: requestData,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess) {
        debugPrint('Purchase acknowledged successfully: ${purchaseDetails.productID}');
      } else {
        debugPrint('Purchase acknowledgement failed: ${response.message}');
      }
    } catch (e) {
      debugPrint('Purchase acknowledgement error: $e');
    }
  }

  /// Query product details from Google Play
  Future<List<ProductDetails>> queryProductDetails(Set<String> productIds) async {
    try {
      final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(productIds);

      if (response.error != null) {
        _errorController.add('Failed to query products: ${response.error}');
        return [];
      }

      debugPrint('Queried ${response.productDetails.length} products');
      return response.productDetails;
    } catch (e) {
      _errorController.add('Error querying products: $e');
      return [];
    }
  }

  /// Query subscription products
  Future<List<ProductDetails>> querySubscriptionProducts() async {
    final subscriptionIds = {
      'bronze_base',
      'silver_base',
      'gold_base',
    };
    return queryProductDetails(subscriptionIds);
  }

  /// Query one-time products
  Future<List<ProductDetails>> queryOneTimeProducts() async {
    final productIds = {
      'superlike_small',
      'superlike_medium',
      'superlike_large',
      'superlike_mega',
    };
    return queryProductDetails(productIds);
  }

  /// Launch billing flow for a product
  Future<bool> launchBillingFlow(ProductDetails productDetails) async {
    try {
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: productDetails,
      );

      final bool success = await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      debugPrint('Billing flow launched for ${productDetails.id}: $success');
      return success;
    } catch (e) {
      debugPrint('Failed to launch billing flow: $e');

      // If billing is not available, queue the purchase for later
      final isAvailable = await _inAppPurchase.isAvailable();
      if (!isAvailable) {
        await _queuePurchaseForOffline(productDetails, true);
        _errorController.add('Billing not available. Purchase queued for when connection is restored.');
        return false;
      }

      _errorController.add('Failed to launch billing flow: $e');
      return false;
    }
  }

  /// Launch billing flow for consumable (superlike packs)
  Future<bool> launchBillingFlowForConsumable(ProductDetails productDetails) async {
    try {
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: productDetails,
      );

      final bool success = await _inAppPurchase.buyConsumable(purchaseParam: purchaseParam);
      debugPrint('Consumable billing flow launched for ${productDetails.id}: $success');
      return success;
    } catch (e) {
      debugPrint('Failed to launch consumable billing flow: $e');

      // If billing is not available, queue the purchase for later
      final isAvailable = await _inAppPurchase.isAvailable();
      if (!isAvailable) {
        await _queuePurchaseForOffline(productDetails, false);
        _errorController.add('Billing not available. Purchase queued for when connection is restored.');
        return false;
      }

      _errorController.add('Failed to launch consumable billing flow: $e');
      return false;
    }
  }

  /// Check if a product ID represents a subscription
  bool _isSubscriptionProduct(String productId) {
    return productId.contains('_base'); // bronze_base, silver_base, gold_base
  }

  /// Get current purchases
  Future<List<PurchaseDetails>> getCurrentPurchases() async {
    try {
      // Query past purchases for both Google Play and App Store
      // Note: queryPastPurchases() method doesn't exist in current in_app_purchase version
      // Using queryProductDetails() as a placeholder - needs to be updated when backend is ready
      final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(<String>{});

      if (response.error != null) {
        _errorController.add('Failed to query past purchases: ${response.error}');
        return [];
      }

      // TODO: Implement proper past purchases query when backend is ready
      return [];
    } catch (e) {
      _errorController.add('Failed to get current purchases: $e');
      return [];
    }
  }

  /// Restore purchases (for user-initiated restore)
  Future<void> restorePurchases() async {
    try {
      await _inAppPurchase.restorePurchases();
      debugPrint('Purchase restoration initiated');
    } catch (e) {
      _errorController.add('Failed to restore purchases: $e');
    }
  }

  /// Queue purchase for offline processing
  Future<void> _queuePurchaseForOffline(ProductDetails productDetails, bool isSubscription) async {
    try {
      final purchaseData = {
        'productId': productDetails.id,
        'isSubscription': isSubscription,
        'price': productDetails.price,
        'currency': productDetails.currencyCode,
        'title': productDetails.title,
        'description': productDetails.description,
        'timestamp': DateTime.now().toIso8601String(),
      };

      await _offlinePaymentService.queuePurchase(purchaseData);
      debugPrint('Purchase queued for offline processing: ${productDetails.id}');
    } catch (e) {
      debugPrint('Failed to queue purchase for offline: $e');
      _errorController.add('Failed to queue purchase for offline processing');
    }
  }

  /// Process pending purchases when connectivity is restored
  Future<void> processPendingPurchases() async {
    try {
      final hasPending = await _offlinePaymentService.hasPendingPurchases();
      if (hasPending) {
        debugPrint('Processing pending purchases...');
        await _offlinePaymentService.processPendingPurchases();
        debugPrint('Finished processing pending purchases');
      }
    } catch (e) {
      debugPrint('Failed to process pending purchases: $e');
      _errorController.add('Failed to process pending purchases');
    }
  }

  /// Get count of pending purchases
  Future<int> getPendingPurchasesCount() async {
    return await _offlinePaymentService.getPendingPurchasesCount();
  }

  /// Check if there are pending purchases
  Future<bool> hasPendingPurchases() async {
    return await _offlinePaymentService.hasPendingPurchases();
  }

  /// Dispose of resources
  void dispose() {
    _purchaseSubscription?.cancel();
    _billingAvailabilityController.close();
    _purchaseUpdatesController.close();
    _errorController.close();
  }

  /// Check if billing is available
  Future<bool> isBillingAvailable() async {
    return await _inAppPurchase.isAvailable();
  }
}
