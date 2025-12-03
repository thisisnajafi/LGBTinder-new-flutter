import 'package:in_app_purchase/in_app_purchase.dart';
import '../repositories/google_play_repository.dart';

/// Use case for initiating a Google Play purchase
class InitiateGooglePurchaseUseCase {
  final GooglePlayRepository _repository;

  InitiateGooglePurchaseUseCase(this._repository);

  /// Execute the use case
  Future<PurchaseResult> execute(String productId, bool isSubscription) async {
    try {
      // Query product details
      final products = isSubscription
          ? await _repository.querySubscriptionProducts()
          : await _repository.queryOneTimeProducts();

      // Find the requested product
      final productDetails = products.firstWhere(
        (product) => product.id == productId,
        orElse: () => throw Exception('Product not found: $productId'),
      );

      // Launch billing flow
      final success = isSubscription
          ? await _repository.launchSubscriptionBillingFlow(productDetails)
          : await _repository.launchConsumableBillingFlow(productDetails);

      if (success) {
        return PurchaseResult.success(productDetails);
      } else {
        return PurchaseResult.failure('Failed to launch billing flow');
      }
    } catch (e) {
      return PurchaseResult.failure('Purchase initiation failed: $e');
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
