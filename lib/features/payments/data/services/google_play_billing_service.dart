import 'dart:async';
import 'dart:io';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../shared/services/api_service.dart';
import '../../../../core/services/offline_payment_service.dart';
import '../../../../core/services/app_logger.dart';
import 'marketing_attribution_service.dart';

/// Server-confirmed outcome for one Play purchase.
class BillingGrantResult {
  const BillingGrantResult({
    required this.productId,
    required this.granted,
    this.canceled = false,
    this.message,
  });

  final String productId;
  final bool granted;
  final bool canceled;
  final String? message;
}

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
  final StreamController<BillingGrantResult> _grantController = StreamController<BillingGrantResult>.broadcast();

  // Stream subscriptions
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  // Store offerId for purchases (keyed by productId, cleared after processing)
  final Map<String, String?> _pendingOfferIds = {};
  final Map<String, bool> _pendingIsSubscription = {};

  /// Called after a subscription is activated or restored on the backend.
  void Function()? onSubscriptionChanged;

  static const String _packageName = 'com.lgbtfinder';

  void _log(String message) {
    AppLogger.debug(message, tag: 'GooglePlayBilling');
  }

  /// Pick the Play [ProductDetails] whose base plan matches [basePlanId].
  ///
  /// Android returns one [ProductDetails] per subscription offer. Buying the
  /// first match charges the wrong period.
  static ProductDetails? matchCatalogProduct(
    List<ProductDetails> products,
    String productId, {
    String? basePlanId,
  }) {
    final matches = products.where((product) => product.id == productId).toList();
    if (matches.isEmpty) return null;

    final wanted = basePlanId?.trim();
    if (wanted == null || wanted.isEmpty) return matches.first;

    for (final product in matches) {
      if (product is! GooglePlayProductDetails) continue;
      final index = product.subscriptionIndex;
      final offers = product.productDetails.subscriptionOfferDetails;
      if (index == null || offers == null || index >= offers.length) continue;
      if (offers[index].basePlanId == wanted) return product;
    }

    return null;
  }

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

  /// Fires after the backend grants or refuses a purchase. Play status alone is not enough.
  Stream<BillingGrantResult> get grantResults => _grantController.stream;

  /// Subscribe before opening the billing sheet so a fast result is not missed.
  ({Future<BillingGrantResult> result, void Function() cancel}) trackGrant(String productId) {
    final completer = Completer<BillingGrantResult>();
    late final StreamSubscription<BillingGrantResult> subscription;
    subscription = grantResults.listen((event) {
      if (event.productId != productId || completer.isCompleted) return;
      completer.complete(event);
      subscription.cancel();
    });

    return (
      result: completer.future.timeout(
        const Duration(minutes: 3),
        onTimeout: () {
          subscription.cancel();
          return BillingGrantResult(
            productId: productId,
            granted: false,
            message: 'Purchase timed out. If you were charged, reopen the app to finish.',
          );
        },
      ),
      cancel: () {
        subscription.cancel();
        if (!completer.isCompleted) {
          completer.complete(BillingGrantResult(
            productId: productId,
            granted: false,
            canceled: true,
          ));
        }
      },
    );
  }

  void _emitGrant(
    String productId, {
    required bool granted,
    bool canceled = false,
    String? message,
  }) {
    if (_grantController.isClosed) return;
    _grantController.add(BillingGrantResult(
      productId: productId,
      granted: granted,
      canceled: canceled,
      message: message,
    ));
  }

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
          _log('Purchase stream closed');
        },
      );

      // Process any pending purchases that were queued offline
      await processPendingPurchases();

      // Re-process unfinished Play purchases from a prior session
      await _processUnfinishedPurchases();

      // Sync subscription status on initialization
      await syncSubscriptionStatus();

      // Start periodic status sync (every 5 minutes)
      startPeriodicStatusSync();

      _log('Google Play Billing initialized successfully');
    } catch (e) {
      _errorController.add('Failed to initialize billing: $e');
      _log('Billing initialization error: $e');
    }
  }

  /// Handle purchase updates from the stream
  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) async {
    _log('Purchase update received: ${purchaseDetailsList.length} purchases');

    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      await _handlePurchaseUpdate(purchaseDetails);
    }

    // Emit after backend verify / complete so UI waiters see a finished purchase.
    _purchaseUpdatesController.add(purchaseDetailsList);
  }

  /// Handle individual purchase updates
  Future<void> _handlePurchaseUpdate(PurchaseDetails purchaseDetails) async {
    _log('Handling purchase: ${purchaseDetails.productID}, status: ${purchaseDetails.status}');

    switch (purchaseDetails.status) {
      case PurchaseStatus.pending:
        _log('Purchase pending: ${purchaseDetails.productID}');
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
        _log('Purchase cancelled: ${purchaseDetails.productID}');
        _emitGrant(purchaseDetails.productID, granted: false, canceled: true);
        break;
    }
  }

  /// Handle successful purchases
  Future<void> _handleSuccessfulPurchase(PurchaseDetails purchaseDetails, {String? offerId}) async {
    try {
      _log('Processing successful purchase: ${purchaseDetails.productID}');

      if (_purchaseIsSubscription(purchaseDetails.productID)) {
        final result = await _activateSubscriptionWithBackend(purchaseDetails, offerId: offerId);

        if (result['success'] == true) {
          await _completePurchase(purchaseDetails);
          onSubscriptionChanged?.call();
          _emitGrant(purchaseDetails.productID, granted: true);
          _log('Subscription activated and completed: ${purchaseDetails.productID}');
        } else {
          _log('Subscription activation failed: ${purchaseDetails.productID}');
          final message = result['message']?.toString() ?? 'Subscription activation failed';
          if (result['error'] != null) {
            _userFriendlyErrorController.add(Map<String, dynamic>.from(result['error'] as Map));
          } else {
            _errorController.add('Subscription activation failed: $message');
          }
          // Subscriptions stay restorable after acknowledge. Completing here
          // prevents Google's 3-day auto-refund while webhook/restore retries grant.
          await _completePurchase(purchaseDetails);
          _emitGrant(purchaseDetails.productID, granted: false, message: message);
        }
        return;
      }

      // One-time purchases: validate with legacy endpoint, then complete
      final validationResult = await _validatePurchaseWithBackend(purchaseDetails, offerId: offerId);

      if (validationResult['success'] == true) {
        await _acknowledgePurchase(purchaseDetails);
        await _completePurchase(purchaseDetails);
        _emitGrant(purchaseDetails.productID, granted: true);
        _log('Purchase validated and completed: ${purchaseDetails.productID}');
      } else {
        _log('Purchase validation failed: ${purchaseDetails.productID}');
        final message = validationResult['message']?.toString() ?? 'Purchase validation failed';
        if (validationResult['error'] != null) {
          _userFriendlyErrorController.add(validationResult['error']);
        } else {
          _errorController.add('Purchase validation failed: $message');
        }
        _emitGrant(purchaseDetails.productID, granted: false, message: message);
      }
    } catch (e) {
      _log('Error handling successful purchase: $e');
      _errorController.add('Error processing purchase: $e');
      _emitGrant(purchaseDetails.productID, granted: false, message: 'Error processing purchase');
    }
  }

  /// Handle restored purchases
  Future<void> _handleRestoredPurchase(PurchaseDetails purchaseDetails) async {
    try {
      _log('Processing restored purchase: ${purchaseDetails.productID}');

      if (_purchaseIsSubscription(purchaseDetails.productID)) {
        final result = await _restoreSubscriptionWithBackend(purchaseDetails);

        if (result['success'] == true) {
          await _completePurchase(purchaseDetails);
          onSubscriptionChanged?.call();
          _emitGrant(purchaseDetails.productID, granted: true);
          _log('Restored subscription validated: ${purchaseDetails.productID}');
        } else {
          _log('Restored subscription failed: ${purchaseDetails.productID}');
          final message = result['message']?.toString() ?? 'Restored purchase failed';
          _errorController.add('Restored purchase failed: $message');
          await _completePurchase(purchaseDetails);
          _emitGrant(purchaseDetails.productID, granted: false, message: message);
        }
        return;
      }

      final validationResult = await _validatePurchaseWithBackend(purchaseDetails);

      if (validationResult['success'] == true) {
        if (validationResult['data'] != null) {
          final data = validationResult['data'] as Map<String, dynamic>;
          final acknowledged = data['acknowledged'] ?? false;

          if (!acknowledged) {
            await _acknowledgePurchase(purchaseDetails);
          }
        }
        await _completePurchase(purchaseDetails);
        _emitGrant(purchaseDetails.productID, granted: true);
        _log('Restored one-time purchase validated: ${purchaseDetails.productID}');
      } else {
        _log('Restored purchase validation failed: ${purchaseDetails.productID}');
        final message = validationResult['message']?.toString() ?? 'Restored purchase validation failed';
        _errorController.add('Restored purchase validation failed: $message');
        _emitGrant(purchaseDetails.productID, granted: false, message: message);
      }
    } catch (e) {
      _log('Error handling restored purchase: $e');
      _errorController.add('Error processing restored purchase: $e');
      _emitGrant(purchaseDetails.productID, granted: false, message: 'Error processing restored purchase');
    }
  }

  /// Handle purchase errors
  Future<void> _handlePurchaseError(PurchaseDetails purchaseDetails) async {
    final errorMessage = purchaseDetails.error?.message ?? 'Unknown error';
    _log('Purchase error for ${purchaseDetails.productID}: $errorMessage');

    AppLogger.error(
      'Purchase failed',
      tag: 'GooglePlayBilling',
      error: purchaseDetails.error,
    );

    _errorController.add('Purchase failed: $errorMessage');
    _emitGrant(purchaseDetails.productID, granted: false, message: errorMessage);
  }

  /// Complete the purchase with Google Play.
  ///
  /// Call after backend success for all products. For subscriptions, also call
  /// on backend failure so Google does not auto-refund after 3 days — the token
  /// remains restorable. Consumables must not be consumed until entitlement is
  /// granted (Play will redeliver unfinished purchases).
  Future<void> _completePurchase(PurchaseDetails purchaseDetails) async {
    if (purchaseDetails.pendingCompletePurchase) {
      await _inAppPurchase.completePurchase(purchaseDetails);
      _log('completePurchase called for ${purchaseDetails.productID}');
    }
  }

  /// Launch a consumable purchase and return whether the Play sheet opened.
  Future<bool> purchaseConsumableProduct(String productId) async {
    if (!await isBillingAvailable()) {
      _errorController.add('Google Play Billing is not available on this device');
      return false;
    }
    final products = await queryProductDetails({productId});
    if (products.isEmpty) {
      _errorController.add('Product not available: $productId');
      return false;
    }
    return launchBillingFlowForConsumable(products.first);
  }

  /// Wait until Play reports a terminal status for [productId].
  Future<PurchaseStatus?> waitForPurchaseOutcome(
    String productId, {
    Duration timeout = const Duration(minutes: 5),
  }) async {
    try {
      return await purchaseUpdates
          .expand((list) => list)
          .where((purchase) => purchase.productID == productId)
          .map((purchase) => purchase.status)
          .firstWhere(
            (status) =>
                status == PurchaseStatus.purchased ||
                status == PurchaseStatus.restored ||
                status == PurchaseStatus.error ||
                status == PurchaseStatus.canceled,
          )
          .timeout(timeout);
    } on TimeoutException {
      return null;
    }
  }

  /// Activate subscription via lifecycle API after Play purchase.
  Future<Map<String, dynamic>> _activateSubscriptionWithBackend(
    PurchaseDetails purchaseDetails, {
    String? offerId,
  }) async {
    try {
      final purchaseToken = _extractPurchaseToken(purchaseDetails);
      if (purchaseToken.isEmpty) {
        throw Exception('Unable to extract purchase token from purchase details');
      }

      _log('Activating subscription with backend: ${purchaseDetails.productID}');

      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.subscriptionsActivate,
        data: {
          'purchase_token': purchaseToken,
          'product_id': purchaseDetails.productID,
          'package_name': _packageName,
          if (offerId != null && offerId.trim().isNotEmpty) 'offer_id': offerId.trim(),
        },
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess) {
        final hasAttribution = await _marketingAttributionService.hasAttribution();
        if (hasAttribution) {
          await _marketingAttributionService.clearAttribution();
        }
        return {'success': true, 'data': response.data};
      }

      final errorData = response.data?['error'] ?? response.data;
      if (errorData != null && errorData is Map) {
        _userFriendlyErrorController.add(Map<String, dynamic>.from(errorData));
      }

      return {
        'success': false,
        'message': response.message,
        'error': errorData,
      };
    } catch (e) {
      _log('Subscription activation error: $e');
      return {
        'success': false,
        'message': 'Subscription activation failed: $e',
      };
    }
  }

  /// Restore subscription via lifecycle API.
  Future<Map<String, dynamic>> _restoreSubscriptionWithBackend(
    PurchaseDetails purchaseDetails,
  ) async {
    try {
      final purchaseToken = _extractPurchaseToken(purchaseDetails);
      if (purchaseToken.isEmpty) {
        throw Exception('Unable to extract purchase token from purchase details');
      }

      _log('Restoring subscription with backend: ${purchaseDetails.productID}');

      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.subscriptionsRestore,
        data: {'purchase_token': purchaseToken},
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess) {
        return {'success': true, 'data': response.data};
      }

      return {
        'success': false,
        'message': response.message,
      };
    } catch (e) {
      _log('Subscription restore error: $e');
      return {
        'success': false,
        'message': 'Subscription restore failed: $e',
      };
    }
  }

  /// Re-query Play for purchases that were not completed in a prior session.
  Future<void> _processUnfinishedPurchases() async {
    try {
      await _inAppPurchase.restorePurchases();
    } catch (e) {
      _log('Failed to process unfinished purchases on init: $e');
    }
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
        'packageName': _packageName,
        if (offerId != null) 'offerId': offerId,
        // Add marketing attribution if available
        if (hasAttribution) ...attributionData.map((key, value) => MapEntry(key, value ?? '')),
      };

      _log('Validating purchase with backend: ${purchaseDetails.productID}');

      final response = await _apiService.post<Map<String, dynamic>>(
        isSubscription ? ApiEndpoints.googlePlayValidatePurchase : ApiEndpoints.googlePlayValidateOneTimePurchase,
        data: requestData,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess) {
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
          _userFriendlyErrorController.add(Map<String, dynamic>.from(errorData));
        }

        return {
          'success': false,
          'message': response.message,
          'error': errorData,
        };
      }
    } catch (e) {
      _log('Backend validation error: $e');
      return {
        'success': false,
        'message': 'Backend validation failed: $e',
      };
    }
  }

  /// Extract purchase token from purchase details
  String _extractPurchaseToken(PurchaseDetails purchaseDetails) {
    // `source` is the constant store identifier ('google_play' / 'app_store'),
    // not a token. The Play purchase token and the StoreKit receipt are both
    // carried in `serverVerificationData`.
    return purchaseDetails.verificationData.serverVerificationData;
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

      _log('Acknowledging purchase: ${purchaseDetails.productID}');

      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.googlePlayAcknowledgePurchase,
        data: requestData,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess) {
        _log('Purchase acknowledged successfully: ${purchaseDetails.productID}');
      } else {
        _log('Purchase acknowledgement failed: ${response.message}');
      }
    } catch (e) {
      _log('Purchase acknowledgement error: $e');
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

      _log('Queried ${response.productDetails.length} products');
      return response.productDetails;
    } catch (e) {
      _errorController.add('Error querying products: $e');
      return [];
    }
  }

  /// Query Play for the product IDs supplied by the backend catalog.
  Future<List<ProductDetails>> queryProducts(Set<String> productIds) async {
    if (productIds.isEmpty) return [];
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
        final PurchaseParam purchaseParam = productDetails is GooglePlayProductDetails
            ? GooglePlayPurchaseParam(
                productDetails: productDetails,
                offerToken: productDetails.offerToken,
              )
            : PurchaseParam(productDetails: productDetails);

        if (offerId != null) {
          _pendingOfferIds[productDetails.id] = offerId;
        }
        _pendingIsSubscription[productDetails.id] = true;

        final bool success = await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
        _log('Subscription billing flow launched for ${productDetails.id}${offerId != null ? ' with offer: $offerId' : ''}: $success');
        return success;
      } else {
        // For iOS, use standard purchase flow for subscriptions
        final PurchaseParam purchaseParam = PurchaseParam(
          productDetails: productDetails,
        );
        if (offerId != null) {
          _pendingOfferIds[productDetails.id] = offerId;
        }
        _pendingIsSubscription[productDetails.id] = true;

        // iOS also uses buyNonConsumable for subscriptions
        final bool success = await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
        _log('Subscription billing flow launched for ${productDetails.id}${offerId != null ? ' with offer: $offerId' : ''}: $success');
        return success;
      }
    } catch (e) {
      _log('Failed to launch subscription billing flow: $e');

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
      _log('Billing flow launched for ${productDetails.id}: $success');
      return success;
    } catch (e) {
      _log('Failed to launch billing flow: $e');

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
      _pendingIsSubscription[productDetails.id] = false;

      final bool success = await _inAppPurchase.buyConsumable(purchaseParam: purchaseParam);
      _log('Consumable billing flow launched for ${productDetails.id}: $success');
      return success;
    } catch (e) {
      _log('Failed to launch consumable billing flow: $e');

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

  bool _purchaseIsSubscription(String productId) {
    final known = _pendingIsSubscription[productId];
    if (known != null) return known;
    return _isSubscriptionProduct(productId);
  }

  /// Fallback for restored purchases that were not started in this session.
  bool _isSubscriptionProduct(String productId) {
    if (productId.contains('_base')) return true;
    if (productId.startsWith('lgbtfinder.')) return true;
    return productId.contains('.silder.') || productId.contains('.golden.');
  }

  /// Get current purchases from backend and validate them
  Future<List<PurchaseDetails>> getCurrentPurchases() async {
    try {
      _log('Fetching current purchases from backend...');

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
          _log('User has active subscription, triggering restore...');
          await restorePurchases();
        }
      }

      // The restorePurchases() call will trigger purchase stream
      // Purchases will be validated through the stream handler
      // Return empty list as purchases come through stream
      return [];
    } catch (e) {
      _log('Failed to get current purchases: $e');
      _errorController.add('Failed to get current purchases: $e');
      return [];
    }
  }

  /// Restore purchases (for user-initiated restore)
  /// This triggers the purchase stream which will validate purchases with backend
  Future<void> restorePurchases() async {
    try {
      _log('Initiating purchase restoration...');
      
      // Call restorePurchases which triggers purchase stream
      await _inAppPurchase.restorePurchases();
      
      _log('Purchase restoration initiated - purchases will come through stream');
      
      // Note: Restored purchases will come through _onPurchaseUpdate
      // and will be validated with backend automatically
    } catch (e) {
      _log('Failed to restore purchases: $e');
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
      _log('Purchase queued for offline processing: ${productDetails.id}');
    } catch (e) {
      _log('Failed to queue purchase for offline: $e');
      _errorController.add('Failed to queue purchase for offline processing');
    }
  }

  /// Process pending purchases when connectivity is restored
  Future<void> processPendingPurchases() async {
    try {
      final hasPending = await _offlinePaymentService.hasPendingPurchases();
      if (hasPending) {
        _log('Processing pending purchases...');
        await _offlinePaymentService.processPendingPurchases();
        _log('Finished processing pending purchases');
      }
    } catch (e) {
      _log('Failed to process pending purchases: $e');
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
    _grantController.close();
  }

  /// Check if billing is available
  Future<bool> isBillingAvailable() async {
    return await _inAppPurchase.isAvailable();
  }

  /// Sync subscription status with backend
  /// Call this periodically or on app launch to ensure status is up to date
  Future<Map<String, dynamic>?> syncSubscriptionStatus() async {
    try {
      _log('Syncing subscription status with backend...');

      final response = await _apiService.get<Map<String, dynamic>>(
        ApiEndpoints.googlePlaySubscriptionStatus,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data!['data'];
        _log('Subscription status synced: ${data?['hasActiveSubscription']}');
        return data;
      } else {
        _log('Failed to sync subscription status: ${response.message}');
        _errorController.add('Failed to sync subscription status: ${response.message}');
        return null;
      }
    } catch (e) {
      _log('Error syncing subscription status: $e');
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
    _log('Started periodic subscription status sync (interval: ${interval.inMinutes} minutes)');
  }

  /// Stop periodic subscription status sync
  void stopPeriodicStatusSync() {
    _statusSyncTimer?.cancel();
    _statusSyncTimer = null;
    _log('Stopped periodic subscription status sync');
  }
}
