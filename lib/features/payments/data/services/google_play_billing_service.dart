import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import '../../../../shared/services/api_service.dart';
import '../../../../core/services/offline_payment_service.dart';
import 'marketing_attribution_service.dart';

/// Google Play Billing Service for handling in-app purchases and subscriptions
class GooglePlayBillingService {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  final ApiService _apiService;
  final OfflinePaymentService _offlinePaymentService;
  final MarketingAttributionService _marketingAttributionService;

  // Stream controllers for reactive updates
  final StreamController<bool> _billingAvailabilityController = StreamController<bool>.broadcast();
  final StreamController<List<PurchaseDetails>> _purchaseUpdatesController = StreamController<List<PurchaseDetails>>.broadcast();
  final StreamController<String> _errorController = StreamController<String>.broadcast();
  final StreamController<Map<String, dynamic>> _userFriendlyErrorController = StreamController<Map<String, dynamic>>.broadcast();

  // Stream subscriptions
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  // Store offerId for purchases (keyed by productId, cleared after processing)
  final Map<String, String?> _pendingOfferIds = {};

  GooglePlayBillingService(
    this._apiService,
    this._offlinePaymentService,
    this._marketingAttributionService,
  ) {
    _initialize();
  }

  // Public stream for user-friendly errors
  Stream<Map<String, dynamic>> get userFriendlyErrors => _userFriendlyErrorController.stream;

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

      // Sync subscription status on initialization
      await syncSubscriptionStatus();

      // Start periodic status sync (every 5 minutes)
      startPeriodicStatusSync();

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
        // Get offerId if stored for this product
        final offerId = _pendingOfferIds[purchaseDetails.productID];
        await _handleSuccessfulPurchase(purchaseDetails, offerId: offerId);
        // Clear offerId after processing
        _pendingOfferIds.remove(purchaseDetails.productID);
        break;

      case PurchaseStatus.restored:
        // Handle restored purchases - validate with backend
        await _handleRestoredPurchase(purchaseDetails);
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
  Future<void> _handleSuccessfulPurchase(PurchaseDetails purchaseDetails, {String? offerId}) async {
    try {
      debugPrint('Processing successful purchase: ${purchaseDetails.productID}');

      // Validate purchase with backend (includes marketing attribution)
      final validationResult = await _validatePurchaseWithBackend(purchaseDetails, offerId: offerId);

      if (validationResult['success'] == true) {
        // Acknowledge the purchase
        await _acknowledgePurchase(purchaseDetails);
        debugPrint('Purchase validated and acknowledged: ${purchaseDetails.productID}');
      } else {
        debugPrint('Purchase validation failed: ${purchaseDetails.productID}');
        // Check if there's user-friendly error data
        if (validationResult['error'] != null) {
          _userFriendlyErrorController.add(validationResult['error']);
        } else {
          _errorController.add('Purchase validation failed: ${validationResult['message'] ?? 'Unknown error'}');
        }
      }
    } catch (e) {
      debugPrint('Error handling successful purchase: $e');
      _errorController.add('Error processing purchase: $e');
    }
  }

  /// Handle restored purchases
  Future<void> _handleRestoredPurchase(PurchaseDetails purchaseDetails) async {
    try {
      debugPrint('Processing restored purchase: ${purchaseDetails.productID}');

      // Validate restored purchase with backend
      final validationResult = await _validatePurchaseWithBackend(purchaseDetails);

      if (validationResult['success'] == true) {
        // For restored purchases, check if already acknowledged
        // If not acknowledged, acknowledge it
        if (validationResult['data'] != null) {
          final data = validationResult['data'] as Map<String, dynamic>;
          final acknowledged = data['acknowledged'] ?? false;
          
          if (!acknowledged) {
            await _acknowledgePurchase(purchaseDetails);
            debugPrint('Restored purchase acknowledged: ${purchaseDetails.productID}');
          } else {
            debugPrint('Restored purchase already acknowledged: ${purchaseDetails.productID}');
          }
        }
        
        debugPrint('Restored purchase validated: ${purchaseDetails.productID}');
      } else {
        debugPrint('Restored purchase validation failed: ${purchaseDetails.productID}');
        _errorController.add('Restored purchase validation failed: ${validationResult['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      debugPrint('Error handling restored purchase: $e');
      _errorController.add('Error processing restored purchase: $e');
    }
  }

  /// Handle purchase errors
  Future<void> _handlePurchaseError(PurchaseDetails purchaseDetails) async {
    final errorMessage = purchaseDetails.error?.message ?? 'Unknown error';
    debugPrint('Purchase error for ${purchaseDetails.productID}: $errorMessage');

    _errorController.add('Purchase failed: $errorMessage');
  }

  /// Validate purchase with backend API
  Future<Map<String, dynamic>> _validatePurchaseWithBackend(PurchaseDetails purchaseDetails, {String? offerId}) async {
    try {
      final isSubscription = _isSubscriptionProduct(purchaseDetails.productID);

      // Extract purchase token using helper method
      final purchaseToken = _extractPurchaseToken(purchaseDetails);
      if (purchaseToken.isEmpty) {
        throw Exception('Unable to extract purchase token from purchase details');
      }

      // Get marketing attribution data
      final attributionData = await _marketingAttributionService.getAttributionData();
      final hasAttribution = await _marketingAttributionService.hasAttribution();

      final requestData = {
        'purchaseToken': purchaseToken,
        'productId': purchaseDetails.productID,
        'isSubscription': isSubscription,
        'packageName': 'com.lgbtfinder.app', // Replace with actual package name
        if (offerId != null) 'offerId': offerId,
        // Add marketing attribution if available
        if (hasAttribution) ...attributionData.map((key, value) => MapEntry(key, value ?? '')),
      };

      debugPrint('Validating purchase with backend: ${purchaseDetails.productID}');

      final response = await _apiService.post<Map<String, dynamic>>(
        isSubscription ? '/api/google-play/validate-purchase' : '/api/google-play/validate-one-time-purchase',
        data: requestData,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        // Clear attribution after successful purchase
        if (hasAttribution) {
          await _marketingAttributionService.clearAttribution();
        }
        return {
          'success': true,
          'data': response.data,
        };
      } else {
        // Check if response contains user-friendly error information
        final errorData = response.data?['error'] ?? response.data;
        if (errorData != null && errorData is Map) {
          // Emit user-friendly error
          _userFriendlyErrorController.add(errorData);
        }

        return {
          'success': false,
          'message': response.message,
          'error': errorData,
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

  /// Extract purchase token from purchase details
  String _extractPurchaseToken(PurchaseDetails purchaseDetails) {
    // For Android (Google Play), the purchase token is in verificationData.source
    // For iOS (App Store), it's in verificationData.serverVerificationData
    String purchaseToken;
    if (Platform.isAndroid) {
      // Android/Google Play: Extract from verificationData.source
      final androidVerificationData = purchaseDetails.verificationData.source;
      if (androidVerificationData != null && androidVerificationData.isNotEmpty) {
        // Parse the JSON to extract purchaseToken
        try {
          final data = jsonDecode(androidVerificationData);
          purchaseToken = data['purchaseToken'] ?? data['token'] ?? '';
        } catch (e) {
          // If parsing fails, try to extract from the raw string
          purchaseToken = androidVerificationData;
        }
      } else {
        // Fallback to serverVerificationData if source is empty
        purchaseToken = purchaseDetails.verificationData.serverVerificationData;
      }
    } else {
      // iOS/App Store: Use serverVerificationData
      purchaseToken = purchaseDetails.verificationData.serverVerificationData;
    }

    // If still empty, use purchaseID as last resort
    if (purchaseToken.isEmpty) {
      purchaseToken = purchaseDetails.purchaseID ?? '';
    }

    return purchaseToken;
  }

  /// Acknowledge purchase with backend
  Future<void> _acknowledgePurchase(PurchaseDetails purchaseDetails) async {
    try {
      final isSubscription = _isSubscriptionProduct(purchaseDetails.productID);

      final purchaseToken = _extractPurchaseToken(purchaseDetails);
      if (purchaseToken.isEmpty) {
        throw Exception('Unable to extract purchase token for acknowledgement');
      }

      final requestData = {
        'purchaseToken': purchaseToken,
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

  /// Launch billing flow for a subscription
  /// [productDetails] - The subscription product details
  /// [offerId] - Optional offer ID for subscription offers (monthly, quarterly, annual)
  /// Note: The in_app_purchase package handles subscriptions through buyNonConsumable,
  /// but we ensure proper subscription handling by checking product type
  Future<bool> launchSubscriptionBillingFlow(ProductDetails productDetails, {String? offerId}) async {
    try {
      // Verify this is actually a subscription product
      if (!_isSubscriptionProduct(productDetails.id)) {
        throw Exception('Product ${productDetails.id} is not a subscription product');
      }

      if (Platform.isAndroid) {
        // For Android, use the Android-specific purchase param for subscriptions
        final InAppPurchaseAndroidPlatformAddition androidAddition =
            _inAppPurchase.getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
        
        // Create purchase param for subscription
        // Note: For subscriptions, we use buyNonConsumable but the package handles it as subscription
        final PurchaseParam purchaseParam = PurchaseParam(
          productDetails: productDetails,
        );

        // Store offerId for later retrieval during purchase processing
        if (offerId != null) {
          _pendingOfferIds[productDetails.id] = offerId;
        }

        // Use buyNonConsumable for subscriptions (this is how in_app_purchase handles subscriptions)
        final bool success = await androidAddition.buyNonConsumable(purchaseParam: purchaseParam);
        debugPrint('Subscription billing flow launched for ${productDetails.id}${offerId != null ? ' with offer: $offerId' : ''}: $success');
        return success;
      } else {
        // For iOS, use standard purchase flow for subscriptions
        final PurchaseParam purchaseParam = PurchaseParam(
          productDetails: productDetails,
        );
        // Store offerId for later retrieval during purchase processing
        if (offerId != null) {
          _pendingOfferIds[productDetails.id] = offerId;
        }

        // iOS also uses buyNonConsumable for subscriptions
        final bool success = await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
        debugPrint('Subscription billing flow launched for ${productDetails.id}${offerId != null ? ' with offer: $offerId' : ''}: $success');
        return success;
      }
    } catch (e) {
      debugPrint('Failed to launch subscription billing flow: $e');

      // If billing is not available, queue the purchase for later
      final isAvailable = await _inAppPurchase.isAvailable();
      if (!isAvailable) {
        await _queuePurchaseForOffline(productDetails, true);
        _errorController.add('Billing not available. Purchase queued for when connection is restored.');
        return false;
      }

      _errorController.add('Failed to launch subscription billing flow: $e');
      return false;
    }
  }

  /// Launch billing flow for a non-consumable product (deprecated - use launchSubscriptionBillingFlow for subscriptions)
  /// This method is kept for backward compatibility but should not be used for subscriptions
  @Deprecated('Use launchSubscriptionBillingFlow for subscriptions instead')
  Future<bool> launchBillingFlow(ProductDetails productDetails) async {
    // Check if it's a subscription and route to appropriate method
    if (_isSubscriptionProduct(productDetails.id)) {
      return launchSubscriptionBillingFlow(productDetails);
    }
    
    // For non-subscription products, use buyNonConsumable
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
        await _queuePurchaseForOffline(productDetails, false);
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

  /// Get current purchases from backend and validate them
  Future<List<PurchaseDetails>> getCurrentPurchases() async {
    try {
      debugPrint('Fetching current purchases from backend...');

      // First, get purchases from backend API
      final response = await _apiService.get<Map<String, dynamic>>(
        '/api/google-play/subscription/status',
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data!['data'];
        
        if (data != null && data['hasActiveSubscription'] == true) {
          // If user has active subscription, restorePurchases will trigger purchase stream
          // which will validate with backend
          debugPrint('User has active subscription, triggering restore...');
          await restorePurchases();
        }
      }

      // The restorePurchases() call will trigger purchase stream
      // Purchases will be validated through the stream handler
      // Return empty list as purchases come through stream
      return [];
    } catch (e) {
      debugPrint('Failed to get current purchases: $e');
      _errorController.add('Failed to get current purchases: $e');
      return [];
    }
  }

  /// Restore purchases (for user-initiated restore)
  /// This triggers the purchase stream which will validate purchases with backend
  Future<void> restorePurchases() async {
    try {
      debugPrint('Initiating purchase restoration...');
      
      // Call restorePurchases which triggers purchase stream
      await _inAppPurchase.restorePurchases();
      
      debugPrint('Purchase restoration initiated - purchases will come through stream');
      
      // Note: Restored purchases will come through _onPurchaseUpdate
      // and will be validated with backend automatically
    } catch (e) {
      debugPrint('Failed to restore purchases: $e');
      _errorController.add('Failed to restore purchases: $e');
      rethrow;
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
    _statusSyncTimer?.cancel();
    _billingAvailabilityController.close();
    _purchaseUpdatesController.close();
    _errorController.close();
  }

  /// Check if billing is available
  Future<bool> isBillingAvailable() async {
    return await _inAppPurchase.isAvailable();
  }

  /// Sync subscription status with backend
  /// Call this periodically or on app launch to ensure status is up to date
  Future<Map<String, dynamic>?> syncSubscriptionStatus() async {
    try {
      debugPrint('Syncing subscription status with backend...');

      final response = await _apiService.get<Map<String, dynamic>>(
        '/api/google-play/subscription/status',
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data!['data'];
        debugPrint('Subscription status synced: ${data?['hasActiveSubscription']}');
        return data;
      } else {
        debugPrint('Failed to sync subscription status: ${response.message}');
        _errorController.add('Failed to sync subscription status: ${response.message}');
        return null;
      }
    } catch (e) {
      debugPrint('Error syncing subscription status: $e');
      _errorController.add('Error syncing subscription status: $e');
      return null;
    }
  }

  /// Periodic subscription status sync
  /// Call this to set up automatic periodic syncing
  Timer? _statusSyncTimer;

  /// Start periodic subscription status sync
  /// [interval] - Duration between syncs (default: 5 minutes)
  void startPeriodicStatusSync({Duration interval = const Duration(minutes: 5)}) {
    _statusSyncTimer?.cancel();
    _statusSyncTimer = Timer.periodic(interval, (timer) async {
      await syncSubscriptionStatus();
    });
    debugPrint('Started periodic subscription status sync (interval: ${interval.inMinutes} minutes)');
  }

  /// Stop periodic subscription status sync
  void stopPeriodicStatusSync() {
    _statusSyncTimer?.cancel();
    _statusSyncTimer = null;
    debugPrint('Stopped periodic subscription status sync');
  }
}
