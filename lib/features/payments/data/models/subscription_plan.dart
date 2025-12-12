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
    // Get ID - use 0 as fallback if not provided
    int planId = 0;
    if (json['id'] != null) {
      planId = (json['id'] is int) ? json['id'] as int : int.tryParse(json['id'].toString()) ?? 0;
    } else if (json['plan_id'] != null) {
      planId = (json['plan_id'] is int) ? json['plan_id'] as int : int.tryParse(json['plan_id'].toString()) ?? 0;
    }
    
    // Get price and duration for name construction fallback
    double price = (json['price'] as num?)?.toDouble() ?? 0.0;
    String? duration = json['duration']?.toString();
    
    // Get name from multiple possible fields (name, title, plan_name, plan_title)
    String name = json['name']?.toString() ?? 
                  json['title']?.toString() ?? 
                  json['plan_name']?.toString() ?? 
                  json['plan_title']?.toString() ??
                  '';
    
    // If name is still empty, construct from available data
    if (name.isEmpty) {
      if (duration != null && duration.isNotEmpty) {
        name = duration.toUpperCase();
      } else if (price > 0) {
        String currencySymbol = (json['currency']?.toString() ?? 'usd').toUpperCase() == 'USD' ? '\$' : (json['currency']?.toString() ?? 'usd').toUpperCase();
        name = '$currencySymbol${price.toStringAsFixed(2)} Plan';
      } else {
        name = planId > 0 ? 'Plan $planId' : 'Subscription Plan';
      }
    }
    
    return SubscriptionPlan(
      id: planId,
      name: name,
      description: json['description']?.toString(),
      price: price,
      currency: json['currency']?.toString() ?? 'usd',
      duration: duration,
      features: json['features'] != null && json['features'] is List
          ? (json['features'] as List).map((e) => e.toString()).toList()
          : null,
      isPopular: json['is_popular'] == true || json['is_popular'] == 1,
      stripePriceId: json['stripe_price_id']?.toString() ?? json['price_id']?.toString(),
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
    this.id = 0, // Made optional with default value
    required this.planId,
    required this.name,
    this.description,
    required this.price,
    this.currency = 'usd',
    this.duration,
    this.stripePriceId,
  });

  factory SubPlan.fromJson(Map<String, dynamic> json) {
    // Get ID from multiple possible fields (id, sub_plan_id, subplan_id)
    // ID is optional since some APIs might not send it for sub-plans
    int subPlanId = 0;
    if (json['id'] != null) {
      subPlanId = (json['id'] is int) ? json['id'] as int : int.tryParse(json['id'].toString()) ?? 0;
    } else if (json['sub_plan_id'] != null) {
      subPlanId = (json['sub_plan_id'] is int) ? json['sub_plan_id'] as int : int.tryParse(json['sub_plan_id'].toString()) ?? 0;
    } else if (json['subplan_id'] != null) {
      subPlanId = (json['subplan_id'] is int) ? json['subplan_id'] as int : int.tryParse(json['subplan_id'].toString()) ?? 0;
    }
    
    // Get plan_id - this is required to link to parent plan
    int planId = 0;
    if (json['plan_id'] != null) {
      planId = (json['plan_id'] is int) ? json['plan_id'] as int : int.tryParse(json['plan_id'].toString()) ?? 0;
    } else if (json['subscription_plan_id'] != null) {
      planId = (json['subscription_plan_id'] is int) ? json['subscription_plan_id'] as int : int.tryParse(json['subscription_plan_id'].toString()) ?? 0;
    }
    
    // Get price - we'll need it for name construction
    double price = (json['price'] as num?)?.toDouble() ?? 0.0;
    String currency = json['currency']?.toString() ?? 'usd';
    String? duration = json['duration']?.toString();
    
    // Get name from multiple possible fields (name, title, plan_name, duration_name, duration)
    String name = json['name']?.toString() ?? 
                  json['title']?.toString() ?? 
                  json['plan_name']?.toString() ?? 
                  json['duration_name']?.toString() ??
                  duration ??
                  '';
    
    // If name is still empty, construct from available data
    if (name.isEmpty) {
      // Try to construct a meaningful name from price and duration
      if (duration != null && duration.isNotEmpty) {
        name = duration;
        if (price > 0) {
          String currencySymbol = currency.toUpperCase() == 'USD' ? '\$' : currency.toUpperCase();
          name = '$duration - $currencySymbol${price.toStringAsFixed(2)}';
        }
      } else if (price > 0) {
        // Just use price if no duration
        String currencySymbol = currency.toUpperCase() == 'USD' ? '\$' : currency.toUpperCase();
        name = '$currencySymbol${price.toStringAsFixed(2)}';
      } else {
        // Last resort - use a generic name with ID or index
        name = subPlanId > 0 ? 'Plan Option $subPlanId' : 'Plan Option';
      }
    }
    
    // If we still don't have a plan_id, generate one from the hash of constructed data
    if (planId == 0) {
      planId = name.hashCode.abs();
    }
    
    return SubPlan(
      id: subPlanId,
      planId: planId,
      name: name,
      description: json['description']?.toString(),
      price: price,
      currency: currency,
      duration: duration,
      stripePriceId: json['stripe_price_id']?.toString() ?? json['price_id']?.toString(),
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
/// FIXED: Updated fromJson to handle type casting safely (Task 5.1.1)
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
    // FIXED: Safe boolean parsing - handles bool, int (0/1), and string ('true'/'false')
    bool parseBoolean(dynamic value, {bool defaultValue = false}) {
      if (value == null) return defaultValue;
      if (value is bool) return value;
      if (value is int) return value == 1;
      if (value is String) return value.toLowerCase() == 'true' || value == '1';
      return defaultValue;
    }
    
    // FIXED: Safe int parsing - handles int and string
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      if (value is num) return value.toInt();
      return null;
    }
    
    // FIXED: Safe DateTime parsing - uses tryParse instead of parse to avoid throws
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value);
      return null;
    }
    
    return SubscriptionStatus(
      isActive: parseBoolean(json['is_active']),
      planName: json['plan_name']?.toString(),
      planId: parseInt(json['plan_id']),
      startDate: parseDateTime(json['start_date']),
      endDate: parseDateTime(json['end_date']),
      nextBillingDate: parseDateTime(json['next_billing_date']),
      status: json['status']?.toString(),
      stripeSubscriptionId: json['stripe_subscription_id']?.toString(),
      autoRenew: parseBoolean(json['auto_renew'], defaultValue: true),
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
