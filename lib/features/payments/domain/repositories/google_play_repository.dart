import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../data/services/google_play_billing_service.dart';

/// Repository interface for Google Play Billing operations
abstract class GooglePlayRepository {
  /// Stream of billing availability status
  Stream<bool> get billingAvailability;

  /// Stream of purchase updates
  Stream<List<PurchaseDetails>> get purchaseUpdates;

  /// Stream of errors
  Stream<String> get errors;

  /// Initialize the billing service
  Future<void> initialize();

  /// Query subscription products
  Future<List<ProductDetails>> querySubscriptionProducts();

  /// Query one-time products
  Future<List<ProductDetails>> queryOneTimeProducts();

  /// Launch billing flow for subscriptions
  Future<bool> launchSubscriptionBillingFlow(ProductDetails productDetails, {String? offerId});

  /// Launch billing flow for consumables (superlike packs)
  Future<bool> launchConsumableBillingFlow(ProductDetails productDetails);

  /// Get current purchases
  Future<List<PurchaseDetails>> getCurrentPurchases();

  /// Restore purchases
  Future<void> restorePurchases();

  /// Check if billing is available
  Future<bool> isBillingAvailable();

  /// Sync subscription status with backend
  Future<Map<String, dynamic>?> syncSubscriptionStatus();

  /// Start periodic subscription status sync
  void startPeriodicStatusSync({Duration interval = const Duration(minutes: 5)});

  /// Stop periodic subscription status sync
  void stopPeriodicStatusSync();

  /// Dispose resources
  void dispose();
}

/// Repository implementation for Google Play Billing
class GooglePlayRepositoryImpl implements GooglePlayRepository {
  final GooglePlayBillingService _billingService;

  GooglePlayRepositoryImpl(this._billingService);

  @override
  Stream<bool> get billingAvailability => _billingService.billingAvailability;

  @override
  Stream<List<PurchaseDetails>> get purchaseUpdates => _billingService.purchaseUpdates;

  @override
  Stream<String> get errors => _billingService.errors;

  @override
  Future<void> initialize() async {
    // The service initializes itself in constructor
    await _billingService.isBillingAvailable();
  }

  @override
  Future<List<ProductDetails>> querySubscriptionProducts() async {
    return await _billingService.querySubscriptionProducts();
  }

  @override
  Future<List<ProductDetails>> queryOneTimeProducts() async {
    return await _billingService.queryOneTimeProducts();
  }

  @override
  Future<bool> launchSubscriptionBillingFlow(ProductDetails productDetails, {String? offerId}) async {
    return await _billingService.launchSubscriptionBillingFlow(productDetails, offerId: offerId);
  }

  @override
  Future<bool> launchConsumableBillingFlow(ProductDetails productDetails) async {
    return await _billingService.launchBillingFlowForConsumable(productDetails);
  }

  @override
  Future<List<PurchaseDetails>> getCurrentPurchases() async {
    return await _billingService.getCurrentPurchases();
  }

  @override
  Future<void> restorePurchases() async {
    await _billingService.restorePurchases();
  }

  @override
  Future<bool> isBillingAvailable() async {
    return await _billingService.isBillingAvailable();
  }

  @override
  Future<Map<String, dynamic>?> syncSubscriptionStatus() async {
    return await _billingService.syncSubscriptionStatus();
  }

  @override
  void startPeriodicStatusSync({Duration interval = const Duration(minutes: 5)}) {
    _billingService.startPeriodicStatusSync(interval: interval);
  }

  @override
  void stopPeriodicStatusSync() {
    _billingService.stopPeriodicStatusSync();
  }

  @override
  void dispose() {
    _billingService.dispose();
  }
}
