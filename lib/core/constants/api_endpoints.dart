/// API endpoint URLs organized by feature
class ApiEndpoints {
  // API origin (host only, no path) — use for WebSocket and baseUrl
  static const String apiOrigin = 'https://api.lgbtfinder.com';
  // Base URL (production API) — must include /api to match Laravel apiPrefix
  static const String baseUrl = '$apiOrigin/api';
  // Storage URL for media files (same host as API)
  static const String storageUrl = '$apiOrigin/storage';

  // ==================== Authentication ====================
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String loginPassword = '/auth/login-password';
  /// Lightweight token validation for splash (GET, Bearer token). 200 = valid, 401 = invalid.
  static const String checkToken = '/auth/check-token';
  static const String checkUserState = '/auth/check-user-state';
  static const String sendVerification = '/auth/send-verification';
  static const String resendVerification = '/auth/resend-verification';
  static const String resendVerificationExisting = '/auth/resend-verification-existing';
  static const String authRefresh = '/auth/refresh';
  static const String completeRegistration = '/complete-registration';

  // OTP and Password Reset
  static const String sendOtp = '/auth/send-otp';
  static const String verifyOtp = '/auth/verify-otp';
  static const String resetPassword = '/auth/reset-password';

  // Social Authentication
  // FIXED: Updated to match backend routes (api.php lines 103-104)
  static const String googleAuthUrl = '/auth/google/url';
  static const String googleCallback = '/auth/google/callback';

  // ==================== Reference Data ====================
  static const String countries = '/countries';
  static String citiesByCountry(int countryId) => '/cities/country/$countryId';
  static const String genders = '/genders';
  static const String jobs = '/jobs';
  static const String education = '/education';
  static const String interests = '/interests';
  static const String languages = '/languages';
  static const String musicGenres = '/music-genres';
  static const String relationGoals = '/relation-goals';
  static const String preferredGenders = '/preferred-genders';

  // ==================== User Management ====================
  static const String user = '/user';
  static const String userShowAdultContent = '/user/show-adult-content';
  static const String userOnesignalPlayer = '/user/onesignal-player';
  static const String userNotificationPreferences = '/user/notification-preferences';
  static const String userNotificationHistory = '/user/notification-history';

  // ==================== Profile Management ====================
  static const String profile = '/profile';
  static String profileById(int userId) => '/profile/$userId';
  static const String profileBadgeInfo = '/profile/badge/info';
  static const String profileUpdate = '/profile/update';
  static String profileByJob(int jobId) => '/profile/by-job/$jobId';

  // ==================== Profile Verification ====================
  // FIXED: Updated to match backend routes (api.php lines 614-623)
  static const String profileVerificationStatus = '/verification/status';
  static const String profileVerificationPhoto = '/verification/submit-photo';
  static const String profileVerificationId = '/verification/submit-id';
  static const String profileVerificationVideo = '/verification/submit-video';
  static const String profileVerificationHistory = '/verification/history';
  static String profileVerificationCancel(int verificationId) => '/verification/cancel/$verificationId';
  static const String profileVerificationGuidelines = '/verification/guidelines';

  // ==================== Profile Completion ====================
  static const String profileCompletionStatus = '/profile/completion-status';

  // ==================== Image Management ====================
  static const String imagesUpload = '/images/upload';
  static String imagesById(int id) => '/images/$id';
  static const String imagesReorder = '/images/reorder';
  static String imagesSetPrimary(int id) => '/images/$id/set-primary';
  static const String imagesList = '/images/list';
  
  // ==================== Profile Picture Management ====================
  static const String profilePicturesUpload = '/profile-pictures/upload';
  static String profilePicturesById(int id) => '/profile-pictures/$id';
  static String profilePicturesSetPrimary(int id) => '/profile-pictures/$id/set-primary';
  static const String profilePicturesList = '/profile-pictures/list';

  // ==================== Matching & Discovery ====================
  static const String matchingMatches = '/matching/matches';
  static const String matchingNearbySuggestions = '/matching/nearby-suggestions';
  static const String matchingAdvanced = '/matching/advanced';
  static const String matchingCompatibilityScore = '/matching/compatibility-score';
  static const String matchingAiSuggestions = '/matching/ai-suggestions';
  static const String matchingDebug = '/matching/debug';

  // ==================== Likes & Superlikes ====================
  static const String likesLike = '/likes/like';
  static const String likesDislike = '/likes/dislike';
  static const String likesSuperlike = '/likes/superlike';
  static const String likesRespond = '/likes/respond';
  static const String likesMatches = '/likes/matches';
  static const String likesPending = '/likes/pending';
  static const String likesSuperlikeHistory = '/likes/superlike-history';
  static const String likesRewind = '/likes/rewind';

  // ==================== Chat & Messaging ====================
  static const String chatSend = '/chat/send';
  static const String chatHistory = '/chat/history';
  static const String chatUsers = '/chat/users';
  static const String chatMessage = '/chat/message';
  static const String chatTyping = '/chat/typing';
  static const String chatRead = '/chat/read';
  static const String chatUnreadCount = '/chat/unread-count';
  // NOTE (Task 2.3.2): Backend handles media uploads directly in sendMessage via 'media' field.
  // Use multipart/form-data request with 'media' file when sending images/videos.
  // This endpoint is kept for potential future separate upload functionality.
  @Deprecated('Media uploads are handled in chatSend endpoint. Use multipart/form-data.')
  static const String chatAttachmentUpload = '/chat/attachment/upload';
  // FIXED: Updated to match backend route (api.php line 437)
  static const String chatOnlineStatus = '/chat/online';
  static const String chatPinnedCount = '/chat/pinned-count';
  static const String chatPinMessage = '/chat/pin-message';
  static const String chatUnpinMessage = '/chat/unpin-message';
  static const String chatPinnedMessages = '/chat/pinned-messages';
  static const String chatSearch = '/chat/search';

  // ==================== Notifications ====================
  static const String notifications = '/notifications';
  static const String notificationsUnreadCount = '/notifications/unread-count';
  static String notificationsRead(int id) => '/notifications/$id/read';
  static const String notificationsReadAll = '/notifications/read-all';
  static String notificationsById(int id) => '/notifications/$id';
  static const String notificationPreferences = '/notification-preferences';
  static const String notificationsTest = '/notifications/test';
  static const String notificationsRegisterDevice = '/notifications/register-device';
  static const String notificationsUnregisterDevice = '/notifications/unregister-device';

  // ==================== Settings ====================
  static const String userSettings = '/user/settings';
  static const String privacySettings = '/privacy/settings';
  static const String preferencesMatching = '/preferences/matching';
  static const String deviceSessions = '/device-sessions';
  static String deviceSessionById(int id) => '/device-sessions/$id';
  static String deviceSessionTrust(int id) => '/device-sessions/$id/trust';
  static const String changePassword = '/auth/change-password';
  static const String changeEmail = '/profile/change-email';
  static const String verifyEmailChange = '/profile/verify-email-change';
  static const String deleteAccount = '/auth/delete-account';
  static const String subscriptionStatus = '/subscriptions/status';
  static const String subscriptionCancel = '/subscriptions/cancel';
  static const String subscriptionReactivate = '/subscriptions/reactivate';
  static const String userPaymentMethods = '/user/payment-methods';
  static const String paymentMethodsList = '/payment-methods';
  static const String emergencyTrigger = '/emergency/trigger';
  static const String reports = '/reports';
  static const String twoFactorStatus = '/2fa/status';
  static const String twoFactorEnable = '/2fa/enable';
  static const String twoFactorVerify = '/2fa/verify';
  static const String twoFactorDisable = '/2fa/disable';
  static const String twoFactorQrCode = '/2fa/qr-code';
  static const String twoFactorBackupCodes = '/2fa/backup-codes';
  static const String userSessions = '/sessions';
  static const String sessionActivity = '/sessions/activity';
  static const String userSearch = '/profile/search';
  static const String emergencyContacts = '/safety/emergency-contacts';
  static const String exportData = '/user/export-data';
  static const String clearCache = '/user/clear-cache';
  static const String resetSettings = '/user/reset-settings';

  // ==================== Admin ====================
  static const String adminUsers = '/admin/users';
  static String adminUserById(int id) => '/admin/users/$id';
  static const String adminAnalytics = '/admin/analytics';
  static const String adminAnalyticsExport = '/admin/analytics/export';
  static const String adminSystemHealth = '/admin/system/health';
  static const String adminSystemCacheClear = '/admin/system/cache/clear';
  static const String adminSystemNotification = '/admin/system/notification';
  static const String adminAppConfiguration = '/admin/app/configuration';

  // ==================== Calls ====================
  // FIXED: Updated to match backend routes (api.php lines 454-466)
  // Backend uses POST body for call_id, not URL path parameters
  static const String calls = '/calls';
  static const String callsInitiate = '/calls/initiate';
  static const String callsAccept = '/calls/accept';  // Send call_id in body
  static const String callsDecline = '/calls/reject'; // Backend uses 'reject' not 'decline'
  static const String callsEnd = '/calls/end';        // Send call_id in body
  static const String callsHistory = '/calls/history';
  static const String callsActive = '/calls/active';
  static String callsById(String callId) => '/calls/$callId';
  static const String callsSettings = '/calls/settings';
  static const String callsStatistics = '/calls/statistics';
  static String callsEligibility(int userId) => '/calls/eligibility/$userId';
  static const String callsReportIssue = '/calls/report-issue';
  static const String callsParticipants = '/calls/participants';

  // ==================== Onboarding ====================
  static const String onboardingPreferences = '/onboarding/preferences';
  static const String onboardingComplete = '/onboarding/complete';
  static const String onboardingSkip = '/onboarding/skip';
  static const String onboardingProgress = '/onboarding/progress';
  static const String onboardingStep = '/onboarding/step';
  static const String onboardingReset = '/onboarding/reset';
  static const String onboardingStatus = '/onboarding/status';

  // ==================== Video/Voice Calls ====================
  static const String callsReject = '/calls/reject';
  static String callsSettingsUpdate = '/calls/settings';
  static const String callsQuota = '/calls/quota';

  // ==================== Analytics ====================
  static const String analyticsMyAnalytics = '/analytics/my-analytics';
  static const String analyticsTrackActivity = '/analytics/track-activity';

  // ==================== User Actions ====================
  static const String blockUser = '/block/user';
  static const String blockList = '/block/list';
  static const String reportsHistory = '/reports/history';
  static const String mutesMute = '/mutes/mute';
  static const String favoritesAdd = '/favorites/add';
  static const String favoritesRemove = '/favorites/remove';
  static const String favoritesList = '/favorites/list';
  static const String emergencyContactsAdd = '/emergency-contacts/add';
  static const String emergencyContactsList = '/emergency-contacts/list';
  static String emergencyContactById(int id) => '/emergency-contacts/$id';
  static const String emergencyAlert = '/emergency/alert';

  // ==================== Payments & Subscriptions ====================
  // Stripe checkout/payment-intent removed; cancel-by-id kept for backend compatibility
  static String stripeSubscriptionById(String id) => '/stripe/subscription/$id';
  static const String subscriptionsStatus = '/subscriptions/status';
  static const String subscriptionsSubscribe = '/subscriptions/subscribe';
  static const String subscriptionsUpgrade = '/subscriptions/upgrade';
  static const String plans = '/plans';
  static const String subPlans = '/sub-plans';

  // ==================== Superlikes ====================
  static const String superlikePacksAvailable = '/superlike-packs/available';
  static const String superlikePacksPurchase = '/superlike-packs/purchase';
  static const String superlikePacksUserPacks = '/superlike-packs/user-packs';
  // ==================== Payments ====================
  static const String validateReceipt = '/payments/validate-receipt';
  static const String restorePurchases = '/payments/restore-purchases';
  static const String purchaseSuperlikePack = '/payments/purchase-superlike-pack';
  static const String paymentHistory = '/payments/history';

  // ==================== Google Play Billing ====================
  static const String googlePlayValidatePurchase = '/google-play/validate-purchase';
  static const String googlePlaySubscriptionStatus = '/google-play/subscription/status';
  static const String googlePlayPurchasesHistory = '/google-play/purchases/history';
  static String googlePlayPurchaseDetails(int purchaseId) => '/google-play/purchases/$purchaseId';
  static const String googlePlaySubscriptionsActive = '/google-play/subscriptions/active';
  static const String googlePlaySubscriptionsHistory = '/google-play/subscriptions/history';
  static String googlePlaySubscriptionDetails(int subscriptionId) => '/google-play/subscriptions/$subscriptionId';
  static String googlePlayCancelSubscription(int subscriptionId) => '/google-play/subscriptions/$subscriptionId/cancel';

  // ==================== Community Forums ====================
  static const String communityForums = '/community-forums';
  static const String forumCategories = '/community-forums/categories';
  static String forumPost(int postId) => '/community-forums/$postId';
  static String forumPostLike(int postId) => '/community-forums/$postId/like';
  static String forumPostComments(int postId) => '/community-forums/$postId/comments';

  // ==================== Marketing System ====================
  static const String marketingPromotions = '/marketing/promotions';
  static const String marketingValidatePromo = '/marketing/validate-promo';
  static const String marketingApplyPromotion = '/marketing/apply-promotion';
  static const String marketingPricing = '/marketing/pricing';
  static String marketingProductPrice(String productId) => '/marketing/price/$productId';
  static const String marketingPromoCodes = '/marketing/promo-codes';
  static const String marketingTrackImpression = '/marketing/track-impression';
  static const String marketingTrackClick = '/marketing/track-click';

  // ==================== Daily Rewards ====================
  static const String dailyRewardsStatus = '/daily-rewards/status';
  static const String dailyRewardsClaim = '/daily-rewards/claim';
  static const String dailyRewardsConfig = '/daily-rewards/config';
  static const String dailyRewardsHistory = '/daily-rewards/history';
  static const String dailyRewardsLeaderboard = '/daily-rewards/leaderboard';

  // ==================== Banners ====================
  static String bannersByPosition(String position) => '/banners/position/$position';
  static const String bannersAll = '/banners/all';
  static const String bannersTrackImpression = '/banners/track-impression';
  static const String bannersTrackClick = '/banners/track-click';
  static const String bannersTrackDismissal = '/banners/track-dismissal';
  static const String bannersTrackConversion = '/banners/track-conversion';

    // ==================== A/B Testing ====================
    static String abTestVariation(String featureKey) => '/ab-test/variation/$featureKey';
    static const String abTestTrack = '/ab-test/track';
    static const String abTestPricingPage = '/ab-test/pricing-page';
    static String abTestBanner(String position) => '/ab-test/banner/$position';

    // ==================== Badges & Gamification ====================
  static const String badgesAll = '/badges/all';
  static const String badgesMy = '/badges/my';
  static const String badgesDisplayed = '/badges/displayed';
  static const String badgesEligibility = '/badges/eligibility';
  static const String badgesClaim = '/badges/claim';
  static const String badgesClaimReward = '/badges/claim-reward';
  static const String badgesToggleDisplay = '/badges/toggle-display';
  static const String badgesLeaderboard = '/badges/leaderboard';
  static String badgesUser(int userId) => '/badges/user/$userId';
}
