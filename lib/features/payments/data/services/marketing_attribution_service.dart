import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to store and retrieve marketing attribution data
/// Captures UTM parameters from deep links and stores them for purchase attribution
class MarketingAttributionService {
  static const String _prefsKey = 'marketing_attribution';
  static const String _prefsKeyUtmSource = 'utm_source';
  static const String _prefsKeyUtmMedium = 'utm_medium';
  static const String _prefsKeyUtmCampaign = 'utm_campaign';
  static const String _prefsKeyUtmTerm = 'utm_term';
  static const String _prefsKeyUtmContent = 'utm_content';
  static const String _prefsKeyMarketingSource = 'marketing_source';
  static const String _prefsKeyCampaignId = 'campaign_id';
  static const String _prefsKeyReferralCode = 'referral_code';

  SharedPreferences? _prefs;

  /// Initialize the service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Store UTM parameters from deep link
  Future<void> storeUtmParameters(Map<String, String> queryParams) async {
    if (_prefs == null) await initialize();

    if (queryParams.containsKey('utm_source')) {
      await _prefs!.setString(_prefsKeyUtmSource, queryParams['utm_source']!);
    }
    if (queryParams.containsKey('utm_medium')) {
      await _prefs!.setString(_prefsKeyUtmMedium, queryParams['utm_medium']!);
    }
    if (queryParams.containsKey('utm_campaign')) {
      await _prefs!.setString(_prefsKeyUtmCampaign, queryParams['utm_campaign']!);
    }
    if (queryParams.containsKey('utm_term')) {
      await _prefs!.setString(_prefsKeyUtmTerm, queryParams['utm_term']!);
    }
    if (queryParams.containsKey('utm_content')) {
      await _prefs!.setString(_prefsKeyUtmContent, queryParams['utm_content']!);
    }
    if (queryParams.containsKey('campaign_id')) {
      await _prefs!.setString(_prefsKeyCampaignId, queryParams['campaign_id']!);
    }
    if (queryParams.containsKey('referral_code')) {
      await _prefs!.setString(_prefsKeyReferralCode, queryParams['referral_code']!);
    }
    if (queryParams.containsKey('marketing_source')) {
      await _prefs!.setString(_prefsKeyMarketingSource, queryParams['marketing_source']!);
    }

    debugPrint('Stored marketing attribution: ${queryParams.keys.join(", ")}');
  }

  /// Get current marketing attribution data
  Future<Map<String, String?>> getAttributionData() async {
    if (_prefs == null) await initialize();

    return {
      'utm_source': _prefs!.getString(_prefsKeyUtmSource),
      'utm_medium': _prefs!.getString(_prefsKeyUtmMedium),
      'utm_campaign': _prefs!.getString(_prefsKeyUtmCampaign),
      'utm_term': _prefs!.getString(_prefsKeyUtmTerm),
      'utm_content': _prefs!.getString(_prefsKeyUtmContent),
      'marketing_source': _prefs!.getString(_prefsKeyMarketingSource),
      'campaign_id': _prefs!.getString(_prefsKeyCampaignId),
      'referral_code': _prefs!.getString(_prefsKeyReferralCode),
    };
  }

  /// Clear marketing attribution data (after purchase or after expiration)
  Future<void> clearAttribution() async {
    if (_prefs == null) await initialize();

    await _prefs!.remove(_prefsKeyUtmSource);
    await _prefs!.remove(_prefsKeyUtmMedium);
    await _prefs!.remove(_prefsKeyUtmCampaign);
    await _prefs!.remove(_prefsKeyUtmTerm);
    await _prefs!.remove(_prefsKeyUtmContent);
    await _prefs!.remove(_prefsKeyMarketingSource);
    await _prefs!.remove(_prefsKeyCampaignId);
    await _prefs!.remove(_prefsKeyReferralCode);

    debugPrint('Cleared marketing attribution data');
  }

  /// Check if there's any attribution data
  Future<bool> hasAttribution() async {
    if (_prefs == null) await initialize();

    return _prefs!.getString(_prefsKeyUtmSource) != null ||
        _prefs!.getString(_prefsKeyUtmCampaign) != null ||
        _prefs!.getString(_prefsKeyCampaignId) != null ||
        _prefs!.getString(_prefsKeyReferralCode) != null;
  }
}
