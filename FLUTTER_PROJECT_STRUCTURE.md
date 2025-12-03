# LGBTinder Flutter Project Structure

Complete folder structure and file organization for the LGBTinder Flutter application.

## 📁 Complete Folder Structure

```
lib/
├── core/
│   ├── theme/
│   │   ├── app_theme.dart              # Main theme configuration
│   │   ├── app_colors.dart             # Color definitions (dark/light)
│   │   ├── typography.dart             # Text styles
│   │   ├── spacing_constants.dart      # Spacing tokens
│   │   └── border_radius_constants.dart # Border radius tokens
│   ├── constants/
│   │   ├── api_endpoints.dart          # API endpoint URLs
│   │   ├── app_constants.dart          # App-wide constants
│   │   └── animation_constants.dart    # Animation durations & curves
│   ├── utils/
│   │   ├── validators.dart             # Form validation
│   │   ├── formatters.dart             # Data formatting
│   │   ├── date_utils.dart             # Date utilities
│   │   ├── image_utils.dart            # Image processing
│   │   └── error_handler.dart          # Error handling
│   └── widgets/
│       ├── avatar_ring.dart             # Avatar with gradient ring
│       ├── discovery_card.dart          # Swipeable profile card
│       ├── chat_list_tile.dart          # Chat list item
│       ├── gradient_pill_button.dart    # Primary CTA button
│       ├── bottom_glass_nav.dart       # Bottom navigation
│       ├── profile_stats_card.dart     # Stats display card
│       ├── interest_tag.dart           # Interest tag with icon
│       ├── typing_indicator.dart       # Animated typing indicator
│       ├── match_animation.dart        # Match celebration
│       ├── story_carousel.dart         # Stories horizontal list
│       ├── loading_indicator.dart      # Loading states
│       └── empty_state.dart            # Empty state widget
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   ├── auth_user.dart
│   │   │   │   ├── login_request.dart
│   │   │   │   └── register_request.dart
│   │   │   └── repositories/
│   │   │       └── auth_repository.dart
│   │   ├── domain/
│   │   │   └── use_cases/
│   │   │       ├── login_use_case.dart
│   │   │       ├── register_use_case.dart
│   │   │       └── logout_use_case.dart
│   │   ├── presentation/
│   │   │   ├── screens/
│   │   │   │   ├── welcome_screen.dart
│   │   │   │   ├── login_screen.dart
│   │   │   │   ├── register_screen.dart
│   │   │   │   ├── email_verification_screen.dart
│   │   │   │   ├── otp_verification_screen.dart
│   │   │   │   ├── forgot_password_screen.dart
│   │   │   │   └── social_auth_screen.dart
│   │   │   └── widgets/
│   │   │       ├── auth_text_field.dart
│   │   │       └── social_login_button.dart
│   │   └── providers/
│   │       └── auth_provider.dart
│   │
│   ├── onboarding/
│   │   ├── presentation/
│   │   │   ├── screens/
│   │   │   │   ├── onboarding_screen.dart
│   │   │   │   ├── onboarding_preferences_screen.dart
│   │   │   │   └── enhanced_onboarding_screen.dart
│   │   │   └── widgets/
│   │   │       └── onboarding_page_view.dart
│   │   └── providers/
│   │       └── onboarding_provider.dart
│   │
│   ├── profile/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   ├── user_profile.dart
│   │   │   │   ├── profile_completion.dart
│   │   │   │   └── user_preferences.dart
│   │   │   └── repositories/
│   │   │       └── profile_repository.dart
│   │   ├── domain/
│   │   │   └── use_cases/
│   │   │       ├── get_profile_use_case.dart
│   │   │       ├── update_profile_use_case.dart
│   │   │       └── upload_image_use_case.dart
│   │   ├── presentation/
│   │   │   ├── screens/
│   │   │   │   ├── profile_screen.dart
│   │   │   │   ├── profile_edit_screen.dart
│   │   │   │   ├── profile_detail_screen.dart
│   │   │   │   ├── profile_wizard_screen.dart
│   │   │   │   ├── profile_completion_screen.dart
│   │   │   │   ├── profile_verification_screen.dart
│   │   │   │   ├── profile_analytics_screen.dart
│   │   │   │   └── profile_sharing_screen.dart
│   │   │   └── widgets/
│   │   │       ├── profile_image_picker.dart
│   │   │       ├── profile_stats_row.dart
│   │   │       └── interest_chip_list.dart
│   │   └── providers/
│   │       └── profile_provider.dart
│   │
│   ├── discover/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   ├── discovery_profile.dart
│   │   │   │   └── discovery_filters.dart
│   │   │   └── repositories/
│   │   │       └── discovery_repository.dart
│   │   ├── domain/
│   │   │   └── use_cases/
│   │   │       ├── get_discovery_profiles_use_case.dart
│   │   │       └── apply_filters_use_case.dart
│   │   ├── presentation/
│   │   │   ├── screens/
│   │   │   │   ├── discover_screen.dart
│   │   │   │   ├── explore_screen.dart
│   │   │   │   ├── filter_screen.dart
│   │   │   │   ├── profile_detail_screen.dart
│   │   │   │   └── likes_received_screen.dart
│   │   │   └── widgets/
│   │   │       ├── swipeable_card_stack.dart
│   │   │       ├── profile_card.dart
│   │   │       └── filter_chip.dart
│   │   └── providers/
│   │       └── discovery_provider.dart
│   │
│   ├── matching/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   ├── match.dart
│   │   │   │   ├── like.dart
│   │   │   │   └── superlike.dart
│   │   │   └── repositories/
│   │   │       └── matching_repository.dart
│   │   ├── domain/
│   │   │   └── use_cases/
│   │   │       ├── like_profile_use_case.dart
│   │   │       ├── superlike_profile_use_case.dart
│   │   │       └── get_matches_use_case.dart
│   │   ├── presentation/
│   │   │   ├── screens/
│   │   │   │   ├── matches_screen.dart
│   │   │   │   ├── match_screen.dart
│   │   │   │   └── likes_screen.dart
│   │   │   └── widgets/
│   │   │       ├── match_card.dart
│   │   │       └── match_celebration.dart
│   │   └── providers/
│   │       └── matching_provider.dart
│   │
│   ├── chat/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   ├── message.dart
│   │   │   │   ├── chat.dart
│   │   │   │   └── chat_participant.dart
│   │   │   └── repositories/
│   │   │       └── chat_repository.dart
│   │   ├── domain/
│   │   │   └── use_cases/
│   │   │       ├── send_message_use_case.dart
│   │   │       ├── get_chat_history_use_case.dart
│   │   │       └── mark_as_read_use_case.dart
│   │   ├── presentation/
│   │   │   ├── screens/
│   │   │   │   ├── chats_screen.dart
│   │   │   │   ├── chat_screen.dart
│   │   │   │   ├── group_chat_screen.dart
│   │   │   │   └── message_search_screen.dart
│   │   │   └── widgets/
│   │   │       ├── message_bubble.dart
│   │   │       ├── chat_input.dart
│   │   │       ├── typing_indicator.dart
│   │   │       └── message_attachment_viewer.dart
│   │   └── providers/
│   │       └── chat_provider.dart
│   │
│   ├── calls/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   └── call.dart
│   │   │   └── repositories/
│   │   │       └── call_repository.dart
│   │   ├── domain/
│   │   │   └── use_cases/
│   │   │       ├── initiate_call_use_case.dart
│   │   │       └── end_call_use_case.dart
│   │   ├── presentation/
│   │   │   ├── screens/
│   │   │   │   ├── voice_call_screen.dart
│   │   │   │   ├── video_call_screen.dart
│   │   │   │   └── call_history_screen.dart
│   │   │   └── widgets/
│   │   │       ├── call_button.dart
│   │   │       └── call_controls.dart
│   │   └── providers/
│   │       └── call_provider.dart
│   │
│   ├── stories/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   └── story.dart
│   │   │   └── repositories/
│   │   │       └── story_repository.dart
│   │   ├── domain/
│   │   │   └── use_cases/
│   │   │       ├── get_stories_use_case.dart
│   │   │       └── create_story_use_case.dart
│   │   ├── presentation/
│   │   │   ├── screens/
│   │   │   │   ├── story_viewing_screen.dart
│   │   │   │   └── story_creation_screen.dart
│   │   │   └── widgets/
│   │   │       ├── story_viewer.dart
│   │   │       └── story_ring.dart
│   │   └── providers/
│   │       └── story_provider.dart
│   │
│   ├── notifications/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   └── notification.dart
│   │   │   └── repositories/
│   │   │       └── notification_repository.dart
│   │   ├── domain/
│   │   │   └── use_cases/
│   │   │       ├── get_notifications_use_case.dart
│   │   │       └── mark_as_read_use_case.dart
│   │   ├── presentation/
│   │   │   ├── screens/
│   │   │   │   └── notifications_screen.dart
│   │   │   └── widgets/
│   │   │       └── notification_tile.dart
│   │   └── providers/
│   │       └── notification_provider.dart
│   │
│   ├── payments/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   ├── subscription_plan.dart
│   │   │   │   ├── superlike_pack.dart
│   │   │   │   └── payment_history.dart
│   │   │   └── repositories/
│   │   │       └── payment_repository.dart
│   │   ├── domain/
│   │   │   └── use_cases/
│   │   │       ├── purchase_subscription_use_case.dart
│   │   │       └── purchase_superlike_pack_use_case.dart
│   │   ├── presentation/
│   │   │   ├── screens/
│   │   │   │   ├── subscription_plans_screen.dart
│   │   │   │   ├── premium_subscription_screen.dart
│   │   │   │   ├── superlike_packs_screen.dart
│   │   │   │   ├── subscription_management_screen.dart
│   │   │   │   ├── payment_methods_screen.dart
│   │   │   │   ├── payment_history_screen.dart
│   │   │   │   └── payment_screen.dart
│   │   │   └── widgets/
│   │   │       ├── plan_card.dart
│   │   │       └── payment_method_tile.dart
│   │   └── providers/
│   │       └── payment_provider.dart
│   │
│   ├── settings/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   ├── user_settings.dart
│   │   │   │   └── privacy_settings.dart
│   │   │   └── repositories/
│   │   │       └── settings_repository.dart
│   │   ├── domain/
│   │   │   └── use_cases/
│   │   │       ├── update_settings_use_case.dart
│   │   │       └── get_settings_use_case.dart
│   │   ├── presentation/
│   │   │   ├── screens/
│   │   │   │   ├── settings_screen.dart
│   │   │   │   ├── account_management_screen.dart
│   │   │   │   ├── privacy_settings_screen.dart
│   │   │   │   ├── notification_settings_screen.dart
│   │   │   │   ├── safety_settings_screen.dart
│   │   │   │   ├── accessibility_settings_screen.dart
│   │   │   │   ├── two_factor_auth_screen.dart
│   │   │   │   └── active_sessions_screen.dart
│   │   │   └── widgets/
│   │   │       └── settings_tile.dart
│   │   └── providers/
│   │       └── settings_provider.dart
│   │
│   ├── safety/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   ├── report.dart
│   │   │   │   ├── block.dart
│   │   │   │   └── emergency_contact.dart
│   │   │   └── repositories/
│   │   │       └── safety_repository.dart
│   │   ├── domain/
│   │   │   └── use_cases/
│   │   │       ├── report_user_use_case.dart
│   │   │       ├── block_user_use_case.dart
│   │   │       └── add_emergency_contact_use_case.dart
│   │   ├── presentation/
│   │   │   ├── screens/
│   │   │   │   ├── safety_center_screen.dart
│   │   │   │   ├── report_user_screen.dart
│   │   │   │   ├── blocked_users_screen.dart
│   │   │   │   ├── emergency_contacts_screen.dart
│   │   │   │   └── report_history_screen.dart
│   │   │   └── widgets/
│   │   │       └── report_category_tile.dart
│   │   └── providers/
│   │       └── safety_provider.dart
│   │
│   ├── feed/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   └── feed_post.dart
│   │   │   └── repositories/
│   │   │       └── feed_repository.dart
│   │   ├── domain/
│   │   │   └── use_cases/
│   │   │       ├── get_feed_use_case.dart
│   │   │       └── create_post_use_case.dart
│   │   ├── presentation/
│   │   │   ├── screens/
│   │   │   │   └── feed_screen.dart
│   │   │   └── widgets/
│   │   │       ├── feed_post_card.dart
│   │   │       └── feed_comment_section.dart
│   │   └── providers/
│   │       └── feed_provider.dart
│   │
│   └── analytics/
│       ├── data/
│       │   ├── models/
│       │   │   └── user_analytics.dart
│       │   └── repositories/
│       │       └── analytics_repository.dart
│       ├── domain/
│       │   └── use_cases/
│       │       └── get_analytics_use_case.dart
│       ├── presentation/
│       │   ├── screens/
│       │   │   └── analytics_screen.dart
│       │   └── widgets/
│       │       └── analytics_chart.dart
│       └── providers/
│           └── analytics_provider.dart
│
├── shared/
│   ├── models/
│   │   ├── api_response.dart
│   │   ├── api_error.dart
│   │   └── pagination.dart
│   ├── services/
│   │   ├── api_service.dart
│   │   ├── storage_service.dart
│   │   ├── websocket_service.dart
│   │   └── notification_service.dart
│   └── widgets/
│       ├── error_widget.dart
│       └── loading_widget.dart
│
├── routes/
│   ├── app_router.dart
│   ├── route_names.dart
│   └── route_guards.dart
│
└── main.dart
```

## 📋 File Creation Checklist

### Core Files
- [x] Theme files (app_theme.dart, app_colors.dart, typography.dart)
- [x] Constants (api_endpoints.dart, app_constants.dart, animation_constants.dart)
- [x] Utils (validators.dart, formatters.dart, error_handler.dart)
- [x] Reusable widgets (avatar_ring.dart, discovery_card.dart, etc.)

### Feature Files
- [ ] Auth screens and providers
- [ ] Onboarding screens
- [ ] Profile screens and widgets
- [ ] Discovery screens and widgets
- [ ] Matching screens and widgets
- [ ] Chat screens and widgets
- [ ] Calls screens and widgets
- [ ] Stories screens and widgets
- [ ] Notifications screens
- [ ] Payments screens and widgets
- [ ] Settings screens
- [ ] Safety screens
- [ ] Feed screens
- [ ] Analytics screens

### Shared Files
- [ ] API service
- [ ] Storage service
- [ ] WebSocket service
- [ ] Notification service
- [ ] Router configuration

---

**Note**: This structure follows Clean Architecture principles with clear separation of concerns:
- **data**: Models and repositories (API layer)
- **domain**: Use cases (business logic)
- **presentation**: Screens and widgets (UI layer)
- **providers**: State management (Riverpod)

