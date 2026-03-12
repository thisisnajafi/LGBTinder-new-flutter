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
  static const String verifyLoginCode = '/auth/verify-login-code';
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
  static const String authLinkedAccounts = '/auth/linked-accounts';
  static const String authGoogleUnlink = '/auth/google/unlink';

  // ==================== Landing (public, no auth) ====================
  static const String landingBlogs = '/landing/blogs';
  static const String landingSettings = '/landing/settings';
  static const String landingContact = '/landing/contact';
  static const String landingAppImages = '/landing/app-images';
  static const String landingStats = '/landing/stats';
  static const String landingTestimonials = '/landing/testimonials';

  // ==================== Locales (i18n) ====================
  static const String locales = '/locales';
  static const String localesTranslations = '/locales/translations';
  static const String localesCurrent = '/locales/current';

  // ==================== Reference Data ====================
  static const String countries = '/countries';
  static String countryById(int id) => '/countries/$id';
  static const String cities = '/cities';
  static String citiesByCountry(int countryId) => '/cities/country/$countryId';
  static String cityById(int id) => '/cities/$id';
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

  // OneSignal (push notification player & preferences)
  static const String onesignalUpdatePlayerId = '/onesignal/update-player-id';
  static const String onesignalRemovePlayerId = '/onesignal/remove-player-id';
  static const String onesignalNotificationInfo = '/onesignal/notification-info';
  static const String onesignalUpdatePreferences = '/onesignal/update-preferences';
  static const String onesignalResetPreferences = '/onesignal/reset-preferences';
  static const String onesignalDeliveryStatus = '/onesignal/delivery-status';

  // ==================== Profile Management ====================
  static const String profile = '/profile';
  static String profileById(int userId) => '/profile/$userId';
  static const String profileBadgeInfo = '/profile/badge/info';
  static const String profileUpdate = '/profile/update';
  static String profileByJob(int jobId) => '/profile/by-job/$jobId';
  static String profileByLanguage(int id) => '/profile/by-language/$id';
  static String profileByRelationGoal(int id) => '/profile/by-relation-goal/$id';
  static String profileByInterest(int id) => '/profile/by-interest/$id';
  static String profileByMusicGenre(int id) => '/profile/by-music-genre/$id';
  static String profileByEducation(int id) => '/profile/by-education/$id';
  static String profileByPreferredGender(int id) => '/profile/by-preferred-gender/$id';
  static String profileByGender(int id) => '/profile/by-gender/$id';
  static String profileMatchStatus(int userId) => '/profile/$userId/match-status';

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

  // ==================== Profile Wizard ====================
  static const String profileWizardCurrentStep = '/profile-wizard/current-step';
  static String profileWizardStepOptions(int stepId) => '/profile-wizard/step-options/$stepId';
  static String profileWizardSaveStep(int stepId) => '/profile-wizard/save-step/$stepId';

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
  static const String matchingLocationBased = '/matching/location-based';
  static const String matchingAiSuggestions = '/matching/ai-suggestions';
  static const String matchingDebug = '/matching/debug';

  // ==================== Likes & Superlikes ====================
  static const String likesLike = '/likes/like';
  static const String likesDislike = '/likes/dislike';
  static const String likesSuperlike = '/likes/superlike';
  static const String likesRespond = '/likes/respond';
  static const String likesMatches = '/likes/matches';
  static const String likesMatchesCount = '/likes/matches/count';
  static String likesMatchById(int id) => '/likes/matches/$id';
  static const String likesPending = '/likes/pending';
  static const String likesSuperlikeHistory = '/likes/superlike-history';
  static const String likesRewind = '/likes/rewind';
  // Matches namespace (alternative to likes/dislike, likes/superlike)
  static const String matchesDislike = '/matches/dislike';
  static const String matchesSuperlike = '/matches/superlike';

  // ==================== Chat & Messaging ====================
  static const String chatSend = '/chat/send';
  static const String chatHistory = '/chat/history';
  static const String chatUsers = '/chat/users';
  static const String chatAccessUsers = '/chat/access-users';
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
  static const String notificationsPermissions = '/notifications/permissions';
  static const String notificationPreferences = '/notification-preferences';
  static const String notificationsTest = '/notifications/test';
  static const String notificationsRegisterDevice = '/notifications/register-device';
  static const String notificationsUnregisterDevice = '/notifications/unregister-device';

  // ==================== Settings ====================
  /// GET /settings — full settings summary (account, profile, discovery, etc.)
  static const String settings = '/settings';
  static const String userSettings = '/user/settings';
  static const String privacySettings = '/privacy/settings';
  static const String preferencesMatching = '/preferences/matching';
  static const String preferencesAge = '/preferences/age';
  static const String deviceSessions = '/device-sessions';
  static String deviceSessionById(int id) => '/device-sessions/$id';
  static String deviceSessionTrust(int id) => '/device-sessions/$id/trust';
  static const String changePassword = '/auth/change-password';
  static const String changeEmail = '/profile/change-email';
  static const String accountChangeEmail = '/account/change-email';
  static const String accountChangePassword = '/account/change-password';
  static const String accountReactivate = '/account/reactivate';

  // Call management (voice/video)
  static const String callManagementInitiate = '/call-management/initiate';
  static String callManagementAccept(int callId) => '/call-management/$callId/accept';
  static String callManagementReject(int callId) => '/call-management/$callId/reject';
  static String callManagementEnd(int callId) => '/call-management/$callId/end';
  static const String callManagementHistory = '/call-management/history';
  static String callManagementHistoryDelete(int id) => '/call-management/history/$id';
  static const String callManagementStatistics = '/call-management/statistics';

  static const String verifyEmailChange = '/profile/verify-email-change';
  static const String deleteAccount = '/auth/delete-account';
  static const String subscriptionStatus = '/subscriptions/status';
  static const String subscriptionCancel = '/subscriptions/cancel';
  static const String subscriptionReactivate = '/subscriptions/reactivate';
  static const String userPaymentMethods = '/user/payment-methods';
  static const String userPaymentMethodsDefault = '/user/payment-methods/default';
  static const String userPaymentsHistory = '/user/payments/history';
  static const String userPaymentsSubscription = '/user/payments/subscription';
  static String userPaymentsReceipt(int id) => '/user/payments/receipt/$id';
  static const String userPaymentsFailed = '/user/payments/failed';
  static String userPaymentsRefund(int id) => '/user/payments/refund/$id';
  static const String paymentMethodsList = '/payment-methods';
  static String paymentMethodById(int id) => '/payment-methods/$id';
  static String paymentMethodsCurrency(String currency) => '/payment-methods/currency/$currency';
  static String paymentMethodsType(String type) => '/payment-methods/type/$type';
  static const String paymentMethodsValidateAmount = '/payment-methods/validate-amount';
  static const String emergencyTrigger = '/emergency/trigger';
  static const String safetyGuidelines = '/safety/guidelines';
  static const String safetyEmergencyAlert = '/safety/emergency-alert';
  static const String safetyShareLocation = '/safety/share-location';
  static const String safetyNearbySafePlaces = '/safety/nearby-safe-places';
  static const String safetyReport = '/safety/report';
  static const String safetyReportCategories = '/safety/report-categories';
  static const String safetyReportHistory = '/safety/report-history';
  static const String safetyModerateContent = '/safety/moderate-content';
  static const String safetyStatistics = '/safety/statistics';
  static const String reports = '/reports';
  static String reportById(int id) => '/reports/$id';
  static const String tickets = '/tickets';
  static String ticketById(int id) => '/tickets/$id';
  static const String twoFactorStatus = '/2fa/status';
  static const String twoFactorEnable = '/2fa/enable';
  static const String twoFactorVerify = '/2fa/verify';
  static const String twoFactorDisable = '/2fa/disable';
  static const String twoFactorQrCode = '/2fa/qr-code';
  static const String twoFactorBackupCodes = '/2fa/backup-codes';
  static const String userSessions = '/sessions';
  static const String sessionsStore = '/sessions/store';
  static const String sessionActivity = '/sessions/activity';
  static String sessionRevoke(int id) => '/sessions/revoke/$id';
  // API tokens (list, current, validate, revoke)
  static const String tokens = '/tokens';
  static const String tokensCurrent = '/tokens/current';
  static const String tokensValidate = '/tokens/validate';
  static String tokenById(int id) => '/tokens/$id';
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
  static const String analyticsEngagement = '/analytics/engagement';
  static const String analyticsRetention = '/analytics/retention';
  static const String analyticsInteractions = '/analytics/interactions';
  static const String analyticsProfileMetrics = '/analytics/profile-metrics';
  static const String analyticsTrackActivity = '/analytics/track-activity';

  // ==================== User Actions ====================
  static const String blockUser = '/block/user';
  static const String blockList = '/block/list';
  /// GET /block/check?user_id= — check if a user is blocked
  static const String blockCheck = '/block/check';
  static const String reportsHistory = '/reports/history';
  static const String mutesMute = '/mutes/mute';
  static const String mutesUnmute = '/mutes/unmute';
  static const String mutesList = '/mutes/list';
  static const String mutesSettings = '/mutes/settings';
  static const String mutesCheck = '/mutes/check';
  static const String favoritesAdd = '/favorites/add';
  static const String favoritesRemove = '/favorites/remove';
  static const String favoritesList = '/favorites/list';
  static const String favoritesCheck = '/favorites/check';
  static const String favoritesNote = '/favorites/note';
  static const String emergencyContactsBase = '/emergency-contacts';
  static const String emergencyContactsAdd = '/emergency-contacts/add';
  static const String emergencyContactsList = '/emergency-contacts/list';
  static String emergencyContactById(int id) => '/emergency-contacts/$id';
  static String emergencyContactVerify(int id) => '/emergency-contacts/$id/verify';
  static String emergencyContactConfirm(int id) => '/emergency-contacts/$id/confirm';
  static const String emergencyAlert = '/emergency/alert';

  // ==================== Payments & Subscriptions ====================
  // Stripe
  static String stripeSubscriptionById(String id) => '/stripe/subscription/$id';
  static const String stripeCheckout = '/stripe/checkout';
  static const String stripeVerifyPayment = '/stripe/verify-payment';
  static const String stripeCreatePaymentIntent = '/stripe/create-payment-intent';
  static const String stripeVerifyPaymentIntent = '/stripe/verify-payment-intent';
  static const String stripeCreateUpgradePaymentIntent = '/stripe/create-upgrade-payment-intent';
  static const String stripeVerifyUpgradePaymentIntent = '/stripe/verify-upgrade-payment-intent';
  static const String stripePaymentIntent = '/stripe/payment-intent';
  static const String stripeSubscription = '/stripe/subscription';
  static const String stripeRefund = '/stripe/refund';
  static const String stripeAnalytics = '/stripe/analytics';
  static const String subscriptionsStatus = '/subscriptions/status';
  static const String subscriptionsPlans = '/subscriptions/plans';
  static const String subscriptionsCreateCheckout = '/subscriptions/create-checkout';
  static const String subscriptionsCalculateUpgrade = '/subscriptions/calculate-upgrade';
  static const String subscriptionsUpgradeWithPenalty = '/subscriptions/upgrade-with-penalty';
  static const String subscriptionsUpdate = '/subscriptions/update';
  static String subscriptionsVerify(String sessionOrToken) => '/subscriptions/verify/$sessionOrToken';
  static const String subscriptionsSubscribe = '/subscriptions/subscribe';
  static const String subscriptionsUpgrade = '/subscriptions/upgrade';
  static const String plans = '/plans';
  static String planById(int id) => '/plans/$id';
  static String planSubPlans(int planId) => '/plans/$planId/sub-plans';
  static String planSubPlanById(int planId, int subPlanId) => '/plans/$planId/sub-plans/$subPlanId';
  static const String subPlans = '/sub-plans';
  static const String subPlansDuration = '/sub-plans/duration';
  static const String subPlansCompare = '/sub-plans/compare';
  static String subPlansByPlan(int planId) => '/sub-plans/plan/$planId';
  static const String subPlansUpgradeOptions = '/sub-plans/upgrade-options';
  static const String subPlansUpgrade = '/sub-plans/upgrade';
  static String subPlanById(int id) => '/sub-plans/$id';

  // Plan purchases (user's plan purchase records)
  static const String planPurchases = '/plan-purchases';
  static const String planPurchasesHistory = '/plan-purchases/history';
  static const String planPurchasesActive = '/plan-purchases/active';
  static const String planPurchasesExpired = '/plan-purchases/expired';
  static const String planPurchasesUpgradeOptions = '/plan-purchases/upgrade-options';
  static String planPurchaseById(int id) => '/plan-purchases/$id';

  // Plan purchase actions (transaction records)
  static const String planPurchaseActions = '/plan-purchase-actions';
  static const String planPurchaseActionsStatistics = '/plan-purchase-actions/statistics';
  static const String planPurchaseActionsToday = '/plan-purchase-actions/today';
  static const String planPurchaseActionsStatus = '/plan-purchase-actions/status';
  static String planPurchaseActionsUser(int userId) => '/plan-purchase-actions/user/$userId';
  static String planPurchaseActionById(int id) => '/plan-purchase-actions/$id';
  static String planPurchaseActionStatus(int id) => '/plan-purchase-actions/$id/status';

  // ==================== Plan Limits ====================
  static const String planLimits = '/plan-limits';
  static const String planLimitsCheck = '/plan-limits/check';

  // ==================== Superlikes ====================
  static const String superlikePacksAvailable = '/superlike-packs/available';
  static const String superlikePacksPurchase = '/superlike-packs/purchase';
  static const String superlikePacksStripeCheckout = '/superlike-packs/stripe-checkout';
  static const String superlikePacksCreatePaymentIntent = '/superlike-packs/create-payment-intent';
  static const String superlikePacksVerifyPaymentIntent = '/superlike-packs/verify-payment-intent';
  static const String superlikePacksStripeVerifyPayment = '/superlike-packs/stripe-verify-payment';
  static const String superlikePacksPaypalCheckout = '/superlike-packs/paypal-checkout';
  static const String superlikePacksUserPacks = '/superlike-packs/user-packs';
  static const String superlikePacksPurchaseHistory = '/superlike-packs/purchase-history';
  static const String superlikePacksActivatePending = '/superlike-packs/activate-pending';
  // PayPal (subscription/plan orders)
  static const String paypalCreateOrderPlan = '/paypal/create-order-plan';
  static const String paypalCaptureOrder = '/paypal/capture-order';
  static String paypalOrderById(String orderId) => '/paypal/order/$orderId';
  // ==================== Payments ====================
  static const String validateReceipt = '/payments/validate-receipt';
  static const String restorePurchases = '/payments/restore-purchases';
  static const String purchaseSuperlikePack = '/payments/purchase-superlike-pack';
  static const String paymentHistory = '/payments/history';

  // ==================== Google Play Billing ====================
  static const String googlePlayProducts = '/google-play/products';
  static const String googlePlayValidatePurchase = '/google-play/validate-purchase';
  static const String googlePlayValidateOneTimePurchase = '/google-play/validate-one-time-purchase';
  static const String googlePlayAcknowledgePurchase = '/google-play/acknowledge-purchase';
  static const String googlePlayConsumePurchase = '/google-play/consume-purchase';
  static const String googlePlaySubscriptionStatus = '/google-play/subscription/status';
  static const String googlePlayPurchasesHistory = '/google-play/purchases/history';
  static String googlePlayPurchaseDetails(int purchaseId) => '/google-play/purchases/$purchaseId';
  static const String googlePlaySubscriptionsActive = '/google-play/subscriptions/active';
  static const String googlePlaySubscriptionsHistory = '/google-play/subscriptions/history';
  static String googlePlaySubscriptionDetails(int subscriptionId) => '/google-play/subscriptions/$subscriptionId';
  static String googlePlayCancelSubscription(int subscriptionId) => '/google-play/subscriptions/$subscriptionId/cancel';
  static const String googlePlaySubscriptionCancel = '/google-play/subscription/cancel';
  static const String googlePlayAnalyticsPurchases = '/google-play/analytics/purchases';
  static const String googlePlayAnalyticsSubscriptions = '/google-play/analytics/subscriptions';
  static const String googlePlayAnalyticsWebhooks = '/google-play/analytics/webhooks';
  static const String googlePlayAnalyticsErrors = '/google-play/analytics/errors';

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

  // ==================== Referrals ====================
  static const String referralsStats = '/referrals/stats';
  static const String referralsCode = '/referrals/code';
  static const String referralsHistory = '/referrals/history';
  static const String referralsTiers = '/referrals/tiers';
  static const String referralsValidateCode = '/referrals/validate-code';
  static const String referralsProcessMilestone = '/referrals/process-milestone';
  static const String referralsMarkCompleted = '/referrals/mark-completed';

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
