import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../providers/google_play_billing_provider.dart';

/// Test screen for Google Play Billing functionality

/// Test screen for Google Play Billing functionality
class GooglePlayBillingTestScreen extends ConsumerStatefulWidget {
  const GooglePlayBillingTestScreen({super.key});

  @override
  ConsumerState<GooglePlayBillingTestScreen> createState() => _GooglePlayBillingTestScreenState();
}

class _GooglePlayBillingTestScreenState extends ConsumerState<GooglePlayBillingTestScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize billing when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(googlePlayBillingInitializerProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Play Billing Test'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Billing Availability Status
            _buildBillingAvailabilitySection(),

            const SizedBox(height: 24),

            // Subscription Products
            _buildSubscriptionProductsSection(),

            const SizedBox(height: 24),

            // One-time Products
            _buildOneTimeProductsSection(),

            const SizedBox(height: 24),

            // Purchase Status
            _buildPurchaseStatusSection(),

            const SizedBox(height: 24),

            // Current Purchases
            _buildCurrentPurchasesSection(),

            const SizedBox(height: 24),

            // Error Display
            _buildErrorDisplaySection(),
          ],
        ),
      ),
    );
  }

  Widget _buildBillingAvailabilitySection() {
    final billingAvailabilityAsync = ref.watch(billingAvailabilityProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Billing Availability',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            billingAvailabilityAsync.when(
              data: (isAvailable) => Text(
                isAvailable ? '✅ Google Play Billing Available' : '❌ Google Play Billing Not Available',
                style: TextStyle(
                  color: isAvailable ? Colors.green : Colors.red,
                  fontSize: 16,
                ),
              ),
              loading: () => const CircularProgressIndicator(),
              error: (error, stack) => Text(
                'Error checking availability: $error',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionProductsSection() {
    final productsAsync = ref.watch(subscriptionProductsProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Subscription Products',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            productsAsync.when(
              data: (products) => products.isEmpty
                  ? const Text('No subscription products available')
                  : Column(
                      children: products.map((product) => _buildProductTile(product, true)).toList(),
                    ),
              loading: () => const CircularProgressIndicator(),
              error: (error, stack) => Text('Error loading products: $error'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOneTimeProductsSection() {
    final productsAsync = ref.watch(oneTimeProductsProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'One-time Products',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            productsAsync.when(
              data: (products) => products.isEmpty
                  ? const Text('No one-time products available')
                  : Column(
                      children: products.map((product) => _buildProductTile(product, false)).toList(),
                    ),
              loading: () => const CircularProgressIndicator(),
              error: (error, stack) => Text('Error loading products: $error'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductTile(ProductDetails product, bool isSubscription) {
    return ListTile(
      title: Text(product.title),
      subtitle: Text('${product.description}\nPrice: ${product.price}'),
      trailing: ElevatedButton(
        onPressed: () async {
          final purchaseNotifier = ref.read(googlePlayPurchaseProvider.notifier);
          await purchaseNotifier.initiatePurchase(product.id, isSubscription);

          // Reset after 3 seconds
          Future.delayed(const Duration(seconds: 3), () {
            purchaseNotifier.reset();
          });
        },
        child: Text(isSubscription ? 'Subscribe' : 'Purchase'),
      ),
    );
  }

  Widget _buildPurchaseStatusSection() {
    final purchaseState = ref.watch(googlePlayPurchaseProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Purchase Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (purchaseState.isLoading)
              const Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Text('Processing purchase...'),
                ],
              )
            else if (purchaseState.isSuccess)
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text('Purchase successful: ${purchaseState.productDetails?.title}'),
                  ),
                ],
              )
            else if (purchaseState.errorMessage != null)
              Row(
                children: [
                  const Icon(Icons.error, color: Colors.red),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text('Purchase failed: ${purchaseState.errorMessage}'),
                  ),
                ],
              )
            else
              const Text('No recent purchase activity'),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentPurchasesSection() {
    final purchasesAsync = ref.watch(currentPurchasesProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Current Purchases',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final repository = ref.read(googlePlayRepositoryProvider);
                    await repository.restorePurchases();
                  },
                  child: const Text('Restore'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            purchasesAsync.when(
              data: (purchases) => purchases.isEmpty
                  ? const Text('No current purchases')
                  : Column(
                      children: purchases.map((purchase) => ListTile(
                        title: Text(purchase.productID),
                        subtitle: Text('Status: ${purchase.status}, Transaction: ${purchase.purchaseID}'),
                        trailing: Icon(
                          purchase.status == PurchaseStatus.purchased ? Icons.check_circle : Icons.pending,
                          color: purchase.status == PurchaseStatus.purchased ? Colors.green : Colors.orange,
                        ),
                      )).toList(),
                    ),
              loading: () => const CircularProgressIndicator(),
              error: (error, stack) => Text('Error loading purchases: $error'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorDisplaySection() {
    final errorsAsync = ref.watch(billingErrorsProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Billing Errors',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            errorsAsync.when(
              data: (error) => error.isEmpty
                  ? const Text('No recent errors')
                  : Text(
                      error,
                      style: const TextStyle(color: Colors.red),
                    ),
              loading: () => const Text('Monitoring for errors...'),
              error: (error, stack) => Text('Error monitoring: $error'),
            ),
          ],
        ),
      ),
    );
  }
}
