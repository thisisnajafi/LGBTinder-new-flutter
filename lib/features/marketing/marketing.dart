/// Marketing feature exports
/// Provides access to all marketing-related models, services, providers, widgets, and screens
library marketing;

// Data Models
export 'data/models/campaign_model.dart';
export 'data/models/banner_model.dart';
export 'data/models/daily_reward_model.dart';
export 'data/models/badge_model.dart';

// Services
export 'data/services/marketing_service.dart';
export 'data/services/daily_rewards_service.dart';
export 'data/services/banner_service.dart';
export 'data/services/gamification_service.dart';
export 'data/services/marketing_notification_service.dart';
export 'data/services/marketing_deep_link_handler.dart';

// Providers
export 'providers/marketing_providers.dart';

// Widgets
export 'presentation/widgets/promotional_banner.dart';
export 'presentation/widgets/daily_rewards_dialog.dart';
export 'presentation/widgets/promo_code_input.dart';
export 'presentation/widgets/badge_display.dart';
export 'presentation/widgets/badge_achievement_popup.dart';

// Screens
export 'presentation/screens/enhanced_plans_screen.dart';
export 'presentation/screens/daily_rewards_screen.dart';
export 'presentation/screens/badges_screen.dart';
export 'presentation/screens/referral_screen.dart';

// Integration Helpers
export 'presentation/integration/marketing_integration.dart';
