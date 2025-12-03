/// Subscription plan model
class SubscriptionPlan {
  final int id;
  final String name;
  final String? description;
  final double price;
  final String currency;
  final String? duration; // 'monthly', 'yearly', etc.
  final List<String>? features;
  final bool isPopular;
  final String? stripePriceId;

  SubscriptionPlan({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.currency = 'usd',
    this.duration,
    this.features,
    this.isPopular = false,
    this.stripePriceId,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'usd',
      duration: json['duration'] as String?,
      features: json['features'] != null
          ? (json['features'] as List).map((e) => e.toString()).toList()
          : null,
      isPopular: json['is_popular'] as bool? ?? false,
      stripePriceId: json['stripe_price_id'] as String? ?? json['price_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (description != null) 'description': description,
      'price': price,
      'currency': currency,
      if (duration != null) 'duration': duration,
      if (features != null) 'features': features,
      'is_popular': isPopular,
      if (stripePriceId != null) 'stripe_price_id': stripePriceId,
    };
  }
}

/// Sub plan model (nested subscription options)
class SubPlan {
  final int id;
  final int planId;
  final String name;
  final String? description;
  final double price;
  final String currency;
  final String? duration;
  final String? stripePriceId;

  SubPlan({
    required this.id,
    required this.planId,
    required this.name,
    this.description,
    required this.price,
    this.currency = 'usd',
    this.duration,
    this.stripePriceId,
  });

  factory SubPlan.fromJson(Map<String, dynamic> json) {
    return SubPlan(
      id: json['id'] as int,
      planId: json['plan_id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'usd',
      duration: json['duration'] as String?,
      stripePriceId: json['stripe_price_id'] as String? ?? json['price_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plan_id': planId,
      'name': name,
      if (description != null) 'description': description,
      'price': price,
      'currency': currency,
      if (duration != null) 'duration': duration,
      if (stripePriceId != null) 'stripe_price_id': stripePriceId,
    };
  }
}

/// Subscription status model
class SubscriptionStatus {
  final bool isActive;
  final String? planName;
  final int? planId;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? nextBillingDate;
  final String? status; // 'active', 'canceled', 'expired', 'trial'
  final String? stripeSubscriptionId;
  final bool autoRenew;

  SubscriptionStatus({
    this.isActive = false,
    this.planName,
    this.planId,
    this.startDate,
    this.endDate,
    this.nextBillingDate,
    this.status,
    this.stripeSubscriptionId,
    this.autoRenew = true,
  });

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) {
    return SubscriptionStatus(
      isActive: json['is_active'] as bool? ?? false,
      planName: json['plan_name'] as String?,
      planId: json['plan_id'] as int?,
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'] as String)
          : null,
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      nextBillingDate: json['next_billing_date'] != null
          ? DateTime.parse(json['next_billing_date'] as String)
          : null,
      status: json['status'] as String?,
      stripeSubscriptionId: json['stripe_subscription_id'] as String?,
      autoRenew: json['auto_renew'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'is_active': isActive,
      if (planName != null) 'plan_name': planName,
      if (planId != null) 'plan_id': planId,
      if (startDate != null) 'start_date': startDate!.toIso8601String(),
      if (endDate != null) 'end_date': endDate!.toIso8601String(),
      if (nextBillingDate != null) 'next_billing_date': nextBillingDate!.toIso8601String(),
      if (status != null) 'status': status,
      if (stripeSubscriptionId != null) 'stripe_subscription_id': stripeSubscriptionId,
      'auto_renew': autoRenew,
    };
  }
}

/// Subscribe request
class SubscribeRequest {
  final int planId;
  final int subPlanId;

  SubscribeRequest({
    required this.planId,
    required this.subPlanId,
  });

  Map<String, dynamic> toJson() {
    return {
      'plan_id': planId,
      'sub_plan_id': subPlanId,
    };
  }
}

/// Stripe checkout request
class StripeCheckoutRequest {
  final String priceId;
  final String successUrl;
  final String cancelUrl;

  StripeCheckoutRequest({
    required this.priceId,
    required this.successUrl,
    required this.cancelUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'price_id': priceId,
      'success_url': successUrl,
      'cancel_url': cancelUrl,
    };
  }
}
