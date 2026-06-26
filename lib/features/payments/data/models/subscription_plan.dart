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
  final List<SubPlan> subPlans;

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
    this.subPlans = const [],
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    int planId = 0;
    if (json['id'] != null) {
      planId = (json['id'] is int)
          ? json['id'] as int
          : int.tryParse(json['id'].toString()) ?? 0;
    } else if (json['plan_id'] != null) {
      planId = (json['plan_id'] is int)
          ? json['plan_id'] as int
          : int.tryParse(json['plan_id'].toString()) ?? 0;
    }

    double price = (json['price'] as num?)?.toDouble() ?? 0.0;
    String? duration = json['duration']?.toString();

    String name = json['name']?.toString() ??
        json['title']?.toString() ??
        json['plan_name']?.toString() ??
        json['plan_title']?.toString() ??
        '';

    if (name.isEmpty) {
      if (duration != null && duration.isNotEmpty) {
        name = duration.toUpperCase();
      } else if (price > 0) {
        String currencySymbol =
            (json['currency']?.toString() ?? 'usd').toUpperCase() == 'USD'
                ? '\$'
                : (json['currency']?.toString() ?? 'usd').toUpperCase();
        name = '$currencySymbol${price.toStringAsFixed(2)} Plan';
      } else {
        name = planId > 0 ? 'Plan $planId' : 'Subscription Plan';
      }
    }

    List<SubPlan>? parsedSubPlans;
    final rawSubPlans = json['sub_plans'];
    if (rawSubPlans is List) {
      parsedSubPlans = rawSubPlans
          .whereType<Map<String, dynamic>>()
          .map(
            (item) => SubPlan.fromJson(<String, dynamic>{
              ...item,
              'plan_id': planId,
            }),
          )
          .toList()
        ..sort(
          (a, b) => (a.durationDays ?? 0).compareTo(b.durationDays ?? 0),
        );
    }

    if (parsedSubPlans != null && parsedSubPlans.isNotEmpty && price <= 0) {
      price = parsedSubPlans.first.price;
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
      stripePriceId:
          json['stripe_price_id']?.toString() ?? json['price_id']?.toString(),
      subPlans: parsedSubPlans ?? const [],
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
      if (subPlans.isNotEmpty)
        'sub_plans': subPlans.map((e) => e.toJson()).toList(),
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
  final int? durationDays;
  final String? durationText;
  final String? stripePriceId;
  final String? googleOfferId;

  SubPlan({
    this.id = 0,
    required this.planId,
    required this.name,
    this.description,
    required this.price,
    this.currency = 'usd',
    this.duration,
    this.durationDays,
    this.durationText,
    this.stripePriceId,
    this.googleOfferId,
  });

  String get durationLabel {
    if (durationText != null && durationText!.isNotEmpty) return durationText!;
    if (durationDays != null) {
      switch (durationDays) {
        case 30:
          return '1 Month';
        case 90:
          return '3 Months';
        case 180:
          return '6 Months';
        case 365:
          return '1 Year';
        default:
          return '$durationDays days';
      }
    }
    return _durationLabelFromString(duration);
  }

  double get perMonthPrice {
    final months = monthsCount;
    if (months <= 0) return price;
    return price / months;
  }

  int get monthsCount {
    if (durationDays != null) {
      if (durationDays == 30) return 1;
      if (durationDays == 90) return 3;
      if (durationDays == 180) return 6;
      if (durationDays == 365) return 12;
      return (durationDays! / 30).round().clamp(1, 12);
    }
    final d = duration?.toLowerCase() ?? '';
    if (d.contains('year') || d.contains('annual') || d.contains('12')) return 12;
    if (d.contains('6')) return 6;
    if (d.contains('3') || d.contains('quarter')) return 3;
    return 1;
  }

  static String _durationLabelFromString(String? duration) {
    if (duration == null || duration.isEmpty) return '1 Month';
    final d = duration.toLowerCase();
    if (d.contains('year') || d.contains('annual') || d.contains('12')) {
      return '1 Year';
    }
    if (d.contains('6')) return '6 Months';
    if (d.contains('3') || d.contains('quarter')) return '3 Months';
    return '1 Month';
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  factory SubPlan.fromJson(Map<String, dynamic> json) {
    int subPlanId = 0;
    if (json['id'] != null) {
      subPlanId = _parseInt(json['id']) ?? 0;
    } else if (json['sub_plan_id'] != null) {
      subPlanId = _parseInt(json['sub_plan_id']) ?? 0;
    }

    int planId = 0;
    if (json['plan_id'] != null) {
      planId = _parseInt(json['plan_id']) ?? 0;
    } else if (json['subscription_plan_id'] != null) {
      planId = _parseInt(json['subscription_plan_id']) ?? 0;
    }

    final price = _parseDouble(json['price']) ?? 0.0;
    final currency = json['currency']?.toString() ?? 'usd';
    final durationDays = _parseInt(json['duration_days']);
    final durationText = json['duration_text']?.toString();
    final duration = json['duration']?.toString() ?? durationText;

    String name = json['name']?.toString() ??
        json['title']?.toString() ??
        json['sub_plan_title']?.toString() ??
        json['plan_name']?.toString() ??
        durationText ??
        duration ??
        '';

    if (name.isEmpty) {
      if (durationText != null && durationText.isNotEmpty) {
        name = durationText;
      } else if (price > 0) {
        final symbol =
            currency.toUpperCase() == 'USD' ? '\$' : currency.toUpperCase();
        name = '$symbol${price.toStringAsFixed(2)}';
      } else {
        name = subPlanId > 0 ? 'Plan Option $subPlanId' : 'Plan Option';
      }
    }

    if (planId == 0) {
      planId = name.hashCode.abs();
    }

    return SubPlan(
      id: subPlanId,
      planId: planId,
      name: name,
      description: json['description']?.toString() ??
          json['sub_plan_description']?.toString(),
      price: price,
      currency: currency,
      duration: duration,
      durationDays: durationDays,
      durationText: durationText,
      stripePriceId:
          json['stripe_price_id']?.toString() ?? json['price_id']?.toString(),
      googleOfferId: json['google_offer_id']?.toString(),
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
      if (durationDays != null) 'duration_days': durationDays,
      if (durationText != null) 'duration_text': durationText,
      if (stripePriceId != null) 'stripe_price_id': stripePriceId,
      if (googleOfferId != null) 'google_offer_id': googleOfferId,
    };
  }
}

/// Subscription status model
/// FIXED: Updated fromJson to handle type casting safely (Task 5.1.1)
class SubscriptionStatus {
  final bool isActive;
  final String? planName;
  final int? planId;
  final String? tier;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? nextBillingDate;
  final String? status; // 'active', 'canceled', 'expired', 'trial'
  final String? stripeSubscriptionId;
  final bool autoRenew;
  final bool cancelAtPeriodEnd;
  final String? provider;

  SubscriptionStatus({
    this.isActive = false,
    this.planName,
    this.planId,
    this.tier,
    this.startDate,
    this.endDate,
    this.nextBillingDate,
    this.status,
    this.stripeSubscriptionId,
    this.autoRenew = true,
    this.cancelAtPeriodEnd = false,
    this.provider,
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
      tier: json['tier']?.toString(),
      startDate: parseDateTime(json['start_date']),
      endDate: parseDateTime(json['end_date'] ??
          json['ends_at'] ??
          json['expiry_date'] ??
          json['current_period_end']),
      nextBillingDate: parseDateTime(
          json['next_billing_date'] ?? json['current_period_end']),
      status: json['status']?.toString() ?? json['subscription_status']?.toString(),
      stripeSubscriptionId: json['stripe_subscription_id']?.toString(),
      autoRenew: parseBoolean(json['auto_renew'] ?? json['will_auto_renew'], defaultValue: true),
      cancelAtPeriodEnd: parseBoolean(json['cancel_at_period_end']),
      provider: json['provider']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'is_active': isActive,
      if (planName != null) 'plan_name': planName,
      if (planId != null) 'plan_id': planId,
      if (tier != null) 'tier': tier,
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
