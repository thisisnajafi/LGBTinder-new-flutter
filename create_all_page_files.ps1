# PowerShell script to create all page/screen files from existing project
$basePath = "lib"

function Create-EmptyScreenFile {
    param(
        [string]$FilePath,
        [string]$ClassName
    )
    
    $directory = Split-Path -Parent $FilePath
    if (-not (Test-Path $directory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }
    
    if (Test-Path $FilePath) {
        Write-Host "Skipping existing: $FilePath"
        return
    }
    
    $content = @"
// Screen: $ClassName
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class $ClassName extends ConsumerStatefulWidget {
  const $ClassName({Key? key}) : super(key: key);

  @override
  ConsumerState<$ClassName> createState() => _${ClassName}State();
}

class _${ClassName}State extends ConsumerState<$ClassName> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('$ClassName'),
      ),
      body: const Center(
        child: Text('$ClassName'),
      ),
    );
  }
}
"@
    
    Set-Content -Path $FilePath -Value $content -Encoding UTF8
    Write-Host "Created: $FilePath"
}

# All page/screen files from the existing project
$allPages = @(
    # Pages (main navigation)
    @{Path="pages/splash_page.dart"; Class="SplashPage"},
    @{Path="pages/onboarding_page.dart"; Class="OnboardingPage"},
    @{Path="pages/home_page.dart"; Class="HomePage"},
    @{Path="pages/discovery_page.dart"; Class="DiscoveryPage"},
    @{Path="pages/chat_list_page.dart"; Class="ChatListPage"},
    @{Path="pages/chat_page.dart"; Class="ChatPage"},
    @{Path="pages/profile_page.dart"; Class="ProfilePage"},
    @{Path="pages/profile_edit_page.dart"; Class="ProfileEditPage"},
    @{Path="pages/profile_wizard_page.dart"; Class="ProfileWizardPage"},
    @{Path="pages/feed_page.dart"; Class="FeedPage"},
    @{Path="pages/search_page.dart"; Class="SearchPage"},
    @{Path="pages/api_test_page.dart"; Class="ApiTestPage"},
    
    # Auth Screens
    @{Path="screens/auth/auth_wrapper.dart"; Class="AuthWrapper"},
    @{Path="screens/auth/welcome_screen.dart"; Class="WelcomeScreen"},
    @{Path="screens/auth/login_screen.dart"; Class="LoginScreen"},
    @{Path="screens/auth/register_screen.dart"; Class="RegisterScreen"},
    @{Path="screens/auth/email_verification_screen.dart"; Class="EmailVerificationScreen"},
    @{Path="screens/auth/forgot_password_screen.dart"; Class="ForgotPasswordScreen"},
    @{Path="screens/auth/password_reset_flow_screen.dart"; Class="PasswordResetFlowScreen"},
    @{Path="screens/auth/profile_completion_screen.dart"; Class="ProfileCompletionScreen"},
    @{Path="screens/auth/profile_completion_welcome_screen.dart"; Class="ProfileCompletionWelcomeScreen"},
    @{Path="screens/auth/profile_wizard_screen.dart"; Class="ProfileWizardScreen"},
    
    # Onboarding Screens
    @{Path="screens/onboarding/onboarding_screen.dart"; Class="OnboardingScreen"},
    @{Path="screens/onboarding/enhanced_onboarding_screen.dart"; Class="EnhancedOnboardingScreen"},
    @{Path="screens/onboarding/onboarding_preferences_screen.dart"; Class="OnboardingPreferencesScreen"},
    
    # Discovery Screens
    @{Path="screens/discovery/filter_screen.dart"; Class="FilterScreen"},
    @{Path="screens/discovery/likes_received_screen.dart"; Class="LikesReceivedScreen"},
    @{Path="screens/discovery/profile_detail_screen.dart"; Class="ProfileDetailScreen"},
    @{Path="screens/discovery/search_screen.dart"; Class="SearchScreen"},
    
    # Profile Screens
    @{Path="screens/profile_edit_screen.dart"; Class="ProfileEditScreen"},
    @{Path="screens/profile/advanced_profile_customization_screen.dart"; Class="AdvancedProfileCustomizationScreen"},
    @{Path="screens/profile/profile_analytics_screen.dart"; Class="ProfileAnalyticsScreen"},
    @{Path="screens/profile/profile_backup_screen.dart"; Class="ProfileBackupScreen"},
    @{Path="screens/profile/profile_completion_incentives_screen.dart"; Class="ProfileCompletionIncentivesScreen"},
    @{Path="screens/profile/profile_export_screen.dart"; Class="ProfileExportScreen"},
    @{Path="screens/profile/profile_sharing_screen.dart"; Class="ProfileSharingScreen"},
    @{Path="screens/profile/profile_templates_screen.dart"; Class="ProfileTemplatesScreen"},
    @{Path="screens/profile/profile_verification_screen.dart"; Class="ProfileVerificationScreen"},
    
    # Settings Screens
    @{Path="screens/settings_screen.dart"; Class="SettingsScreen"},
    @{Path="screens/settings/account_management_screen.dart"; Class="AccountManagementScreen"},
    @{Path="screens/settings/comprehensive_settings_screen.dart"; Class="ComprehensiveSettingsScreen"},
    @{Path="screens/privacy_settings_screen.dart"; Class="PrivacySettingsScreen"},
    @{Path="screens/notification_settings_screen.dart"; Class="NotificationSettingsScreen"},
    @{Path="screens/safety_settings_screen.dart"; Class="SafetySettingsScreen"},
    @{Path="screens/accessibility_settings_screen.dart"; Class="AccessibilitySettingsScreen"},
    @{Path="screens/haptic_feedback_settings_screen.dart"; Class="HapticFeedbackSettingsScreen"},
    @{Path="screens/animation_settings_screen.dart"; Class="AnimationSettingsScreen"},
    @{Path="screens/image_compression_settings_screen.dart"; Class="ImageCompressionSettingsScreen"},
    @{Path="screens/media_picker_settings_screen.dart"; Class="MediaPickerSettingsScreen"},
    @{Path="screens/pull_to_refresh_settings_screen.dart"; Class="PullToRefreshSettingsScreen"},
    @{Path="screens/skeleton_loader_settings_screen.dart"; Class="SkeletonLoaderSettingsScreen"},
    @{Path="screens/rainbow_theme_settings_screen.dart"; Class="RainbowThemeSettingsScreen"},
    @{Path="screens/group_notification_settings_screen.dart"; Class="GroupNotificationSettingsScreen"},
    @{Path="screens/two_factor_auth_screen.dart"; Class="TwoFactorAuthScreen"},
    @{Path="screens/active_sessions_screen.dart"; Class="ActiveSessionsScreen"},
    
    # Safety Screens
    @{Path="screens/safety_center_screen.dart"; Class="SafetyCenterScreen"},
    @{Path="screens/blocked_users_screen.dart"; Class="BlockedUsersScreen"},
    @{Path="screens/report_history_screen.dart"; Class="ReportHistoryScreen"},
    @{Path="screens/emergency_contacts_screen.dart"; Class="EmergencyContactsScreen"},
    
    # Payment Screens
    @{Path="screens/payment_screen.dart"; Class="PaymentScreen"},
    @{Path="screens/payment_methods_screen.dart"; Class="PaymentMethodsScreen"},
    @{Path="screens/add_payment_method_screen.dart"; Class="AddPaymentMethodScreen"},
    @{Path="screens/subscription_plans_screen.dart"; Class="SubscriptionPlansScreen"},
    @{Path="screens/subscription_management_screen.dart"; Class="SubscriptionManagementScreen"},
    @{Path="screens/premium/premium_subscription_screen.dart"; Class="PremiumSubscriptionScreen"},
    @{Path="screens/premium/superlike_packs_screen.dart"; Class="SuperlikePacksScreen"},
    @{Path="screens/premium_features_screen.dart"; Class="PremiumFeaturesScreen"},
    
    # Chat & Communication Screens
    @{Path="screens/message_search_screen.dart"; Class="MessageSearchScreen"},
    
    # Calls Screens
    @{Path="screens/voice_call_screen.dart"; Class="VoiceCallScreen"},
    @{Path="screens/video_call_screen.dart"; Class="VideoCallScreen"},
    @{Path="screens/call_history_screen.dart"; Class="CallHistoryScreen"},
    
    # Stories Screens
    @{Path="screens/story_creation_screen.dart"; Class="StoryCreationScreen"},
    @{Path="screens/story_viewing_screen.dart"; Class="StoryViewingScreen"},
    
    # Legal Screens
    @{Path="screens/legal/privacy_policy_screen.dart"; Class="PrivacyPolicyScreen"},
    @{Path="screens/legal/terms_of_service_screen.dart"; Class="TermsOfServiceScreen"},
    
    # Help & Support
    @{Path="screens/help_support_screen.dart"; Class="HelpSupportScreen"},
    @{Path="screens/community_forum_screen.dart"; Class="CommunityForumScreen"}
)

Write-Host "Creating all page/screen files..."
$count = 0
foreach ($page in $allPages) {
    Create-EmptyScreenFile -FilePath "$basePath/$($page.Path)" -ClassName $page.Class
    $count++
}

Write-Host "`nTotal page files created: $count"
Write-Host "All page files created successfully!"

