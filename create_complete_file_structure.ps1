# Complete file generation script for all Flutter files
$basePath = "flutter_app_structure/lib"

function Get-FileName {
    param([string]$Path)
    $name = Split-Path -Leaf $Path
    $name = $name -replace '\.dart$', ''
    $name = $name -replace '_', ''
    $parts = $name -split '-'
    $className = ($parts | ForEach-Object { 
        $_.Substring(0,1).ToUpper() + $_.Substring(1) 
    }) -join ''
    return $className
}

function Create-File {
    param(
        [string]$FilePath,
        [string]$Type,
        [string]$Name
    )
    
    $directory = Split-Path -Parent $FilePath
    if (-not (Test-Path $directory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }
    
    if (Test-Path $FilePath) {
        Write-Host "Skipping existing: $FilePath"
        return
    }
    
    $content = switch ($Type) {
        "model" {
            $className = if ($Name) { $Name } else { (Get-FileName $FilePath) }
            @"
// Model: $className
class $className {
  // TODO: Add properties and fromJson/toJson methods
  
  $className();
  
  factory $className.fromJson(Map<String, dynamic> json) {
    return $className();
  }
  
  Map<String, dynamic> toJson() {
    return {};
  }
}
"@
        }
        "repository" {
            $className = if ($Name) { $Name } else { (Get-FileName $FilePath) }
            @"
// Repository: $className
class $className {
  // TODO: Implement repository methods
  
  Future<dynamic> getData() async {
    // TODO: Implement
    throw UnimplementedError();
  }
}
"@
        }
        "usecase" {
            $className = if ($Name) { $Name } else { (Get-FileName $FilePath) }
            @"
// Use Case: $className
class $className {
  // TODO: Implement use case
  
  Future<dynamic> execute() async {
    // TODO: Implement
    throw UnimplementedError();
  }
}
"@
        }
        "screen" {
            $className = if ($Name) { $Name } else { (Get-FileName $FilePath) }
            @"
// Screen: $className
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class $className extends ConsumerStatefulWidget {
  const $className({Key? key}) : super(key: key);

  @override
  ConsumerState<$className> createState() => _${className}State();
}

class _${className}State extends ConsumerState<$className> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('$className'),
      ),
      body: const Center(
        child: Text('$className Screen'),
      ),
    );
  }
}
"@
        }
        "widget" {
            $className = if ($Name) { $Name } else { (Get-FileName $FilePath) }
            @"
// Widget: $className
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class $className extends ConsumerWidget {
  const $className({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      // TODO: Implement widget
    );
  }
}
"@
        }
        "provider" {
            $className = if ($Name) { $Name } else { (Get-FileName $FilePath) }
            @"
// Provider: $className
import 'package:flutter_riverpod/flutter_riverpod.dart';

final ${className}Provider = StateNotifierProvider<${className}Notifier, ${className}State>((ref) {
  return ${className}Notifier();
});

class ${className}State {
  // TODO: Add state properties
}

class ${className}Notifier extends StateNotifier<${className}State> {
  ${className}Notifier() : super(${className}State());
  
  // TODO: Implement state management methods
}
"@
        }
    }
    
    Set-Content -Path $FilePath -Value $content -Encoding UTF8
    Write-Host "Created: $FilePath"
}

# Define all files to create
$allFiles = @(
    # Onboarding
    @{Path="features/onboarding/presentation/screens/onboarding_screen.dart"; Type="screen"},
    @{Path="features/onboarding/presentation/screens/onboarding_preferences_screen.dart"; Type="screen"},
    @{Path="features/onboarding/presentation/screens/enhanced_onboarding_screen.dart"; Type="screen"},
    @{Path="features/onboarding/presentation/widgets/onboarding_page_view.dart"; Type="widget"},
    @{Path="features/onboarding/presentation/widgets/onboarding_page.dart"; Type="widget"},
    @{Path="features/onboarding/providers/onboarding_provider.dart"; Type="provider"},
    
    # Profile
    @{Path="features/profile/data/models/user_profile.dart"; Type="model"},
    @{Path="features/profile/data/models/profile_completion.dart"; Type="model"},
    @{Path="features/profile/data/models/user_preferences.dart"; Type="model"},
    @{Path="features/profile/data/models/user_image.dart"; Type="model"},
    @{Path="features/profile/data/models/profile_verification.dart"; Type="model"},
    @{Path="features/profile/data/repositories/profile_repository.dart"; Type="repository"},
    @{Path="features/profile/domain/use_cases/get_profile_use_case.dart"; Type="usecase"},
    @{Path="features/profile/domain/use_cases/update_profile_use_case.dart"; Type="usecase"},
    @{Path="features/profile/domain/use_cases/upload_image_use_case.dart"; Type="usecase"},
    @{Path="features/profile/domain/use_cases/delete_image_use_case.dart"; Type="usecase"},
    @{Path="features/profile/domain/use_cases/complete_profile_use_case.dart"; Type="usecase"},
    @{Path="features/profile/domain/use_cases/verify_profile_use_case.dart"; Type="usecase"},
    @{Path="features/profile/presentation/screens/profile_screen.dart"; Type="screen"},
    @{Path="features/profile/presentation/screens/profile_edit_screen.dart"; Type="screen"},
    @{Path="features/profile/presentation/screens/profile_detail_screen.dart"; Type="screen"},
    @{Path="features/profile/presentation/screens/profile_wizard_screen.dart"; Type="screen"},
    @{Path="features/profile/presentation/screens/profile_completion_screen.dart"; Type="screen"},
    @{Path="features/profile/presentation/screens/profile_verification_screen.dart"; Type="screen"},
    @{Path="features/profile/presentation/screens/profile_analytics_screen.dart"; Type="screen"},
    @{Path="features/profile/presentation/screens/profile_sharing_screen.dart"; Type="screen"},
    @{Path="features/profile/presentation/widgets/profile_image_picker.dart"; Type="widget"},
    @{Path="features/profile/presentation/widgets/profile_stats_row.dart"; Type="widget"},
    @{Path="features/profile/presentation/widgets/interest_chip_list.dart"; Type="widget"},
    @{Path="features/profile/presentation/widgets/profile_image_carousel.dart"; Type="widget"},
    @{Path="features/profile/presentation/widgets/profile_bio_section.dart"; Type="widget"},
    @{Path="features/profile/providers/profile_provider.dart"; Type="provider"},
    
    # Discover
    @{Path="features/discover/data/models/discovery_profile.dart"; Type="model"},
    @{Path="features/discover/data/models/discovery_filters.dart"; Type="model"},
    @{Path="features/discover/data/models/age_preference.dart"; Type="model"},
    @{Path="features/discover/data/repositories/discovery_repository.dart"; Type="repository"},
    @{Path="features/discover/domain/use_cases/get_discovery_profiles_use_case.dart"; Type="usecase"},
    @{Path="features/discover/domain/use_cases/apply_filters_use_case.dart"; Type="usecase"},
    @{Path="features/discover/domain/use_cases/get_nearby_suggestions_use_case.dart"; Type="usecase"},
    @{Path="features/discover/presentation/screens/discover_screen.dart"; Type="screen"},
    @{Path="features/discover/presentation/screens/explore_screen.dart"; Type="screen"},
    @{Path="features/discover/presentation/screens/filter_screen.dart"; Type="screen"},
    @{Path="features/discover/presentation/screens/profile_detail_screen.dart"; Type="screen"},
    @{Path="features/discover/presentation/screens/likes_received_screen.dart"; Type="screen"},
    @{Path="features/discover/presentation/widgets/swipeable_card_stack.dart"; Type="widget"},
    @{Path="features/discover/presentation/widgets/profile_card.dart"; Type="widget"},
    @{Path="features/discover/presentation/widgets/filter_chip.dart"; Type="widget"},
    @{Path="features/discover/presentation/widgets/action_buttons_row.dart"; Type="widget"},
    @{Path="features/discover/providers/discovery_provider.dart"; Type="provider"},
    
    # Matching
    @{Path="features/matching/data/models/match.dart"; Type="model"},
    @{Path="features/matching/data/models/like.dart"; Type="model"},
    @{Path="features/matching/data/models/superlike.dart"; Type="model"},
    @{Path="features/matching/data/models/compatibility_score.dart"; Type="model"},
    @{Path="features/matching/data/repositories/matching_repository.dart"; Type="repository"},
    @{Path="features/matching/domain/use_cases/like_profile_use_case.dart"; Type="usecase"},
    @{Path="features/matching/domain/use_cases/superlike_profile_use_case.dart"; Type="usecase"},
    @{Path="features/matching/domain/use_cases/get_matches_use_case.dart"; Type="usecase"},
    @{Path="features/matching/domain/use_cases/get_compatibility_score_use_case.dart"; Type="usecase"},
    @{Path="features/matching/presentation/screens/matches_screen.dart"; Type="screen"},
    @{Path="features/matching/presentation/screens/match_screen.dart"; Type="screen"},
    @{Path="features/matching/presentation/screens/likes_screen.dart"; Type="screen"},
    @{Path="features/matching/presentation/widgets/match_card.dart"; Type="widget"},
    @{Path="features/matching/presentation/widgets/match_celebration.dart"; Type="widget"},
    @{Path="features/matching/presentation/widgets/like_button.dart"; Type="widget"},
    @{Path="features/matching/presentation/widgets/superlike_button.dart"; Type="widget"},
    @{Path="features/matching/providers/matching_provider.dart"; Type="provider"},
    
    # Chat
    @{Path="features/chat/data/models/message.dart"; Type="model"},
    @{Path="features/chat/data/models/chat.dart"; Type="model"},
    @{Path="features/chat/data/models/chat_participant.dart"; Type="model"},
    @{Path="features/chat/data/models/message_attachment.dart"; Type="model"},
    @{Path="features/chat/data/repositories/chat_repository.dart"; Type="repository"},
    @{Path="features/chat/domain/use_cases/send_message_use_case.dart"; Type="usecase"},
    @{Path="features/chat/domain/use_cases/get_chat_history_use_case.dart"; Type="usecase"},
    @{Path="features/chat/domain/use_cases/mark_as_read_use_case.dart"; Type="usecase"},
    @{Path="features/chat/domain/use_cases/delete_message_use_case.dart"; Type="usecase"},
    @{Path="features/chat/domain/use_cases/set_typing_use_case.dart"; Type="usecase"},
    @{Path="features/chat/presentation/screens/chats_screen.dart"; Type="screen"},
    @{Path="features/chat/presentation/screens/chat_screen.dart"; Type="screen"},
    @{Path="features/chat/presentation/screens/group_chat_screen.dart"; Type="screen"},
    @{Path="features/chat/presentation/screens/message_search_screen.dart"; Type="screen"},
    @{Path="features/chat/presentation/widgets/message_bubble.dart"; Type="widget"},
    @{Path="features/chat/presentation/widgets/chat_input.dart"; Type="widget"},
    @{Path="features/chat/presentation/widgets/typing_indicator.dart"; Type="widget"},
    @{Path="features/chat/presentation/widgets/message_attachment_viewer.dart"; Type="widget"},
    @{Path="features/chat/presentation/widgets/online_friends_list.dart"; Type="widget"},
    @{Path="features/chat/providers/chat_provider.dart"; Type="provider"},
    
    # Calls
    @{Path="features/calls/data/models/call.dart"; Type="model"},
    @{Path="features/calls/data/models/call_settings.dart"; Type="model"},
    @{Path="features/calls/data/repositories/call_repository.dart"; Type="repository"},
    @{Path="features/calls/domain/use_cases/initiate_call_use_case.dart"; Type="usecase"},
    @{Path="features/calls/domain/use_cases/accept_call_use_case.dart"; Type="usecase"},
    @{Path="features/calls/domain/use_cases/end_call_use_case.dart"; Type="usecase"},
    @{Path="features/calls/domain/use_cases/get_call_history_use_case.dart"; Type="usecase"},
    @{Path="features/calls/presentation/screens/voice_call_screen.dart"; Type="screen"},
    @{Path="features/calls/presentation/screens/video_call_screen.dart"; Type="screen"},
    @{Path="features/calls/presentation/screens/call_history_screen.dart"; Type="screen"},
    @{Path="features/calls/presentation/widgets/call_button.dart"; Type="widget"},
    @{Path="features/calls/presentation/widgets/call_controls.dart"; Type="widget"},
    @{Path="features/calls/presentation/widgets/call_timer.dart"; Type="widget"},
    @{Path="features/calls/providers/call_provider.dart"; Type="provider"},
    
    # Stories
    @{Path="features/stories/data/models/story.dart"; Type="model"},
    @{Path="features/stories/data/models/story_reply.dart"; Type="model"},
    @{Path="features/stories/data/repositories/story_repository.dart"; Type="repository"},
    @{Path="features/stories/domain/use_cases/get_stories_use_case.dart"; Type="usecase"},
    @{Path="features/stories/domain/use_cases/create_story_use_case.dart"; Type="usecase"},
    @{Path="features/stories/domain/use_cases/view_story_use_case.dart"; Type="usecase"},
    @{Path="features/stories/domain/use_cases/reply_to_story_use_case.dart"; Type="usecase"},
    @{Path="features/stories/presentation/screens/story_viewing_screen.dart"; Type="screen"},
    @{Path="features/stories/presentation/screens/story_creation_screen.dart"; Type="screen"},
    @{Path="features/stories/presentation/widgets/story_viewer.dart"; Type="widget"},
    @{Path="features/stories/presentation/widgets/story_ring.dart"; Type="widget"},
    @{Path="features/stories/presentation/widgets/story_progress_bar.dart"; Type="widget"},
    @{Path="features/stories/providers/story_provider.dart"; Type="provider"},
    
    # Notifications
    @{Path="features/notifications/data/models/notification.dart"; Type="model"},
    @{Path="features/notifications/data/models/notification_preferences.dart"; Type="model"},
    @{Path="features/notifications/data/repositories/notification_repository.dart"; Type="repository"},
    @{Path="features/notifications/domain/use_cases/get_notifications_use_case.dart"; Type="usecase"},
    @{Path="features/notifications/domain/use_cases/mark_as_read_use_case.dart"; Type="usecase"},
    @{Path="features/notifications/domain/use_cases/delete_notification_use_case.dart"; Type="usecase"},
    @{Path="features/notifications/domain/use_cases/update_preferences_use_case.dart"; Type="usecase"},
    @{Path="features/notifications/presentation/screens/notifications_screen.dart"; Type="screen"},
    @{Path="features/notifications/presentation/screens/notification_settings_screen.dart"; Type="screen"},
    @{Path="features/notifications/presentation/widgets/notification_tile.dart"; Type="widget"},
    @{Path="features/notifications/presentation/widgets/notification_badge.dart"; Type="widget"},
    @{Path="features/notifications/providers/notification_provider.dart"; Type="provider"},
    
    # Payments
    @{Path="features/payments/data/models/subscription_plan.dart"; Type="model"},
    @{Path="features/payments/data/models/superlike_pack.dart"; Type="model"},
    @{Path="features/payments/data/models/payment_history.dart"; Type="model"},
    @{Path="features/payments/data/models/payment_method.dart"; Type="model"},
    @{Path="features/payments/data/repositories/payment_repository.dart"; Type="repository"},
    @{Path="features/payments/domain/use_cases/purchase_subscription_use_case.dart"; Type="usecase"},
    @{Path="features/payments/domain/use_cases/purchase_superlike_pack_use_case.dart"; Type="usecase"},
    @{Path="features/payments/domain/use_cases/get_payment_history_use_case.dart"; Type="usecase"},
    @{Path="features/payments/domain/use_cases/cancel_subscription_use_case.dart"; Type="usecase"},
    @{Path="features/payments/domain/use_cases/upgrade_subscription_use_case.dart"; Type="usecase"},
    @{Path="features/payments/presentation/screens/subscription_plans_screen.dart"; Type="screen"},
    @{Path="features/payments/presentation/screens/premium_subscription_screen.dart"; Type="screen"},
    @{Path="features/payments/presentation/screens/superlike_packs_screen.dart"; Type="screen"},
    @{Path="features/payments/presentation/screens/subscription_management_screen.dart"; Type="screen"},
    @{Path="features/payments/presentation/screens/payment_methods_screen.dart"; Type="screen"},
    @{Path="features/payments/presentation/screens/payment_history_screen.dart"; Type="screen"},
    @{Path="features/payments/presentation/screens/payment_screen.dart"; Type="screen"},
    @{Path="features/payments/presentation/widgets/plan_card.dart"; Type="widget"},
    @{Path="features/payments/presentation/widgets/payment_method_tile.dart"; Type="widget"},
    @{Path="features/payments/presentation/widgets/subscription_status_card.dart"; Type="widget"},
    @{Path="features/payments/providers/payment_provider.dart"; Type="provider"},
    
    # Settings
    @{Path="features/settings/data/models/user_settings.dart"; Type="model"},
    @{Path="features/settings/data/models/privacy_settings.dart"; Type="model"},
    @{Path="features/settings/data/models/device_session.dart"; Type="model"},
    @{Path="features/settings/data/repositories/settings_repository.dart"; Type="repository"},
    @{Path="features/settings/domain/use_cases/update_settings_use_case.dart"; Type="usecase"},
    @{Path="features/settings/domain/use_cases/get_settings_use_case.dart"; Type="usecase"},
    @{Path="features/settings/domain/use_cases/change_password_use_case.dart"; Type="usecase"},
    @{Path="features/settings/domain/use_cases/delete_account_use_case.dart"; Type="usecase"},
    @{Path="features/settings/presentation/screens/settings_screen.dart"; Type="screen"},
    @{Path="features/settings/presentation/screens/account_management_screen.dart"; Type="screen"},
    @{Path="features/settings/presentation/screens/privacy_settings_screen.dart"; Type="screen"},
    @{Path="features/settings/presentation/screens/notification_settings_screen.dart"; Type="screen"},
    @{Path="features/settings/presentation/screens/safety_settings_screen.dart"; Type="screen"},
    @{Path="features/settings/presentation/screens/accessibility_settings_screen.dart"; Type="screen"},
    @{Path="features/settings/presentation/screens/two_factor_auth_screen.dart"; Type="screen"},
    @{Path="features/settings/presentation/screens/active_sessions_screen.dart"; Type="screen"},
    @{Path="features/settings/presentation/widgets/settings_tile.dart"; Type="widget"},
    @{Path="features/settings/presentation/widgets/settings_section.dart"; Type="widget"},
    @{Path="features/settings/presentation/widgets/switch_tile.dart"; Type="widget"},
    @{Path="features/settings/providers/settings_provider.dart"; Type="provider"},
    
    # Safety
    @{Path="features/safety/data/models/report.dart"; Type="model"},
    @{Path="features/safety/data/models/block.dart"; Type="model"},
    @{Path="features/safety/data/models/emergency_contact.dart"; Type="model"},
    @{Path="features/safety/data/repositories/safety_repository.dart"; Type="repository"},
    @{Path="features/safety/domain/use_cases/report_user_use_case.dart"; Type="usecase"},
    @{Path="features/safety/domain/use_cases/block_user_use_case.dart"; Type="usecase"},
    @{Path="features/safety/domain/use_cases/unblock_user_use_case.dart"; Type="usecase"},
    @{Path="features/safety/domain/use_cases/add_emergency_contact_use_case.dart"; Type="usecase"},
    @{Path="features/safety/presentation/screens/safety_center_screen.dart"; Type="screen"},
    @{Path="features/safety/presentation/screens/report_user_screen.dart"; Type="screen"},
    @{Path="features/safety/presentation/screens/blocked_users_screen.dart"; Type="screen"},
    @{Path="features/safety/presentation/screens/emergency_contacts_screen.dart"; Type="screen"},
    @{Path="features/safety/presentation/screens/report_history_screen.dart"; Type="screen"},
    @{Path="features/safety/presentation/widgets/report_category_tile.dart"; Type="widget"},
    @{Path="features/safety/presentation/widgets/block_user_dialog.dart"; Type="widget"},
    @{Path="features/safety/providers/safety_provider.dart"; Type="provider"},
    
    # Feed
    @{Path="features/feed/data/models/feed_post.dart"; Type="model"},
    @{Path="features/feed/data/models/feed_comment.dart"; Type="model"},
    @{Path="features/feed/data/models/feed_reaction.dart"; Type="model"},
    @{Path="features/feed/data/repositories/feed_repository.dart"; Type="repository"},
    @{Path="features/feed/domain/use_cases/get_feed_use_case.dart"; Type="usecase"},
    @{Path="features/feed/domain/use_cases/create_post_use_case.dart"; Type="usecase"},
    @{Path="features/feed/domain/use_cases/like_post_use_case.dart"; Type="usecase"},
    @{Path="features/feed/domain/use_cases/comment_on_post_use_case.dart"; Type="usecase"},
    @{Path="features/feed/presentation/screens/feed_screen.dart"; Type="screen"},
    @{Path="features/feed/presentation/widgets/feed_post_card.dart"; Type="widget"},
    @{Path="features/feed/presentation/widgets/feed_comment_section.dart"; Type="widget"},
    @{Path="features/feed/presentation/widgets/feed_reaction_bar.dart"; Type="widget"},
    @{Path="features/feed/providers/feed_provider.dart"; Type="provider"},
    
    # Analytics
    @{Path="features/analytics/data/models/user_analytics.dart"; Type="model"},
    @{Path="features/analytics/data/repositories/analytics_repository.dart"; Type="repository"},
    @{Path="features/analytics/domain/use_cases/get_analytics_use_case.dart"; Type="usecase"},
    @{Path="features/analytics/domain/use_cases/track_activity_use_case.dart"; Type="usecase"},
    @{Path="features/analytics/presentation/screens/analytics_screen.dart"; Type="screen"},
    @{Path="features/analytics/presentation/widgets/analytics_chart.dart"; Type="widget"},
    @{Path="features/analytics/presentation/widgets/analytics_card.dart"; Type="widget"},
    @{Path="features/analytics/providers/analytics_provider.dart"; Type="provider"}
)

Write-Host "Creating all feature files..."
$count = 0
foreach ($file in $allFiles) {
    Create-File -FilePath "$basePath/$($file.Path)" -Type $file.Type
    $count++
    if ($count % 50 -eq 0) {
        Write-Host "Created $count files..."
    }
}

Write-Host "Total files created: $count"
Write-Host "All feature files created successfully!"

