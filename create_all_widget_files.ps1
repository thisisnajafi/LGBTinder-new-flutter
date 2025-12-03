# PowerShell script to create all widget files for LGBTinder app
$basePath = "lib/widgets"

function Create-WidgetFile {
    param(
        [string]$FilePath,
        [string]$ClassName,
        [string]$Description,
        [string]$Type = "widget"  # "widget", "stateless", "stateful"
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
        "stateless" {
            @"
// Widget: $ClassName
// $Description
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// $Description
class $ClassName extends ConsumerStatelessWidget {
  const $ClassName({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      // TODO: Implement widget
    );
  }
}
"@
        }
        "stateful" {
            @"
// Widget: $ClassName
// $Description
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// $Description
class $ClassName extends ConsumerStatefulWidget {
  const $ClassName({Key? key}) : super(key: key);

  @override
  ConsumerState<$ClassName> createState() => _${ClassName}State();
}

class _${ClassName}State extends ConsumerState<$ClassName> {
  @override
  Widget build(BuildContext context) {
    return Container(
      // TODO: Implement widget
    );
  }
}
"@
        }
        default {
            @"
// Widget: $ClassName
// $Description
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// $Description
class $ClassName extends ConsumerWidget {
  const $ClassName({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      // TODO: Implement widget
    );
  }
}
"@
        }
    }
    
    Set-Content -Path $FilePath -Value $content -Encoding UTF8
    Write-Host "Created: $FilePath"
}

# Core Widgets (already created, but listing for reference)
Write-Host "Core widgets already exist in lib/core/widgets/"

# Chat Widgets
Write-Host "`nCreating Chat widgets..."
$chatWidgets = @(
    @{Path="chat/audio_player_widget.dart"; Class="AudioPlayerWidget"; Desc="Audio message player with controls"; Type="stateful"},
    @{Path="chat/audio_recorder_widget.dart"; Class="AudioRecorderWidget"; Desc="Audio recorder for voice messages"; Type="stateful"},
    @{Path="chat/chat_header.dart"; Class="ChatHeader"; Desc="Chat screen header with user info"; Type="widget"},
    @{Path="chat/chat_list_empty.dart"; Class="ChatListEmpty"; Desc="Empty state for chat list"; Type="widget"},
    @{Path="chat/chat_list_header.dart"; Class="ChatListHeader"; Desc="Header for chat list with search"; Type="widget"},
    @{Path="chat/chat_list_item.dart"; Class="ChatListItem"; Desc="Individual chat list item"; Type="widget"},
    @{Path="chat/chat_list_loading.dart"; Class="ChatListLoading"; Desc="Loading state for chat list"; Type="widget"},
    @{Path="chat/emoji_picker_widget.dart"; Class="EmojiPickerWidget"; Desc="Emoji picker for messages"; Type="stateful"},
    @{Path="chat/last_seen_widget.dart"; Class="LastSeenWidget"; Desc="Last seen timestamp widget"; Type="widget"},
    @{Path="chat/media_picker_bottom_sheet.dart"; Class="MediaPickerBottomSheet"; Desc="Bottom sheet for media selection"; Type="widget"},
    @{Path="chat/media_picker.dart"; Class="MediaPicker"; Desc="Media picker component"; Type="stateful"},
    @{Path="chat/media_viewer.dart"; Class="MediaViewer"; Desc="Full-screen media viewer"; Type="stateful"},
    @{Path="chat/mention_input_field.dart"; Class="MentionInputField"; Desc="Text input with mention support"; Type="stateful"},
    @{Path="chat/mention_text_widget.dart"; Class="MentionTextWidget"; Desc="Text widget with mention highlighting"; Type="widget"},
    @{Path="chat/message_bubble.dart"; Class="MessageBubble"; Desc="Chat message bubble"; Type="widget"},
    @{Path="chat/message_input.dart"; Class="MessageInput"; Desc="Message input field with actions"; Type="stateful"},
    @{Path="chat/message_reaction_bar.dart"; Class="MessageReactionBar"; Desc="Message reaction emoji bar"; Type="widget"},
    @{Path="chat/message_reply_widget.dart"; Class="MessageReplyWidget"; Desc="Message reply preview widget"; Type="widget"},
    @{Path="chat/message_status_indicator.dart"; Class="MessageStatusIndicator"; Desc="Message read/sent status"; Type="widget"},
    @{Path="chat/pinned_messages_banner.dart"; Class="PinnedMessagesBanner"; Desc="Banner for pinned messages"; Type="widget"},
    @{Path="chat/typing_indicator.dart"; Class="TypingIndicator"; Desc="Animated typing indicator"; Type="stateful"},
    @{Path="chat/upload_progress_indicator.dart"; Class="UploadProgressIndicator"; Desc="File upload progress"; Type="widget"}
)

foreach ($widget in $chatWidgets) {
    Create-WidgetFile -FilePath "$basePath/$($widget.Path)" -ClassName $widget.Class -Description $widget.Desc -Type $widget.Type
}

# Profile Widgets
Write-Host "`nCreating Profile widgets..."
$profileWidgets = @(
    @{Path="profile/avatar_upload.dart"; Class="AvatarUpload"; Desc="Avatar upload widget"; Type="stateful"},
    @{Path="profile/customizable_profile_widget.dart"; Class="CustomizableProfileWidget"; Desc="Customizable profile display"; Type="widget"},
    @{Path="profile/edit_profile.dart"; Class="EditProfile"; Desc="Profile editing widget"; Type="stateful"},
    @{Path="profile/photo_gallery.dart"; Class="PhotoGallery"; Desc="Profile photo gallery"; Type="stateful"},
    @{Path="profile/profile_action_buttons.dart"; Class="ProfileActionButtons"; Desc="Profile action buttons row"; Type="widget"},
    @{Path="profile/profile_bio.dart"; Class="ProfileBio"; Desc="Profile bio section"; Type="widget"},
    @{Path="profile/profile_header.dart"; Class="ProfileHeader"; Desc="Profile header with avatar and name"; Type="widget"},
    @{Path="profile/profile_info_sections.dart"; Class="ProfileInfoSections"; Desc="Profile information sections"; Type="widget"},
    @{Path="profile/profile_settings.dart"; Class="ProfileSettings"; Desc="Profile settings widget"; Type="widget"},
    @{Path="profile/safety_verification_section.dart"; Class="SafetyVerificationSection"; Desc="Safety verification section"; Type="widget"},
    @{Path="profile/edit/profile_image_editor.dart"; Class="ProfileImageEditor"; Desc="Profile image editing"; Type="stateful"},
    @{Path="profile/edit/profile_field_editor.dart"; Class="ProfileFieldEditor"; Desc="Profile field editor"; Type="stateful"},
    @{Path="profile/edit/profile_section_editor.dart"; Class="ProfileSectionEditor"; Desc="Profile section editor"; Type="stateful"}
)

foreach ($widget in $profileWidgets) {
    Create-WidgetFile -FilePath "$basePath/$($widget.Path)" -ClassName $widget.Class -Description $widget.Desc -Type $widget.Type
}

# Profile Cards Widgets
Write-Host "`nCreating Profile Cards widgets..."
$profileCardWidgets = @(
    @{Path="profile_cards/match_card.dart"; Class="MatchCard"; Desc="Match display card"; Type="widget"},
    @{Path="profile_cards/profile_completion_bar.dart"; Class="ProfileCompletionBar"; Desc="Profile completion progress bar"; Type="widget"},
    @{Path="profile_cards/swipeable_profile_card.dart"; Class="SwipeableProfileCard"; Desc="Swipeable profile card"; Type="stateful"}
)

foreach ($widget in $profileCardWidgets) {
    Create-WidgetFile -FilePath "$basePath/$($widget.Path)" -ClassName $widget.Class -Description $widget.Desc -Type $widget.Type
}

# Match Interaction Widgets
Write-Host "`nCreating Match Interaction widgets..."
$matchWidgets = @(
    @{Path="match_interaction/action_buttons.dart"; Class="ActionButtons"; Desc="Swipe action buttons"; Type="widget"},
    @{Path="match_interaction/animated_snackbar.dart"; Class="AnimatedSnackbar"; Desc="Animated snackbar notifications"; Type="widget"},
    @{Path="match_interaction/loading_indicator.dart"; Class="LoadingIndicator"; Desc="Loading indicator for matches"; Type="widget"},
    @{Path="match_interaction/match_indicator.dart"; Class="MatchIndicator"; Desc="Match percentage indicator"; Type="widget"}
)

foreach ($widget in $matchWidgets) {
    Create-WidgetFile -FilePath "$basePath/$($widget.Path)" -ClassName $widget.Class -Description $widget.Desc -Type $widget.Type
}

# Cards Widgets
Write-Host "`nCreating Cards widgets..."
$cardWidgets = @(
    @{Path="cards/card_preview_widget.dart"; Class="CardPreviewWidget"; Desc="Card preview widget"; Type="widget"},
    @{Path="cards/card_stack_manager.dart"; Class="CardStackManager"; Desc="Card stack manager"; Type="stateful"},
    @{Path="cards/swipeable_card.dart"; Class="SwipeableCard"; Desc="Swipeable card component"; Type="stateful"}
)

foreach ($widget in $cardWidgets) {
    Create-WidgetFile -FilePath "$basePath/$($widget.Path)" -ClassName $widget.Class -Description $widget.Desc -Type $widget.Type
}

# Buttons Widgets
Write-Host "`nCreating Buttons widgets..."
$buttonWidgets = @(
    @{Path="buttons/accessible_button.dart"; Class="AccessibleButton"; Desc="Accessible button widget"; Type="widget"},
    @{Path="buttons/animated_button.dart"; Class="AnimatedButton"; Desc="Animated button with effects"; Type="stateful"},
    @{Path="buttons/optimized_button.dart"; Class="OptimizedButton"; Desc="Optimized button widget"; Type="widget"},
    @{Path="buttons/gradient_button.dart"; Class="GradientButton"; Desc="Gradient button"; Type="widget"},
    @{Path="buttons/icon_button_circle.dart"; Class="IconButtonCircle"; Desc="Circular icon button"; Type="widget"},
    @{Path="buttons/like_button.dart"; Class="LikeButton"; Desc="Like action button"; Type="stateful"},
    @{Path="buttons/superlike_button.dart"; Class="SuperlikeButton"; Desc="Superlike action button"; Type="stateful"},
    @{Path="buttons/dislike_button.dart"; Class="DislikeButton"; Desc="Dislike action button"; Type="stateful"}
)

foreach ($widget in $buttonWidgets) {
    Create-WidgetFile -FilePath "$basePath/$($widget.Path)" -ClassName $widget.Class -Description $widget.Desc -Type $widget.Type
}

# Badges Widgets
Write-Host "`nCreating Badges widgets..."
$badgeWidgets = @(
    @{Path="badges/notification_badge.dart"; Class="NotificationBadge"; Desc="Notification count badge"; Type="widget"},
    @{Path="badges/verification_badge.dart"; Class="VerificationBadge"; Desc="User verification badge"; Type="widget"},
    @{Path="badges/online_badge.dart"; Class="OnlineBadge"; Desc="Online status badge"; Type="widget"},
    @{Path="badges/premium_badge.dart"; Class="PremiumBadge"; Desc="Premium user badge"; Type="widget"},
    @{Path="badges/unread_badge.dart"; Class="UnreadBadge"; Desc="Unread message badge"; Type="widget"}
)

foreach ($widget in $badgeWidgets) {
    Create-WidgetFile -FilePath "$basePath/$($widget.Path)" -ClassName $widget.Class -Description $widget.Desc -Type $widget.Type
}

# Avatar Widgets
Write-Host "`nCreating Avatar widgets..."
$avatarWidgets = @(
    @{Path="avatar/animated_avatar.dart"; Class="AnimatedAvatar"; Desc="Animated avatar widget"; Type="stateful"},
    @{Path="avatar/avatar_with_ring.dart"; Class="AvatarWithRing"; Desc="Avatar with gradient ring"; Type="widget"},
    @{Path="avatar/avatar_with_status.dart"; Class="AvatarWithStatus"; Desc="Avatar with online status"; Type="widget"},
    @{Path="avatar/story_avatar.dart"; Class="StoryAvatar"; Desc="Avatar for stories"; Type="widget"}
)

foreach ($widget in $avatarWidgets) {
    Create-WidgetFile -FilePath "$basePath/$($widget.Path)" -ClassName $widget.Class -Description $widget.Desc -Type $widget.Type
}

# Images Widgets
Write-Host "`nCreating Images widgets..."
$imageWidgets = @(
    @{Path="images/optimized_image.dart"; Class="OptimizedImage"; Desc="Optimized image loader"; Type="widget"},
    @{Path="images/profile_image_editor.dart"; Class="ProfileImageEditor"; Desc="Profile image editor"; Type="stateful"},
    @{Path="images/image_carousel.dart"; Class="ImageCarousel"; Desc="Image carousel viewer"; Type="stateful"},
    @{Path="images/image_picker_widget.dart"; Class="ImagePickerWidget"; Desc="Image picker widget"; Type="stateful"}
)

foreach ($widget in $imageWidgets) {
    Create-WidgetFile -FilePath "$basePath/$($widget.Path)" -ClassName $widget.Class -Description $widget.Desc -Type $widget.Type
}

# Loading Widgets
Write-Host "`nCreating Loading widgets..."
$loadingWidgets = @(
    @{Path="loading/loading_widgets.dart"; Class="LoadingWidgets"; Desc="Collection of loading widgets"; Type="widget"},
    @{Path="loading/skeleton_loader.dart"; Class="SkeletonLoader"; Desc="Skeleton loading animation"; Type="stateful"},
    @{Path="loading/circular_progress.dart"; Class="CircularProgress"; Desc="Circular progress indicator"; Type="widget"},
    @{Path="loading/linear_progress.dart"; Class="LinearProgress"; Desc="Linear progress indicator"; Type="widget"},
    @{Path="loading/shimmer_effect.dart"; Class="ShimmerEffect"; Desc="Shimmer loading effect"; Type="widget"}
)

foreach ($widget in $loadingWidgets) {
    Create-WidgetFile -FilePath "$basePath/$($widget.Path)" -ClassName $widget.Class -Description $widget.Desc -Type $widget.Type
}

# Lists & Feeds Widgets
Write-Host "`nCreating Lists & Feeds widgets..."
$listWidgets = @(
    @{Path="lists_feeds/feed_item_card.dart"; Class="FeedItemCard"; Desc="Feed item card"; Type="widget"},
    @{Path="lists_feeds/matches_list.dart"; Class="MatchesList"; Desc="Matches list widget"; Type="widget"},
    @{Path="lists_feeds/pull_to_refresh_list.dart"; Class="PullToRefreshList"; Desc="Pull to refresh list"; Type="stateful"},
    @{Path="lists_feeds/search_results_list.dart"; Class="SearchResultsList"; Desc="Search results list"; Type="widget"},
    @{Path="lists_feeds/online_friends_list.dart"; Class="OnlineFriendsList"; Desc="Online friends horizontal list"; Type="widget"}
)

foreach ($widget in $listWidgets) {
    Create-WidgetFile -FilePath "$basePath/$($widget.Path)" -ClassName $widget.Class -Description $widget.Desc -Type $widget.Type
}

# Feed Widgets
Write-Host "`nCreating Feed widgets..."
$feedWidgets = @(
    @{Path="feed/feed_post_card.dart"; Class="FeedPostCard"; Desc="Social feed post card"; Type="widget"},
    @{Path="feed/feed_comment_section.dart"; Class="FeedCommentSection"; Desc="Feed post comments section"; Type="stateful"},
    @{Path="feed/feed_reaction_bar.dart"; Class="FeedReactionBar"; Desc="Feed post reaction bar"; Type="widget"}
)

foreach ($widget in $feedWidgets) {
    Create-WidgetFile -FilePath "$basePath/$($widget.Path)" -ClassName $widget.Class -Description $widget.Desc -Type $widget.Type
}

# Navbar Widgets
Write-Host "`nCreating Navbar widgets..."
$navbarWidgets = @(
    @{Path="navbar/bottom_navbar.dart"; Class="BottomNavbar"; Desc="Bottom navigation bar"; Type="stateful"},
    @{Path="navbar/lgbtinder_logo.dart"; Class="LGBTinderLogo"; Desc="App logo widget"; Type="widget"},
    @{Path="navbar/app_bar_custom.dart"; Class="AppBarCustom"; Desc="Custom app bar"; Type="widget"}
)

foreach ($widget in $navbarWidgets) {
    Create-WidgetFile -FilePath "$basePath/$($widget.Path)" -ClassName $widget.Class -Description $widget.Desc -Type $widget.Type
}

# Modals Widgets
Write-Host "`nCreating Modals widgets..."
$modalWidgets = @(
    @{Path="modals/responsive_modal.dart"; Class="ResponsiveModal"; Desc="Responsive modal dialog"; Type="stateful"},
    @{Path="modals/bottom_sheet_custom.dart"; Class="BottomSheetCustom"; Desc="Custom bottom sheet"; Type="widget"},
    @{Path="modals/confirmation_dialog.dart"; Class="ConfirmationDialog"; Desc="Confirmation dialog"; Type="widget"},
    @{Path="modals/alert_dialog_custom.dart"; Class="AlertDialogCustom"; Desc="Custom alert dialog"; Type="widget"}
)

foreach ($widget in $modalWidgets) {
    Create-WidgetFile -FilePath "$basePath/$($widget.Path)" -ClassName $widget.Class -Description $widget.Desc -Type $widget.Type
}

# Animations Widgets
Write-Host "`nCreating Animations widgets..."
$animationWidgets = @(
    @{Path="animations/animated_components.dart"; Class="AnimatedComponents"; Desc="Collection of animated components"; Type="widget"},
    @{Path="animations/lottie_animations.dart"; Class="LottieAnimations"; Desc="Lottie animation wrapper"; Type="widget"},
    @{Path="animations/match_celebration.dart"; Class="MatchCelebration"; Desc="Match celebration animation"; Type="stateful"},
    @{Path="animations/super_like_animation.dart"; Class="SuperLikeAnimation"; Desc="Super like animation"; Type="stateful"},
    @{Path="animations/heart_animation.dart"; Class="HeartAnimation"; Desc="Heart pop animation"; Type="stateful"},
    @{Path="animations/confetti_animation.dart"; Class="ConfettiAnimation"; Desc="Confetti celebration"; Type="stateful"}
)

foreach ($widget in $animationWidgets) {
    Create-WidgetFile -FilePath "$basePath/$($widget.Path)" -ClassName $widget.Class -Description $widget.Desc -Type $widget.Type
}

# Stories Widgets
Write-Host "`nCreating Stories widgets..."
$storyWidgets = @(
    @{Path="stories/story_viewer.dart"; Class="StoryViewer"; Desc="Story viewer component"; Type="stateful"},
    @{Path="stories/story_ring.dart"; Class="StoryRing"; Desc="Story ring indicator"; Type="widget"},
    @{Path="stories/story_progress_bar.dart"; Class="StoryProgressBar"; Desc="Story progress bar"; Type="stateful"},
    @{Path="stories/story_carousel.dart"; Class="StoryCarousel"; Desc="Stories horizontal carousel"; Type="widget"}
)

foreach ($widget in $storyWidgets) {
    Create-WidgetFile -FilePath "$basePath/$($widget.Path)" -ClassName $widget.Class -Description $widget.Desc -Type $widget.Type
}

# Payment Widgets
Write-Host "`nCreating Payment widgets..."
$paymentWidgets = @(
    @{Path="payment/invoice_payment_handler.dart"; Class="InvoicePaymentHandler"; Desc="Invoice payment handler"; Type="widget"},
    @{Path="payment/payment_intent_handler.dart"; Class="PaymentIntentHandler"; Desc="Payment intent handler"; Type="widget"},
    @{Path="payment/subscription_event_handler.dart"; Class="SubscriptionEventHandler"; Desc="Subscription event handler"; Type="widget"},
    @{Path="payment/plan_card.dart"; Class="PlanCard"; Desc="Subscription plan card"; Type="widget"},
    @{Path="payment/payment_method_tile.dart"; Class="PaymentMethodTile"; Desc="Payment method list tile"; Type="widget"},
    @{Path="payment/subscription_status_card.dart"; Class="SubscriptionStatusCard"; Desc="Subscription status display"; Type="widget"}
)

foreach ($widget in $paymentWidgets) {
    Create-WidgetFile -FilePath "$basePath/$($widget.Path)" -ClassName $widget.Class -Description $widget.Desc -Type $widget.Type
}

# Premium Widgets
Write-Host "`nCreating Premium widgets..."
$premiumWidgets = @(
    @{Path="premium/cancellation_reason_dialog.dart"; Class="CancellationReasonDialog"; Desc="Subscription cancellation dialog"; Type="widget"},
    @{Path="premium/premium_badge.dart"; Class="PremiumBadge"; Desc="Premium badge indicator"; Type="widget"},
    @{Path="premium/retention_offer_dialog.dart"; Class="RetentionOfferDialog"; Desc="Retention offer dialog"; Type="widget"},
    @{Path="premium/premium_feature_card.dart"; Class="PremiumFeatureCard"; Desc="Premium feature card"; Type="widget"}
)

foreach ($widget in $premiumWidgets) {
    Create-WidgetFile -FilePath "$basePath/$($widget.Path)" -ClassName $widget.Class -Description $widget.Desc -Type $widget.Type
}

# Offline Widgets
Write-Host "`nCreating Offline widgets..."
$offlineWidgets = @(
    @{Path="offline/offline_indicator.dart"; Class="OfflineIndicator"; Desc="Offline status indicator"; Type="widget"},
    @{Path="offline/offline_wrapper.dart"; Class="OfflineWrapper"; Desc="Offline state wrapper"; Type="widget"}
)

foreach ($widget in $offlineWidgets) {
    Create-WidgetFile -FilePath "$basePath/$($widget.Path)" -ClassName $widget.Class -Description $widget.Desc -Type $widget.Type
}

# Error Handling Widgets
Write-Host "`nCreating Error Handling widgets..."
$errorWidgets = @(
    @{Path="error_handling/error_boundary.dart"; Class="ErrorBoundary"; Desc="Error boundary widget"; Type="widget"},
    @{Path="error_handling/error_display_widget.dart"; Class="ErrorDisplayWidget"; Desc="Error display widget"; Type="widget"},
    @{Path="error_handling/error_snackbar.dart"; Class="ErrorSnackbar"; Desc="Error snackbar"; Type="widget"},
    @{Path="error_handling/empty_state.dart"; Class="EmptyState"; Desc="Empty state widget"; Type="widget"},
    @{Path="error_handling/retry_button.dart"; Class="RetryButton"; Desc="Retry action button"; Type="widget"}
)

foreach ($widget in $errorWidgets) {
    Create-WidgetFile -FilePath "$basePath/$($widget.Path)" -ClassName $widget.Class -Description $widget.Desc -Type $widget.Type
}

# Splash Widgets
Write-Host "`nCreating Splash widgets..."
$splashWidgets = @(
    @{Path="splash/optimized_splash_page.dart"; Class="OptimizedSplashPage"; Desc="Optimized splash screen"; Type="stateful"},
    @{Path="splash/simple_splash_page.dart"; Class="SimpleSplashPage"; Desc="Simple splash screen"; Type="stateful"}
)

foreach ($widget in $splashWidgets) {
    Create-WidgetFile -FilePath "$basePath/$($widget.Path)" -ClassName $widget.Class -Description $widget.Desc -Type $widget.Type
}

# Gradients Widgets
Write-Host "`nCreating Gradients widgets..."
$gradientWidgets = @(
    @{Path="gradients/lgbt_gradient_system.dart"; Class="LGBTGradientSystem"; Desc="LGBT gradient system"; Type="widget"},
    @{Path="gradients/gradient_background.dart"; Class="GradientBackground"; Desc="Gradient background widget"; Type="widget"}
)

foreach ($widget in $gradientWidgets) {
    Create-WidgetFile -FilePath "$basePath/$($widget.Path)" -ClassName $widget.Class -Description $widget.Desc -Type $widget.Type
}

# Haptic Widgets
Write-Host "`nCreating Haptic widgets..."
$hapticWidgets = @(
    @{Path="haptic/haptic_widgets.dart"; Class="HapticWidgets"; Desc="Haptic feedback widgets"; Type="widget"}
)

foreach ($widget in $hapticWidgets) {
    Create-WidgetFile -FilePath "$basePath/$($widget.Path)" -ClassName $widget.Class -Description $widget.Desc -Type $widget.Type
}

# Rainbow Widgets
Write-Host "`nCreating Rainbow widgets..."
$rainbowWidgets = @(
    @{Path="rainbow/rainbow_components.dart"; Class="RainbowComponents"; Desc="Rainbow/LGBT theme components"; Type="widget"}
)

foreach ($widget in $rainbowWidgets) {
    Create-WidgetFile -FilePath "$basePath/$($widget.Path)" -ClassName $widget.Class -Description $widget.Desc -Type $widget.Type
}

# Real-time Widgets
Write-Host "`nCreating Real-time widgets..."
$realtimeWidgets = @(
    @{Path="real_time/real_time_listener.dart"; Class="RealTimeListener"; Desc="Real-time event listener"; Type="stateful"},
    @{Path="real_time/real_time_widgets.dart"; Class="RealTimeWidgets"; Desc="Real-time widgets collection"; Type="widget"}
)

foreach ($widget in $realtimeWidgets) {
    Create-WidgetFile -FilePath "$basePath/$($widget.Path)" -ClassName $widget.Class -Description $widget.Desc -Type $widget.Type
}

# Sharing Widgets
Write-Host "`nCreating Sharing widgets..."
$sharingWidgets = @(
    @{Path="sharing/sharing_components.dart"; Class="SharingComponents"; Desc="Sharing functionality widgets"; Type="widget"}
)

foreach ($widget in $sharingWidgets) {
    Create-WidgetFile -FilePath "$basePath/$($widget.Path)" -ClassName $widget.Class -Description $widget.Desc -Type $widget.Type
}

# Statistics Widgets
Write-Host "`nCreating Statistics widgets..."
$statWidgets = @(
    @{Path="statistics/statistics_components.dart"; Class="StatisticsComponents"; Desc="Statistics display widgets"; Type="widget"}
)

foreach ($widget in $statWidgets) {
    Create-WidgetFile -FilePath "$basePath/$($widget.Path)" -ClassName $widget.Class -Description $widget.Desc -Type $widget.Type
}

# Super Like Widgets
Write-Host "`nCreating Super Like widgets..."
$superlikeWidgets = @(
    @{Path="super_like/super_like_components.dart"; Class="SuperLikeComponents"; Desc="Super like widgets"; Type="widget"}
)

foreach ($widget in $superlikeWidgets) {
    Create-WidgetFile -FilePath "$basePath/$($widget.Path)" -ClassName $widget.Class -Description $widget.Desc -Type $widget.Type
}

# Templates Widgets
Write-Host "`nCreating Templates widgets..."
$templateWidgets = @(
    @{Path="templates/template_components.dart"; Class="TemplateComponents"; Desc="Template widgets"; Type="widget"}
)

foreach ($widget in $templateWidgets) {
    Create-WidgetFile -FilePath "$basePath/$($widget.Path)" -ClassName $widget.Class -Description $widget.Desc -Type $widget.Type
}

# Theme Widgets
Write-Host "`nCreating Theme widgets..."
$themeWidgets = @(
    @{Path="theme/theme_components.dart"; Class="ThemeComponents"; Desc="Theme-related widgets"; Type="widget"}
)

foreach ($widget in $themeWidgets) {
    Create-WidgetFile -FilePath "$basePath/$($widget.Path)" -ClassName $widget.Class -Description $widget.Desc -Type $widget.Type
}

# Verification Widgets
Write-Host "`nCreating Verification widgets..."
$verificationWidgets = @(
    @{Path="verification/verification_components.dart"; Class="VerificationComponents"; Desc="Verification widgets"; Type="widget"}
)

foreach ($widget in $verificationWidgets) {
    Create-WidgetFile -FilePath "$basePath/$($widget.Path)" -ClassName $widget.Class -Description $widget.Desc -Type $widget.Type
}

# Wizard Widgets
Write-Host "`nCreating Wizard widgets..."
$wizardWidgets = @(
    @{Path="wizard/wizard_components.dart"; Class="WizardComponents"; Desc="Wizard/stepper widgets"; Type="widget"}
)

foreach ($widget in $wizardWidgets) {
    Create-WidgetFile -FilePath "$basePath/$($widget.Path)" -ClassName $widget.Class -Description $widget.Desc -Type $widget.Type
}

# Gamification Widgets
Write-Host "`nCreating Gamification widgets..."
$gamificationWidgets = @(
    @{Path="gamification/gamification_components.dart"; Class="GamificationComponents"; Desc="Gamification widgets"; Type="widget"}
)

foreach ($widget in $gamificationWidgets) {
    Create-WidgetFile -FilePath "$basePath/$($widget.Path)" -ClassName $widget.Class -Description $widget.Desc -Type $widget.Type
}

# Accessibility Widgets
Write-Host "`nCreating Accessibility widgets..."
$accessibilityWidgets = @(
    @{Path="accessibility/accessible_components.dart"; Class="AccessibleComponents"; Desc="Accessibility widgets"; Type="widget"}
)

foreach ($widget in $accessibilityWidgets) {
    Create-WidgetFile -FilePath "$basePath/$($widget.Path)" -ClassName $widget.Class -Description $widget.Desc -Type $widget.Type
}

# Analytics Widgets
Write-Host "`nCreating Analytics widgets..."
$analyticsWidgets = @(
    @{Path="analytics/analytics_components.dart"; Class="AnalyticsComponents"; Desc="Analytics widgets"; Type="widget"}
)

foreach ($widget in $analyticsWidgets) {
    Create-WidgetFile -FilePath "$basePath/$($widget.Path)" -ClassName $widget.Class -Description $widget.Desc -Type $widget.Type
}

# Backup Widgets
Write-Host "`nCreating Backup widgets..."
$backupWidgets = @(
    @{Path="backup/backup_components.dart"; Class="BackupComponents"; Desc="Backup widgets"; Type="widget"}
)

foreach ($widget in $backupWidgets) {
    Create-WidgetFile -FilePath "$basePath/$($widget.Path)" -ClassName $widget.Class -Description $widget.Desc -Type $widget.Type
}

# Export Widgets
Write-Host "`nCreating Export widgets..."
$exportWidgets = @(
    @{Path="export/export_components.dart"; Class="ExportComponents"; Desc="Export widgets"; Type="widget"}
)

foreach ($widget in $exportWidgets) {
    Create-WidgetFile -FilePath "$basePath/$($widget.Path)" -ClassName $widget.Class -Description $widget.Desc -Type $widget.Type
}

# Media Widgets
Write-Host "`nCreating Media widgets..."
$mediaWidgets = @(
    @{Path="media/media_picker_component.dart"; Class="MediaPickerComponent"; Desc="Media picker component"; Type="stateful"}
)

foreach ($widget in $mediaWidgets) {
    Create-WidgetFile -FilePath "$basePath/$($widget.Path)" -ClassName $widget.Class -Description $widget.Desc -Type $widget.Type
}

# Messaging Widgets (additional)
Write-Host "`nCreating Messaging widgets..."
$messagingWidgets = @(
    @{Path="messaging/chat_message_bubble.dart"; Class="ChatMessageBubble"; Desc="Chat message bubble"; Type="widget"},
    @{Path="messaging/message_input_field.dart"; Class="MessageInputField"; Desc="Message input field"; Type="stateful"},
    @{Path="messaging/typing_indicator.dart"; Class="TypingIndicator"; Desc="Typing indicator"; Type="stateful"}
)

foreach ($widget in $messagingWidgets) {
    Create-WidgetFile -FilePath "$basePath/$($widget.Path)" -ClassName $widget.Class -Description $widget.Desc -Type $widget.Type
}

# Common Widgets
Write-Host "`nCreating Common widgets..."
$commonWidgets = @(
    @{Path="common/optimized_image.dart"; Class="OptimizedImage"; Desc="Optimized image widget"; Type="widget"},
    @{Path="common/divider_custom.dart"; Class="DividerCustom"; Desc="Custom divider"; Type="widget"},
    @{Path="common/section_header.dart"; Class="SectionHeader"; Desc="Section header widget"; Type="widget"},
    @{Path="common/list_tile_custom.dart"; Class="ListTileCustom"; Desc="Custom list tile"; Type="widget"}
)

foreach ($widget in $commonWidgets) {
    Create-WidgetFile -FilePath "$basePath/$($widget.Path)" -ClassName $widget.Class -Description $widget.Desc -Type $widget.Type
}

# Additional UI Widgets from Design System
Write-Host "`nCreating Additional UI widgets..."
$additionalWidgets = @(
    @{Path="ui/filter_chip.dart"; Class="FilterChip"; Desc="Filter chip widget"; Type="widget"},
    @{Path="ui/interest_tag.dart"; Class="InterestTag"; Desc="Interest tag with icon"; Type="widget"},
    @{Path="ui/status_indicator.dart"; Class="StatusIndicator"; Desc="Online/offline status indicator"; Type="widget"},
    @{Path="ui/distance_tag.dart"; Class="DistanceTag"; Desc="Distance display tag"; Type="widget"},
    @{Path="ui/profile_badge.dart"; Class="ProfileBadge"; Desc="Profile badge widget"; Type="widget"},
    @{Path="ui/action_button_row.dart"; Class="ActionButtonRow"; Desc="Action buttons row"; Type="widget"},
    @{Path="ui/greeting_header.dart"; Class="GreetingHeader"; Desc="Greeting header with avatar"; Type="widget"},
    @{Path="ui/stats_card.dart"; Class="StatsCard"; Desc="Statistics card"; Type="widget"},
    @{Path="ui/menu_item_tile.dart"; Class="MenuItemTile"; Desc="Menu item list tile"; Type="widget"},
    @{Path="ui/image_indicator_dots.dart"; Class="ImageIndicatorDots"; Desc="Image carousel indicator dots"; Type="widget"}
)

foreach ($widget in $additionalWidgets) {
    Create-WidgetFile -FilePath "$basePath/$($widget.Path)" -ClassName $widget.Class -Description $widget.Desc -Type $widget.Type
}

Write-Host "`nAll widget files created successfully!"

