/// API endpoint URLs organized by feature
class ApiEndpoints {
  // Base URL
  static const String baseUrl = 'http://lg.abolfazlnajafi.com/api';

  // ==================== Authentication ====================
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String loginPassword = '/auth/login-password';
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
  static const String googleAuthUrl = '/social/google/auth-url';
  static const String googleCallback = '/social/google/callback';

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
  static const String profileVerificationStatus = '/profile-verification/status';
  static const String profileVerificationPhoto = '/profile-verification/photo';
  static const String profileVerificationId = '/profile-verification/id';
  static const String profileVerificationVideo = '/profile-verification/video';
  static const String profileVerificationHistory = '/profile-verification/history';
  static String profileVerificationCancel(int verificationId) => '/profile-verification/cancel/$verificationId';
  static const String profileVerificationGuidelines = '/profile-verification/guidelines';

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

  // ==================== Chat & Messaging ====================
  static const String chatSend = '/chat/send';
  static const String chatHistory = '/chat/history';
  static const String chatUsers = '/chat/users';
  static const String chatMessage = '/chat/message';
  static const String chatTyping = '/chat/typing';
  static const String chatRead = '/chat/read';

  // ==================== Notifications ====================
  static const String notifications = '/notifications';
  static const String notificationsUnreadCount = '/notifications/unread-count';
  static String notificationsRead(int id) => '/notifications/$id/read';
  static const String notificationsReadAll = '/notifications/read-all';
  static String notificationsById(int id) => '/notifications/$id';

  // ==================== Video/Voice Calls ====================
  static const String callsInitiate = '/calls/initiate';
  static const String callsAccept = '/calls/accept';
  static const String callsReject = '/calls/reject';
  static const String callsEnd = '/calls/end';
  static const String callsHistory = '/calls/history';
  static const String callsActive = '/calls/active';
  static const String callsSettings = '/calls/settings';
  static String callsSettingsUpdate = '/calls/settings';
  static const String callsQuota = '/calls/quota';

// ==================== User Actions ====================
  static const String blockUser = '/block/user';
  static const String blockList = '/block/list';
  static const String reports = '/reports';
  static const String mutesMute = '/mutes/mute';
  static const String favoritesAdd = '/favorites/add';

  // ==================== Payments & Subscriptions ====================
  static const String stripePaymentIntent = '/stripe/payment-intent';
  static const String stripeCheckout = '/stripe/checkout';
  static const String stripeSubscription = '/stripe/subscription';
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
  static const String superlikePacksStripeCheckout = '/superlike-packs/stripe-checkout';
}
