# Complete Flutter Files List

This document lists all files that need to be created for the LGBTinder Flutter application, organized by feature and with basic structure templates.

## 📋 Core Files

### Theme Files
- `lib/core/theme/app_theme.dart` - Main theme configuration
- `lib/core/theme/app_colors.dart` - Color definitions
- `lib/core/theme/typography.dart` - Text styles
- `lib/core/theme/spacing_constants.dart` - Spacing tokens
- `lib/core/theme/border_radius_constants.dart` - Border radius tokens

### Constants Files
- `lib/core/constants/api_endpoints.dart` - API endpoint URLs
- `lib/core/constants/app_constants.dart` - App-wide constants
- `lib/core/constants/animation_constants.dart` - Animation durations & curves

### Utils Files
- `lib/core/utils/validators.dart` - Form validation
- `lib/core/utils/formatters.dart` - Data formatting
- `lib/core/utils/date_utils.dart` - Date utilities
- `lib/core/utils/image_utils.dart` - Image processing
- `lib/core/utils/error_handler.dart` - Error handling

### Core Widgets
- `lib/core/widgets/avatar_ring.dart` - Avatar with gradient ring
- `lib/core/widgets/discovery_card.dart` - Swipeable profile card
- `lib/core/widgets/chat_list_tile.dart` - Chat list item
- `lib/core/widgets/gradient_pill_button.dart` - Primary CTA button
- `lib/core/widgets/bottom_glass_nav.dart` - Bottom navigation
- `lib/core/widgets/profile_stats_card.dart` - Stats display card
- `lib/core/widgets/interest_tag.dart` - Interest tag with icon
- `lib/core/widgets/typing_indicator.dart` - Animated typing indicator
- `lib/core/widgets/match_animation.dart` - Match celebration
- `lib/core/widgets/story_carousel.dart` - Stories horizontal list
- `lib/core/widgets/loading_indicator.dart` - Loading states
- `lib/core/widgets/empty_state.dart` - Empty state widget

---

## 🔐 Authentication Feature Files

### Models
- `lib/features/auth/data/models/auth_user.dart`
- `lib/features/auth/data/models/login_request.dart`
- `lib/features/auth/data/models/register_request.dart`
- `lib/features/auth/data/models/otp_request.dart`
- `lib/features/auth/data/models/social_auth_request.dart`

### Repositories
- `lib/features/auth/data/repositories/auth_repository.dart`

### Use Cases
- `lib/features/auth/domain/use_cases/login_use_case.dart`
- `lib/features/auth/domain/use_cases/register_use_case.dart`
- `lib/features/auth/domain/use_cases/logout_use_case.dart`
- `lib/features/auth/domain/use_cases/verify_email_use_case.dart`
- `lib/features/auth/domain/use_cases/send_otp_use_case.dart`
- `lib/features/auth/domain/use_cases/verify_otp_use_case.dart`
- `lib/features/auth/domain/use_cases/reset_password_use_case.dart`
- `lib/features/auth/domain/use_cases/social_login_use_case.dart`

### Screens
- `lib/features/auth/presentation/screens/welcome_screen.dart`
- `lib/features/auth/presentation/screens/login_screen.dart`
- `lib/features/auth/presentation/screens/register_screen.dart`
- `lib/features/auth/presentation/screens/email_verification_screen.dart`
- `lib/features/auth/presentation/screens/otp_verification_screen.dart`
- `lib/features/auth/presentation/screens/forgot_password_screen.dart`
- `lib/features/auth/presentation/screens/social_auth_screen.dart`

### Widgets
- `lib/features/auth/presentation/widgets/auth_text_field.dart`
- `lib/features/auth/presentation/widgets/social_login_button.dart`
- `lib/features/auth/presentation/widgets/password_field.dart`

### Providers
- `lib/features/auth/providers/auth_provider.dart`

---

## 🎯 Onboarding Feature Files

### Screens
- `lib/features/onboarding/presentation/screens/onboarding_screen.dart`
- `lib/features/onboarding/presentation/screens/onboarding_preferences_screen.dart`
- `lib/features/onboarding/presentation/screens/enhanced_onboarding_screen.dart`

### Widgets
- `lib/features/onboarding/presentation/widgets/onboarding_page_view.dart`
- `lib/features/onboarding/presentation/widgets/onboarding_page.dart`

### Providers
- `lib/features/onboarding/providers/onboarding_provider.dart`

---

## 👤 Profile Feature Files

### Models
- `lib/features/profile/data/models/user_profile.dart`
- `lib/features/profile/data/models/profile_completion.dart`
- `lib/features/profile/data/models/user_preferences.dart`
- `lib/features/profile/data/models/user_image.dart`
- `lib/features/profile/data/models/profile_verification.dart`

### Repositories
- `lib/features/profile/data/repositories/profile_repository.dart`

### Use Cases
- `lib/features/profile/domain/use_cases/get_profile_use_case.dart`
- `lib/features/profile/domain/use_cases/update_profile_use_case.dart`
- `lib/features/profile/domain/use_cases/upload_image_use_case.dart`
- `lib/features/profile/domain/use_cases/delete_image_use_case.dart`
- `lib/features/profile/domain/use_cases/complete_profile_use_case.dart`
- `lib/features/profile/domain/use_cases/verify_profile_use_case.dart`

### Screens
- `lib/features/profile/presentation/screens/profile_screen.dart`
- `lib/features/profile/presentation/screens/profile_edit_screen.dart`
- `lib/features/profile/presentation/screens/profile_detail_screen.dart`
- `lib/features/profile/presentation/screens/profile_wizard_screen.dart`
- `lib/features/profile/presentation/screens/profile_completion_screen.dart`
- `lib/features/profile/presentation/screens/profile_verification_screen.dart`
- `lib/features/profile/presentation/screens/profile_analytics_screen.dart`
- `lib/features/profile/presentation/screens/profile_sharing_screen.dart`

### Widgets
- `lib/features/profile/presentation/widgets/profile_image_picker.dart`
- `lib/features/profile/presentation/widgets/profile_stats_row.dart`
- `lib/features/profile/presentation/widgets/interest_chip_list.dart`
- `lib/features/profile/presentation/widgets/profile_image_carousel.dart`
- `lib/features/profile/presentation/widgets/profile_bio_section.dart`

### Providers
- `lib/features/profile/providers/profile_provider.dart`

---

## 🔍 Discovery Feature Files

### Models
- `lib/features/discover/data/models/discovery_profile.dart`
- `lib/features/discover/data/models/discovery_filters.dart`
- `lib/features/discover/data/models/age_preference.dart`

### Repositories
- `lib/features/discover/data/repositories/discovery_repository.dart`

### Use Cases
- `lib/features/discover/domain/use_cases/get_discovery_profiles_use_case.dart`
- `lib/features/discover/domain/use_cases/apply_filters_use_case.dart`
- `lib/features/discover/domain/use_cases/get_nearby_suggestions_use_case.dart`

### Screens
- `lib/features/discover/presentation/screens/discover_screen.dart`
- `lib/features/discover/presentation/screens/explore_screen.dart`
- `lib/features/discover/presentation/screens/filter_screen.dart`
- `lib/features/discover/presentation/screens/profile_detail_screen.dart`
- `lib/features/discover/presentation/screens/likes_received_screen.dart`

### Widgets
- `lib/features/discover/presentation/widgets/swipeable_card_stack.dart`
- `lib/features/discover/presentation/widgets/profile_card.dart`
- `lib/features/discover/presentation/widgets/filter_chip.dart`
- `lib/features/discover/presentation/widgets/action_buttons_row.dart`

### Providers
- `lib/features/discover/providers/discovery_provider.dart`

---

## ❤️ Matching Feature Files

### Models
- `lib/features/matching/data/models/match.dart`
- `lib/features/matching/data/models/like.dart`
- `lib/features/matching/data/models/superlike.dart`
- `lib/features/matching/data/models/compatibility_score.dart`

### Repositories
- `lib/features/matching/data/repositories/matching_repository.dart`

### Use Cases
- `lib/features/matching/domain/use_cases/like_profile_use_case.dart`
- `lib/features/matching/domain/use_cases/superlike_profile_use_case.dart`
- `lib/features/matching/domain/use_cases/get_matches_use_case.dart`
- `lib/features/matching/domain/use_cases/get_compatibility_score_use_case.dart`

### Screens
- `lib/features/matching/presentation/screens/matches_screen.dart`
- `lib/features/matching/presentation/screens/match_screen.dart`
- `lib/features/matching/presentation/screens/likes_screen.dart`

### Widgets
- `lib/features/matching/presentation/widgets/match_card.dart`
- `lib/features/matching/presentation/widgets/match_celebration.dart`
- `lib/features/matching/presentation/widgets/like_button.dart`
- `lib/features/matching/presentation/widgets/superlike_button.dart`

### Providers
- `lib/features/matching/providers/matching_provider.dart`

---

## 💬 Chat Feature Files

### Models
- `lib/features/chat/data/models/message.dart`
- `lib/features/chat/data/models/chat.dart`
- `lib/features/chat/data/models/chat_participant.dart`
- `lib/features/chat/data/models/message_attachment.dart`

### Repositories
- `lib/features/chat/data/repositories/chat_repository.dart`

### Use Cases
- `lib/features/chat/domain/use_cases/send_message_use_case.dart`
- `lib/features/chat/domain/use_cases/get_chat_history_use_case.dart`
- `lib/features/chat/domain/use_cases/mark_as_read_use_case.dart`
- `lib/features/chat/domain/use_cases/delete_message_use_case.dart`
- `lib/features/chat/domain/use_cases/set_typing_use_case.dart`

### Screens
- `lib/features/chat/presentation/screens/chats_screen.dart`
- `lib/features/chat/presentation/screens/chat_screen.dart`
- `lib/features/chat/presentation/screens/group_chat_screen.dart`
- `lib/features/chat/presentation/screens/message_search_screen.dart`

### Widgets
- `lib/features/chat/presentation/widgets/message_bubble.dart`
- `lib/features/chat/presentation/widgets/chat_input.dart`
- `lib/features/chat/presentation/widgets/typing_indicator.dart`
- `lib/features/chat/presentation/widgets/message_attachment_viewer.dart`
- `lib/features/chat/presentation/widgets/online_friends_list.dart`

### Providers
- `lib/features/chat/providers/chat_provider.dart`

---

## 📞 Calls Feature Files

### Models
- `lib/features/calls/data/models/call.dart`
- `lib/features/calls/data/models/call_settings.dart`

### Repositories
- `lib/features/calls/data/repositories/call_repository.dart`

### Use Cases
- `lib/features/calls/domain/use_cases/initiate_call_use_case.dart`
- `lib/features/calls/domain/use_cases/accept_call_use_case.dart`
- `lib/features/calls/domain/use_cases/end_call_use_case.dart`
- `lib/features/calls/domain/use_cases/get_call_history_use_case.dart`

### Screens
- `lib/features/calls/presentation/screens/voice_call_screen.dart`
- `lib/features/calls/presentation/screens/video_call_screen.dart`
- `lib/features/calls/presentation/screens/call_history_screen.dart`

### Widgets
- `lib/features/calls/presentation/widgets/call_button.dart`
- `lib/features/calls/presentation/widgets/call_controls.dart`
- `lib/features/calls/presentation/widgets/call_timer.dart`

### Providers
- `lib/features/calls/providers/call_provider.dart`

---

## 📸 Stories Feature Files

### Models
- `lib/features/stories/data/models/story.dart`
- `lib/features/stories/data/models/story_reply.dart`

### Repositories
- `lib/features/stories/data/repositories/story_repository.dart`

### Use Cases
- `lib/features/stories/domain/use_cases/get_stories_use_case.dart`
- `lib/features/stories/domain/use_cases/create_story_use_case.dart`
- `lib/features/stories/domain/use_cases/view_story_use_case.dart`
- `lib/features/stories/domain/use_cases/reply_to_story_use_case.dart`

### Screens
- `lib/features/stories/presentation/screens/story_viewing_screen.dart`
- `lib/features/stories/presentation/screens/story_creation_screen.dart`

### Widgets
- `lib/features/stories/presentation/widgets/story_viewer.dart`
- `lib/features/stories/presentation/widgets/story_ring.dart`
- `lib/features/stories/presentation/widgets/story_progress_bar.dart`

### Providers
- `lib/features/stories/providers/story_provider.dart`

---

## 🔔 Notifications Feature Files

### Models
- `lib/features/notifications/data/models/notification.dart`
- `lib/features/notifications/data/models/notification_preferences.dart`

### Repositories
- `lib/features/notifications/data/repositories/notification_repository.dart`

### Use Cases
- `lib/features/notifications/domain/use_cases/get_notifications_use_case.dart`
- `lib/features/notifications/domain/use_cases/mark_as_read_use_case.dart`
- `lib/features/notifications/domain/use_cases/delete_notification_use_case.dart`
- `lib/features/notifications/domain/use_cases/update_preferences_use_case.dart`

### Screens
- `lib/features/notifications/presentation/screens/notifications_screen.dart`
- `lib/features/notifications/presentation/screens/notification_settings_screen.dart`

### Widgets
- `lib/features/notifications/presentation/widgets/notification_tile.dart`
- `lib/features/notifications/presentation/widgets/notification_badge.dart`

### Providers
- `lib/features/notifications/providers/notification_provider.dart`

---

## 💳 Payments Feature Files

### Models
- `lib/features/payments/data/models/subscription_plan.dart`
- `lib/features/payments/data/models/superlike_pack.dart`
- `lib/features/payments/data/models/payment_history.dart`
- `lib/features/payments/data/models/payment_method.dart`

### Repositories
- `lib/features/payments/data/repositories/payment_repository.dart`

### Use Cases
- `lib/features/payments/domain/use_cases/purchase_subscription_use_case.dart`
- `lib/features/payments/domain/use_cases/purchase_superlike_pack_use_case.dart`
- `lib/features/payments/domain/use_cases/get_payment_history_use_case.dart`
- `lib/features/payments/domain/use_cases/cancel_subscription_use_case.dart`
- `lib/features/payments/domain/use_cases/upgrade_subscription_use_case.dart`

### Screens
- `lib/features/payments/presentation/screens/subscription_plans_screen.dart`
- `lib/features/payments/presentation/screens/premium_subscription_screen.dart`
- `lib/features/payments/presentation/screens/superlike_packs_screen.dart`
- `lib/features/payments/presentation/screens/subscription_management_screen.dart`
- `lib/features/payments/presentation/screens/payment_methods_screen.dart`
- `lib/features/payments/presentation/screens/payment_history_screen.dart`
- `lib/features/payments/presentation/screens/payment_screen.dart`

### Widgets
- `lib/features/payments/presentation/widgets/plan_card.dart`
- `lib/features/payments/presentation/widgets/payment_method_tile.dart`
- `lib/features/payments/presentation/widgets/subscription_status_card.dart`

### Providers
- `lib/features/payments/providers/payment_provider.dart`

---

## ⚙️ Settings Feature Files

### Models
- `lib/features/settings/data/models/user_settings.dart`
- `lib/features/settings/data/models/privacy_settings.dart`
- `lib/features/settings/data/models/device_session.dart`

### Repositories
- `lib/features/settings/data/repositories/settings_repository.dart`

### Use Cases
- `lib/features/settings/domain/use_cases/update_settings_use_case.dart`
- `lib/features/settings/domain/use_cases/get_settings_use_case.dart`
- `lib/features/settings/domain/use_cases/change_password_use_case.dart`
- `lib/features/settings/domain/use_cases/delete_account_use_case.dart`

### Screens
- `lib/features/settings/presentation/screens/settings_screen.dart`
- `lib/features/settings/presentation/screens/account_management_screen.dart`
- `lib/features/settings/presentation/screens/privacy_settings_screen.dart`
- `lib/features/settings/presentation/screens/notification_settings_screen.dart`
- `lib/features/settings/presentation/screens/safety_settings_screen.dart`
- `lib/features/settings/presentation/screens/accessibility_settings_screen.dart`
- `lib/features/settings/presentation/screens/two_factor_auth_screen.dart`
- `lib/features/settings/presentation/screens/active_sessions_screen.dart`

### Widgets
- `lib/features/settings/presentation/widgets/settings_tile.dart`
- `lib/features/settings/presentation/widgets/settings_section.dart`
- `lib/features/settings/presentation/widgets/switch_tile.dart`

### Providers
- `lib/features/settings/providers/settings_provider.dart`

---

## 🛡️ Safety Feature Files

### Models
- `lib/features/safety/data/models/report.dart`
- `lib/features/safety/data/models/block.dart`
- `lib/features/safety/data/models/emergency_contact.dart`

### Repositories
- `lib/features/safety/data/repositories/safety_repository.dart`

### Use Cases
- `lib/features/safety/domain/use_cases/report_user_use_case.dart`
- `lib/features/safety/domain/use_cases/block_user_use_case.dart`
- `lib/features/safety/domain/use_cases/unblock_user_use_case.dart`
- `lib/features/safety/domain/use_cases/add_emergency_contact_use_case.dart`

### Screens
- `lib/features/safety/presentation/screens/safety_center_screen.dart`
- `lib/features/safety/presentation/screens/report_user_screen.dart`
- `lib/features/safety/presentation/screens/blocked_users_screen.dart`
- `lib/features/safety/presentation/screens/emergency_contacts_screen.dart`
- `lib/features/safety/presentation/screens/report_history_screen.dart`

### Widgets
- `lib/features/safety/presentation/widgets/report_category_tile.dart`
- `lib/features/safety/presentation/widgets/block_user_dialog.dart`

### Providers
- `lib/features/safety/providers/safety_provider.dart`

---

## 📰 Feed Feature Files

### Models
- `lib/features/feed/data/models/feed_post.dart`
- `lib/features/feed/data/models/feed_comment.dart`
- `lib/features/feed/data/models/feed_reaction.dart`

### Repositories
- `lib/features/feed/data/repositories/feed_repository.dart`

### Use Cases
- `lib/features/feed/domain/use_cases/get_feed_use_case.dart`
- `lib/features/feed/domain/use_cases/create_post_use_case.dart`
- `lib/features/feed/domain/use_cases/like_post_use_case.dart`
- `lib/features/feed/domain/use_cases/comment_on_post_use_case.dart`

### Screens
- `lib/features/feed/presentation/screens/feed_screen.dart`

### Widgets
- `lib/features/feed/presentation/widgets/feed_post_card.dart`
- `lib/features/feed/presentation/widgets/feed_comment_section.dart`
- `lib/features/feed/presentation/widgets/feed_reaction_bar.dart`

### Providers
- `lib/features/feed/providers/feed_provider.dart`

---

## 📊 Analytics Feature Files

### Models
- `lib/features/analytics/data/models/user_analytics.dart`

### Repositories
- `lib/features/analytics/data/repositories/analytics_repository.dart`

### Use Cases
- `lib/features/analytics/domain/use_cases/get_analytics_use_case.dart`
- `lib/features/analytics/domain/use_cases/track_activity_use_case.dart`

### Screens
- `lib/features/analytics/presentation/screens/analytics_screen.dart`

### Widgets
- `lib/features/analytics/presentation/widgets/analytics_chart.dart`
- `lib/features/analytics/presentation/widgets/analytics_card.dart`

### Providers
- `lib/features/analytics/providers/analytics_provider.dart`

---

## 🔗 Shared Files

### Models
- `lib/shared/models/api_response.dart`
- `lib/shared/models/api_error.dart`
- `lib/shared/models/pagination.dart`

### Services
- `lib/shared/services/api_service.dart`
- `lib/shared/services/storage_service.dart`
- `lib/shared/services/websocket_service.dart`
- `lib/shared/services/notification_service.dart`

### Widgets
- `lib/shared/widgets/error_widget.dart`
- `lib/shared/widgets/loading_widget.dart`

---

## 🛣️ Routes Files

- `lib/routes/app_router.dart` - Main router configuration
- `lib/routes/route_names.dart` - Route name constants
- `lib/routes/route_guards.dart` - Route guards and middleware

---

## 📝 File Creation Template

Each file should follow this basic structure:

```dart
// File: lib/features/[feature]/presentation/screens/[screen_name]_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// [ScreenName] - Brief description of the screen
/// 
/// This screen handles [purpose/functionality]
class ScreenName extends ConsumerStatefulWidget {
  const ScreenName({Key? key}) : super(key: key);

  @override
  ConsumerState<ScreenName> createState() => _ScreenNameState();
}

class _ScreenNameState extends ConsumerState<ScreenName> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Screen Title'),
      ),
      body: const Center(
        child: Text('Screen Content'),
      ),
    );
  }
}
```

---

## ✅ Total File Count

- **Core Files**: ~20 files
- **Auth Feature**: ~25 files
- **Onboarding Feature**: ~5 files
- **Profile Feature**: ~30 files
- **Discovery Feature**: ~20 files
- **Matching Feature**: ~20 files
- **Chat Feature**: ~25 files
- **Calls Feature**: ~15 files
- **Stories Feature**: ~15 files
- **Notifications Feature**: ~15 files
- **Payments Feature**: ~25 files
- **Settings Feature**: ~25 files
- **Safety Feature**: ~20 files
- **Feed Feature**: ~15 files
- **Analytics Feature**: ~10 files
- **Shared Files**: ~10 files
- **Routes Files**: ~3 files

**Total: ~300+ files**

---

**Next Steps**: 
1. Create directory structure using PowerShell script
2. Create each file with basic template structure
3. Implement functionality based on API endpoints
4. Follow UI design system from `UI-DESIGN-SYSTEM.md`
5. Reference screen specifications from `Enhanced-Flutter-UI-Document.md`

