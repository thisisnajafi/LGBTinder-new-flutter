import 'package:in_app_purchase/in_app_purchase.dart';
import '../../data/services/google_play_billing_service.dart';
import '../repositories/google_play_repository.dart';

/// Use case for initiating a Google Play purchase
class InitiateGooglePurchaseUseCase {
  final GooglePlayRepository _repository;

  InitiateGooglePurchaseUseCase(this._repository);

  /// Execute the use case
  Future<PurchaseResult> execute(String productId, bool isSubscription, {String? offerId}) async {
    try {
      if (!await _repository.isBillingAvailable()) {
        return PurchaseResult.failure(
          GooglePlayBillingService.billingUnavailableMessage,
        );
      }

      final products = await _repository.queryProducts({productId});
      var productDetails = GooglePlayBillingService.matchCatalogProduct(
        products,
        productId,
        basePlanId: isSubscription ? offerId : null,
      );
      // Product exists but the base plan ID differs from the backend's
      // google_offer_id: fall back to the product's first active base plan
      // rather than failing the purchase.
      if (productDetails == null && isSubscription) {
        productDetails =
            GooglePlayBillingService.matchCatalogProduct(products, productId);
      }

      if (productDetails == null) {
        return PurchaseResult.failure(
          _repository.lastFailureMessage ??
              GooglePlayBillingService.productNotFoundMessage(productId),
        );
      }

      // Launch billing flow
      final success = isSubscription
          ? await _repository.launchSubscriptionBillingFlow(productDetails, offerId: offerId)
          : await _repository.launchConsumableBillingFlow(productDetails);

      if (success) {
        return PurchaseResult.success(productDetails);
      } else {
        return PurchaseResult.failure(
          'Google Play could not open the purchase screen. Please try again.',
        );
      }
    } catch (e) {
      return PurchaseResult.failure('Could not start the Google Play purchase: $e');
    }
  }
}

/// Result of a purchase initiation attempt
class PurchaseResult {
  final bool isSuccess;
  final ProductDetails? productDetails;
  final String? errorMessage;

  PurchaseResult._({
    required this.isSuccess,
    this.productDetails,
    this.errorMessage,
  });

  /// Create a successful result
  factory PurchaseResult.success(ProductDetails productDetails) {
    return PurchaseResult._(
      isSuccess: true,
      productDetails: productDetails,
    );
  }

  /// Create a failure result
  factory PurchaseResult.failure(String errorMessage) {
    return PurchaseResult._(
      isSuccess: false,
      errorMessage: errorMessage,
    );
  }
}
