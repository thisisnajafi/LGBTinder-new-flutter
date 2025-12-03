# LGBTinder Flutter App - Comprehensive TODO List

## Overview
This document contains all 465 TODO comments found throughout the LGBTinder Flutter application codebase. Tasks are organized by feature/module for better management and tracking.

## Statistics
- **Total TODO Comments**: 465
- **Files with TODOs**: 260
- **Main Categories**: Settings, Profile, Auth, Payments, Chat, Discovery, Safety, etc.

## Task Categories

### 🔧 Settings Module
#### Providers
- [ ] `lib/features/settings/providers/settings_provider.dart` - Add state properties
- [ ] `lib/features/settings/providers/settings_provider.dart` - Implement state management methods

#### Widgets
- [ ] `lib/features/settings/presentation/widgets/switch_tile.dart` - Implement widget
- [ ] `lib/features/settings/presentation/widgets/settings_tile.dart` - Implement widget
- [ ] `lib/features/settings/presentation/widgets/settings_section.dart` - Implement widget

#### Use Cases
- [ ] `lib/features/settings/domain/use_cases/update_settings_use_case.dart` - Implement use case
- [ ] `lib/features/settings/domain/use_cases/get_settings_use_case.dart` - Implement use case
- [ ] `lib/features/settings/domain/use_cases/delete_account_use_case.dart` - Implement use case
- [ ] `lib/features/settings/domain/use_cases/change_password_use_case.dart` - Implement use case

#### Repositories
- [ ] `lib/features/settings/data/repositories/settings_repository.dart` - Implement repository methods

#### Models
- [ ] `lib/features/settings/data/models/user_settings.dart` - Add properties and fromJson/toJson methods
- [ ] `lib/features/settings/data/models/privacy_settings.dart` - Add properties and fromJson/toJson methods
- [ ] `lib/features/settings/data/models/device_session.dart` - Add properties and fromJson/toJson methods

### 🛡️ Safety Module
#### Providers
- [ ] `lib/features/safety/providers/safety_provider.dart` - Add state properties
- [ ] `lib/features/safety/providers/safety_provider.dart` - Implement state management methods

#### Widgets
- [ ] `lib/features/safety/presentation/widgets/report_category_tile.dart` - Implement widget
- [ ] `lib/features/safety/presentation/widgets/block_user_dialog.dart` - Implement widget

#### Use Cases
- [ ] `lib/features/safety/domain/use_cases/unblock_user_use_case.dart` - Implement use case
- [ ] `lib/features/safety/domain/use_cases/report_user_use_case.dart` - Implement use case
- [ ] `lib/features/safety/domain/use_cases/block_user_use_case.dart` - Implement use case
- [ ] `lib/features/safety/domain/use_cases/add_emergency_contact_use_case.dart` - Implement use case

#### Repositories
- [ ] `lib/features/safety/data/repositories/safety_repository.dart` - Implement repository methods

#### Models
- [ ] `lib/features/safety/data/models/emergency_contact.dart` - Add properties and fromJson/toJson methods

### 👤 Profile Module ✅ COMPLETED
#### Providers ✅ COMPLETED
- [x] `lib/features/profile/providers/profile_provider.dart` - Add state properties
- [x] `lib/features/profile/providers/profile_provider.dart` - Implement state management methods

#### Widgets ✅ COMPLETED
- [x] `lib/features/profile/presentation/widgets/profile_stats_row.dart` - Implement widget
- [x] `lib/features/profile/presentation/widgets/profile_image_picker.dart` - Implement widget
- [x] `lib/features/profile/presentation/widgets/profile_image_carousel.dart` - Implement widget
- [x] `lib/features/profile/presentation/widgets/profile_bio_section.dart` - Implement widget
- [x] `lib/features/profile/presentation/widgets/interest_chip_list.dart` - Implement widget

#### Use Cases ✅ COMPLETED
- [x] `lib/features/profile/domain/use_cases/verify_profile_use_case.dart` - Implement use case
- [x] `lib/features/profile/domain/use_cases/upload_image_use_case.dart` - Implement use case
- [x] `lib/features/profile/domain/use_cases/update_profile_use_case.dart` - Implement use case
- [x] `lib/features/profile/domain/use_cases/get_profile_use_case.dart` - Implement use case
- [x] `lib/features/profile/domain/use_cases/delete_image_use_case.dart` - Implement use case
- [x] `lib/features/profile/domain/use_cases/complete_profile_use_case.dart` - Implement use case

#### Repositories ✅ COMPLETED
- [x] `lib/features/profile/data/repositories/profile_repository.dart` - Implement repository methods

#### Models ✅ COMPLETED
- [x] `lib/features/profile/data/models/user_preferences.dart` - Add properties and fromJson/toJson methods
- [x] `lib/features/profile/data/models/user_image.dart` - Add properties and fromJson/toJson methods
- [x] `lib/features/profile/data/models/profile_verification.dart` - Add properties and fromJson/toJson methods
- [x] `lib/features/profile/data/models/profile_completion.dart` - Add properties and fromJson/toJson methods
- [x] `lib/features/profile/data/models/update_profile_request.dart` - Already implemented
- [x] `lib/features/profile/data/models/user_profile.dart` - Already implemented

#### Services ✅ COMPLETED
- [x] `lib/features/profile/domain/services/profile_service.dart` - Created and implemented
- [x] Added profile API endpoints to api_endpoints.dart

### 💳 Payments Module
#### Providers
- [ ] `lib/features/payments/providers/payment_provider.dart` - Add state properties
- [ ] `lib/features/payments/providers/payment_provider.dart` - Implement state management methods

#### Widgets
- [ ] `lib/features/payments/presentation/widgets/subscription_status_card.dart` - Implement widget
- [ ] `lib/features/payments/presentation/widgets/plan_card.dart` - Implement widget
- [ ] `lib/features/payments/presentation/widgets/payment_method_tile.dart` - Implement widget

#### Use Cases
- [ ] `lib/features/payments/domain/use_cases/upgrade_subscription_use_case.dart` - Implement use case
- [ ] `lib/features/payments/domain/use_cases/purchase_superlike_pack_use_case.dart` - Implement use case
- [ ] `lib/features/payments/domain/use_cases/purchase_subscription_use_case.dart` - Implement use case
- [ ] `lib/features/payments/domain/use_cases/get_payment_history_use_case.dart` - Implement use case
- [ ] `lib/features/payments/domain/use_cases/cancel_subscription_use_case.dart` - Implement use case

#### Repositories
- [ ] `lib/features/payments/data/repositories/payment_repository.dart` - Implement repository methods

#### Models
- [ ] `lib/features/payments/data/models/payment_method.dart` - Add properties and fromJson/toJson methods
- [ ] `lib/features/payments/data/models/payment_history.dart` - Add properties and fromJson/toJson methods

#### Services
- [ ] `lib/features/payments/data/services/google_play_billing_service.dart` - Implement with correct API for current in_app_purchase version

### 🎯 Onboarding Module
#### Providers
- [ ] `lib/features/onboarding/providers/onboarding_provider.dart` - Add state properties
- [ ] `lib/features/onboarding/providers/onboarding_provider.dart` - Implement state management methods

#### Widgets
- [ ] `lib/features/onboarding/presentation/widgets/onboarding_page_view.dart` - Implement widget
- [ ] `lib/features/onboarding/presentation/widgets/onboarding_page.dart` - Implement widget

### 🔔 Notifications Module
#### Providers
- [ ] `lib/features/notifications/providers/notification_provider.dart` - Add state properties
- [ ] `lib/features/notifications/providers/notification_provider.dart` - Implement state management methods

#### Widgets
- [ ] `lib/features/notifications/presentation/widgets/notification_badge.dart` - Implement widget

#### Use Cases
- [ ] `lib/features/notifications/domain/use_cases/update_preferences_use_case.dart` - Implement use case
- [ ] `lib/features/notifications/domain/use_cases/mark_as_read_use_case.dart` - Implement use case
- [ ] `lib/features/notifications/domain/use_cases/get_notifications_use_case.dart` - Implement use case
- [ ] `lib/features/notifications/domain/use_cases/delete_notification_use_case.dart` - Implement use case

#### Repositories
- [ ] `lib/features/notifications/data/repositories/notification_repository.dart` - Implement repository methods

#### Models
- [ ] `lib/features/notifications/data/models/notification_preferences.dart` - Add properties and fromJson/toJson methods

### 💞 Matching Module
#### Providers
- [ ] `lib/features/matching/providers/matching_provider.dart` - Add state properties
- [ ] `lib/features/matching/providers/matching_provider.dart` - Implement state management methods

#### Widgets
- [ ] `lib/features/matching/presentation/widgets/superlike_button.dart` - Implement widget
- [ ] `lib/features/matching/presentation/widgets/match_celebration.dart` - Implement widget
- [ ] `lib/features/matching/presentation/widgets/match_card.dart` - Implement widget
- [ ] `lib/features/matching/presentation/widgets/like_button.dart` - Implement widget

#### Use Cases
- [ ] `lib/features/matching/domain/use_cases/superlike_profile_use_case.dart` - Implement use case
- [ ] `lib/features/matching/domain/use_cases/like_profile_use_case.dart` - Implement use case
- [ ] `lib/features/matching/domain/use_cases/get_matches_use_case.dart` - Implement use case
- [ ] `lib/features/matching/domain/use_cases/get_compatibility_score_use_case.dart` - Implement use case

#### Repositories
- [ ] `lib/features/matching/data/repositories/matching_repository.dart` - Implement repository methods

#### Models
- [ ] `lib/features/matching/data/models/superlike.dart` - Add properties and fromJson/toJson methods

### 🔍 Discovery Module ✅ COMPLETED
#### Providers ✅ COMPLETED
- [x] `lib/features/discover/providers/discovery_provider.dart` - Add state properties
- [x] `lib/features/discover/providers/discovery_provider.dart` - Implement state management methods

#### Widgets ✅ COMPLETED
- [x] `lib/features/discover/presentation/widgets/swipeable_card_stack.dart` - Implement widget
- [x] `lib/features/discover/presentation/widgets/profile_card.dart` - Implement widget
- [x] `lib/features/discover/presentation/widgets/filter_chip.dart` - Implement widget
- [x] `lib/features/discover/presentation/widgets/action_buttons_row.dart` - Implement widget

#### Use Cases ✅ COMPLETED
- [x] `lib/features/discover/domain/use_cases/get_nearby_suggestions_use_case.dart` - Implement use case
- [x] `lib/features/discover/domain/use_cases/get_discovery_profiles_use_case.dart` - Implement use case
- [x] `lib/features/discover/domain/use_cases/apply_filters_use_case.dart` - Implement use case

#### Repositories ✅ COMPLETED
- [x] `lib/features/discover/data/repositories/discovery_repository.dart` - Implement repository methods

#### Models ✅ COMPLETED
- [x] `lib/features/discover/data/models/discovery_filters.dart` - Add properties and fromJson/toJson methods
- [x] `lib/features/discover/data/models/age_preference.dart` - Add properties and fromJson/toJson methods
- [x] `lib/features/discover/data/models/discovery_profile.dart` - Already implemented

#### Services ✅ COMPLETED
- [x] `lib/features/discover/data/services/discovery_service.dart` - Extended with additional methods
- [x] Added discovery API endpoints integration

### 💬 Chat Module
#### Providers
- [ ] `lib/features/chat/providers/chat_provider.dart` - Add state properties
- [ ] `lib/features/chat/providers/chat_provider.dart` - Implement state management methods

#### Widgets
- [ ] `lib/features/chat/presentation/widgets/typing_indicator.dart` - Implement widget
- [ ] `lib/features/chat/presentation/widgets/online_friends_list.dart` - Implement widget
- [ ] `lib/features/chat/presentation/widgets/message_bubble.dart` - Implement widget
- [ ] `lib/features/chat/presentation/widgets/message_attachment_viewer.dart` - Implement widget
- [ ] `lib/features/chat/presentation/widgets/chat_input.dart` - Implement widget

#### Use Cases
- [ ] `lib/features/chat/domain/use_cases/set_typing_use_case.dart` - Implement use case
- [ ] `lib/features/chat/domain/use_cases/send_message_use_case.dart` - Implement use case
- [ ] `lib/features/chat/domain/use_cases/mark_as_read_use_case.dart` - Implement use case
- [ ] `lib/features/chat/domain/use_cases/get_chat_history_use_case.dart` - Implement use case
- [ ] `lib/features/chat/domain/use_cases/delete_message_use_case.dart` - Implement use case

#### Repositories
- [ ] `lib/features/chat/data/repositories/chat_repository.dart` - Implement repository methods

#### Models
- [ ] `lib/features/chat/data/models/message_attachment.dart` - Add properties and fromJson/toJson methods

### 📞 Calls Module
#### Widgets
- [ ] `lib/features/calls/presentation/widgets/call_timer.dart` - Implement widget
- [ ] `lib/features/calls/presentation/widgets/call_controls.dart` - Implement widget
- [ ] `lib/features/calls/presentation/widgets/call_button.dart` - Implement widget

#### Use Cases
- [ ] `lib/features/calls/domain/use_cases/initiate_call_use_case.dart` - Implement use case
- [ ] `lib/features/calls/domain/use_cases/get_call_history_use_case.dart` - Implement use case
- [ ] `lib/features/calls/domain/use_cases/end_call_use_case.dart` - Implement use case
- [ ] `lib/features/calls/domain/use_cases/accept_call_use_case.dart` - Implement use case

#### Repositories
- [ ] `lib/features/calls/data/repositories/call_repository.dart` - Implement repository methods

### 🔐 Authentication Module ✅ COMPLETED
#### Widgets
- [ ] `lib/features/auth/presentation/widgets/social_login_button.dart` - Implement widget
- [ ] `lib/features/auth/presentation/widgets/password_field.dart` - Implement widget
- [ ] `lib/features/auth/presentation/widgets/auth_text_field.dart` - Implement widget

#### Use Cases ✅ COMPLETED
- [x] `lib/features/auth/domain/use_cases/verify_otp_use_case.dart` - Implement use case
- [x] `lib/features/auth/domain/use_cases/verify_email_use_case.dart` - Implement use case
- [x] `lib/features/auth/domain/use_cases/social_login_use_case.dart` - Implement use case
- [x] `lib/features/auth/domain/use_cases/send_otp_use_case.dart` - Implement use case
- [x] `lib/features/auth/domain/use_cases/reset_password_use_case.dart` - Implement use case
- [x] `lib/features/auth/domain/use_cases/register_use_case.dart` - Implement use case
- [x] `lib/features/auth/domain/use_cases/logout_use_case.dart` - Implement use case
- [x] `lib/features/auth/domain/use_cases/login_use_case.dart` - Implement use case
- [x] `lib/features/auth/domain/use_cases/complete_profile_use_case.dart` - Implement use case

#### Models ✅ COMPLETED
- [x] `lib/features/auth/data/models/social_auth_request.dart` - Add properties and fromJson/toJson methods
- [x] `lib/features/auth/data/models/otp_request.dart` - Add properties and fromJson/toJson methods
- [x] `lib/features/auth/data/models/auth_user.dart` - Add properties and fromJson/toJson methods
- [x] `lib/features/auth/data/models/send_otp_request.dart` - Created
- [x] `lib/features/auth/data/models/verify_otp_request.dart` - Created
- [x] `lib/features/auth/data/models/otp_response.dart` - Created
- [x] `lib/features/auth/data/models/reset_password_request.dart` - Created
- [x] `lib/features/auth/data/models/social_auth_response.dart` - Created

#### Services & Repositories ✅ COMPLETED
- [x] Added OTP methods to AuthService and AuthRepository
- [x] Added Social login methods to AuthService and AuthRepository
- [x] Added Reset password methods to AuthService and AuthRepository
- [x] Updated API endpoints for OTP and Social login

### 🎨 UI/UX Implementation Tasks

#### Settings Screen
- [ ] `lib/screens/settings_screen.dart` - Navigate to profile
- [ ] `lib/screens/settings_screen.dart` - Navigate to help
- [ ] `lib/screens/settings_screen.dart` - Show terms
- [ ] `lib/screens/settings_screen.dart` - Show privacy policy

#### Profile Page
- [ ] `lib/pages/profile_page.dart` - Show match screen
- [ ] `lib/pages/profile_page.dart` - Add verification status to UserProfile
- [ ] `lib/pages/profile_page.dart` - Add premium status to UserProfile
- [ ] `lib/pages/profile_page.dart` - Add online status to UserProfile
- [ ] `lib/pages/profile_page.dart` - Open image picker
- [ ] `lib/pages/profile_page.dart` - Add views count if available
- [ ] `lib/pages/profile_page.dart` - Open image viewer
- [ ] `lib/pages/profile_page.dart` - Add verification status
- [ ] `lib/pages/profile_page.dart` - Add phone verification status
- [ ] `lib/pages/profile_page.dart` - Get email verification from user info
- [ ] `lib/pages/profile_page.dart` - Navigate to verification

#### Discovery Page
- [ ] `lib/pages/discovery_page.dart` - Add verification status to DiscoveryProfile
- [ ] `lib/pages/discovery_page.dart` - Add premium status to DiscoveryProfile
- [ ] `lib/pages/discovery_page.dart` - Map gender names to IDs using reference data
- [ ] `lib/pages/discovery_page.dart` - Get actual user data from providers
- [ ] `lib/pages/discovery_page.dart` - Replace with actual user avatar
- [ ] `lib/pages/discovery_page.dart` - Replace with actual user name
- [ ] `lib/pages/discovery_page.dart` - Navigate to notifications
- [ ] `lib/pages/discovery_page.dart` - Check if filter icon exists

#### Chat Page
- [ ] `lib/pages/chat_page.dart` - Open media picker
- [ ] `lib/pages/chat_page.dart` - Open emoji picker
- [ ] `lib/pages/chat_page.dart` - Navigate to profile
- [ ] `lib/pages/chat_page.dart` - Get pinned count from API
- [ ] `lib/pages/chat_page.dart` - Scroll to pinned messages

#### Profile Edit Page
- [ ] `lib/pages/profile_edit_page.dart` - Open interests editor with reference data

#### Chat List Page
- [ ] `lib/pages/chat_list_page.dart` - Open filters

#### Profile Detail Screen
- [ ] `lib/screens/discovery/profile_detail_screen.dart` - Open image viewer
- [ ] `lib/screens/discovery/profile_detail_screen.dart` - Check if matched

#### Voice Call Screen
- [ ] `lib/screens/voice_call_screen.dart` - Toggle mute via WebRTC
- [ ] `lib/screens/voice_call_screen.dart` - Toggle speaker via WebRTC
- [ ] `lib/screens/voice_call_screen.dart` - Handle incoming call channel/token retrieval
- [ ] `lib/screens/voice_call_screen.dart` - Minimize call

#### Video Call Screen
- [ ] `lib/screens/video_call_screen.dart` - Initialize WebRTC connection for accepted call
- [ ] `lib/screens/video_call_screen.dart` - Minimize call

#### Call History Screen
- [ ] `lib/screens/call_history_screen.dart` - Fetch user avatar from profile API
- [ ] `lib/screens/call_history_screen.dart` - Fetch user name from profile API
- [ ] `lib/screens/call_history_screen.dart` - Use proper timestamp from API
- [ ] `lib/screens/call_history_screen.dart` - Initiate call

#### Match Screen
- [ ] `lib/widgets/match/match_screen.dart` - Get current user's image

#### Matches List
- [ ] `lib/widgets/lists_feeds/matches_list.dart` - Parse time from API format

#### Swipeable Card
- [ ] `lib/widgets/cards/swipeable_card.dart` - Check if more icon exists
- [ ] `lib/widgets/cards/swipeable_card.dart` - Show menu options (report, block, etc.)

#### Authentication Screens
- [ ] `lib/screens/auth/profile_completion_screen.dart` - Open image picker (multiple instances)
- [ ] `lib/screens/auth/profile_completion_screen.dart` - Open image viewer
- [ ] `lib/screens/auth/profile_wizard_screen.dart` - Save profile via API
- [ ] `lib/screens/auth/profile_wizard_screen.dart` - Open image picker (multiple instances)
- [ ] `lib/screens/auth/password_reset_flow_screen.dart` - Send OTP via API
- [ ] `lib/screens/auth/password_reset_flow_screen.dart` - Verify OTP via API
- [ ] `lib/screens/auth/password_reset_flow_screen.dart` - Get token from API response
- [ ] `lib/screens/auth/password_reset_flow_screen.dart` - Resend OTP via API
- [ ] `lib/screens/auth/password_reset_flow_screen.dart` - Reset password via API
- [ ] `lib/screens/auth/forgot_password_screen.dart` - Send password reset email via API

#### Push Notification Service
- [ ] `lib/shared/services/push_notification_service.dart` - Send new token to backend
- [ ] `lib/shared/services/push_notification_service.dart` - Navigate to matches screen
- [ ] `lib/shared/services/push_notification_service.dart` - Navigate to match screen
- [ ] `lib/shared/services/push_notification_service.dart` - Navigate to chat screen
- [ ] `lib/shared/services/push_notification_service.dart` - Navigate to notifications screen

## Implementation Priority

### 🚨 High Priority (Core Features)
1. **Authentication** - Login, registration, password reset
2. **Profile Management** - Basic profile creation and editing
3. **Discovery** - Core swiping functionality
4. **Matching** - Like/superlike functionality
5. **Chat** - Basic messaging

### ⚠️ Medium Priority (Enhanced Features)
1. **Calls** - Voice and video calling
2. **Payments** - Subscription and in-app purchases
3. **Safety** - Reporting and blocking
4. **Notifications** - Push notifications
5. **Settings** - User preferences

### 📈 Low Priority (Polish)
1. **Onboarding** - Enhanced user onboarding
2. **Advanced Chat** - Media sharing, typing indicators
3. **Advanced Discovery** - Filters, location-based matching

## Task Completion Checklist

### Feature Implementation Template
- [ ] Design Review
- [ ] API Integration
- [ ] UI Implementation
- [ ] State Management
- [ ] Testing (Unit + Integration)
- [ ] Code Review
- [ ] QA Testing
- [ ] Deployment

### Quality Gates
- [ ] Follows LGBTinder design system
- [ ] Implements proper error handling
- [ ] Includes loading states
- [ ] Supports both light/dark themes
- [ ] Accessible (WCAG compliance)
- [ ] Performance optimized
- [ ] Proper documentation

## Notes

- **Total Tasks**: 465 TODO comments across 260 files
- **Architecture**: Clean Architecture with feature-based organization
- **State Management**: Riverpod for state management
- **Navigation**: Go Router for routing
- **UI Framework**: Material 3 with custom LGBT+ theme

This comprehensive list should serve as a roadmap for completing the LGBTinder Flutter application. Each TODO represents a specific implementation requirement that needs to be addressed for full functionality.
