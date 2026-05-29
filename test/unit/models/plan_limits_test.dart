import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/features/payments/data/models/plan_limits.dart';

const _innerPayload = {
  'plan_info': {
    'is_premium': false,
    'plan_name': 'Free',
    'plan_id': null,
    'expires_at': null,
  },
  'limits': {
    'swipes': {'daily_limit': 10, 'is_unlimited': false},
    'likes': {'daily_limit': 8, 'is_unlimited': false},
    'superlikes': {'daily_limit': 1, 'is_unlimited': false},
    'messages': {'max_conversations': 5, 'is_unlimited': false},
  },
  'usage': {
    'swipes': {
      'used_today': 0,
      'limit': 10,
      'remaining': 10,
      'is_unlimited': false,
    },
    'likes': {
      'used_today': 0,
      'limit': 8,
      'remaining': 8,
      'is_unlimited': false,
    },
    'superlikes': {
      'used_today': 0,
      'limit': 1,
      'remaining': 1,
      'is_unlimited': false,
    },
    'messages': {
      'sent_today': 0,
      'active_conversations': 0,
      'conversation_limit': 5,
      'is_unlimited': false,
    },
  },
  'features': {
    'advanced_filters': false,
    'see_who_liked_me': false,
    'rewind': false,
    'passport': false,
    'boost': false,
    'read_receipts': false,
    'video_calls': false,
    'incognito_mode': false,
    'ad_free': false,
    'priority_likes': false,
    'ai_matching': false,
  },
  'timestamps': {
    'resets_at': '2026-05-28T00:00:00.000Z',
    'checked_at': '2026-05-27T16:00:00.000Z',
  },
  'superlike_info': {
    'can_superlike': true,
    'total_remaining': 2,
    'daily_remaining': 1,
    'extra_packs_remaining': 1,
    'daily_limit': 1,
    'daily_used': 0,
  },
};

void main() {
  group('PlanLimits.tryParse', () {
    test('parses wrapped API envelope', () {
      final limits = PlanLimits.tryParse({'data': _innerPayload});
      expect(limits, isNotNull);
      expect(limits!.effectiveSuperlikeInfo.totalRemaining, 2);
    });

    test('parses inner payload from HTTP cache', () {
      final limits = PlanLimits.tryParse(_innerPayload);
      expect(limits, isNotNull);
      expect(limits!.effectiveSuperlikeInfo.canSuperlike, isTrue);
    });

    test('returns null for invalid payload', () {
      expect(PlanLimits.tryParse({'foo': 'bar'}), isNull);
      expect(PlanLimits.tryParse(null), isNull);
    });

    test('corrects golden tier swipe cap when API sends daily_profile=1', () {
      final payload = Map<String, dynamic>.from(_innerPayload);
      payload['plan_info'] = {
        'is_premium': true,
        'plan_name': 'Golden',
        'plan_id': 3,
        'tier': 'golden',
        'expires_at': null,
      };
      payload['usage'] = Map<String, dynamic>.from(payload['usage'] as Map);
      (payload['usage'] as Map)['swipes'] = {
        'used_today': 2,
        'limit': 1,
        'remaining': 0,
        'is_unlimited': false,
      };
      (payload['limits'] as Map)['swipes'] = {
        'daily_limit': 1,
        'is_unlimited': false,
      };

      final limits = PlanLimits.tryParse({'data': payload});
      expect(limits, isNotNull);
      expect(limits!.usage.swipes.isUnlimited, isTrue);
      expect(limits.usage.swipes.limit, 9999);
      expect(limits.hasReachedLimit('swipes'), isFalse);
    });
  });
}
