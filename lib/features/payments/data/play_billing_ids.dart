/// Google Play subscription IDs.
///
/// Product IDs use underscores (`gold_monthly`). Base plan IDs use hyphens
/// (`gold-monthly`). Older ids such as `bronze-base`, `silver_base`, and
/// `gold_base` still resolve to the monthly product and base plan.
class PlayBillingIds {
  PlayBillingIds._();

  static const legacyProducts = <String, String>{
    'bronze-base': 'bronze_monthly',
    'bronze_base': 'bronze_monthly',
    'silver-base': 'silver_monthly',
    'silver_base': 'silver_monthly',
    'gold-base': 'gold_monthly',
    'gold_base': 'gold_monthly',
  };

  static const legacyBasePlans = <String, String>{
    'bronze-base': 'bronze-monthly',
    'bronze_base': 'bronze-monthly',
    'silver-base': 'silver-monthly',
    'silver_base': 'silver-monthly',
    'gold-base': 'gold-monthly',
    'gold_base': 'gold-monthly',
  };

  static const canonicalProducts = <String>[
    'bronze_monthly',
    'bronze_quarterly',
    'bronze_annual',
    'silver_monthly',
    'silver_quarterly',
    'silver_annual',
    'gold_monthly',
    'gold_quarterly',
    'gold_annual',
  ];

  static const canonicalBasePlans = <String>[
    'bronze-monthly',
    'bronze-quarterly',
    'bronze-annual',
    'silver-monthly',
    'silver-quarterly',
    'silver-annual',
    'gold-monthly',
    'gold-quarterly',
    'gold-annual',
  ];

  static String canonicalProductId(String productId) {
    final key = productId.trim().toLowerCase();
    if (key.isEmpty) return key;
    final legacy = legacyProducts[key];
    if (legacy != null) return legacy;
    return _swapSeparator(key, from: '-', to: '_') ?? key;
  }

  static String canonicalBasePlanId(String basePlanId) {
    final key = basePlanId.trim().toLowerCase();
    if (key.isEmpty) return key;
    final legacy = legacyBasePlans[key];
    if (legacy != null) return legacy;
    return _swapSeparator(key, from: '_', to: '-') ?? key;
  }

  /// Product ids to ask Play for. Includes the raw id and the canonical one.
  static Set<String> productQueryIds(String productId) {
    final raw = productId.trim();
    if (raw.isEmpty) return const {};
    return {raw, canonicalProductId(raw)};
  }

  static bool sameBasePlan(String left, String right) {
    if (left == right) return true;
    final a = canonicalBasePlanId(left);
    final b = canonicalBasePlanId(right);
    return a.isNotEmpty && a == b;
  }

  static String? _swapSeparator(
    String key, {
    required String from,
    required String to,
  }) {
    final match = RegExp('^(bronze|silver|gold)\\$from(monthly|quarterly|annual|yearly)\$')
        .firstMatch(key);
    if (match == null) return null;
    final cycle = match.group(2) == 'yearly' ? 'annual' : match.group(2);
    return '${match.group(1)}$to$cycle';
  }
}
