# PowerShell script to create all Flutter files for LGBTinder app
# Run from: lgbtindernew/flutter_app_structure

$basePath = "lib"

# Function to create a Dart file with basic template
function Create-DartFile {
    param(
        [string]$FilePath,
        [string]$ClassName,
        [string]$Description
    )
    
    $directory = Split-Path -Parent $FilePath
    if (-not (Test-Path $directory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }
    
    $content = @"
// $Description
// TODO: Implement $ClassName

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// $Description
class $ClassName {
  // TODO: Implement class
}
"@
    
    Set-Content -Path $FilePath -Value $content -Encoding UTF8
}

# Core Constants Files
Create-DartFile -FilePath "$basePath/core/constants/api_endpoints.dart" -ClassName "ApiEndpoints" -Description "API endpoint URLs"
Create-DartFile -FilePath "$basePath/core/constants/app_constants.dart" -ClassName "AppConstants" -Description "App-wide constants"
Create-DartFile -FilePath "$basePath/core/constants/animation_constants.dart" -ClassName "AppAnimations" -Description "Animation durations and curves"

# Core Utils Files
Create-DartFile -FilePath "$basePath/core/utils/validators.dart" -ClassName "Validators" -Description "Form validation utilities"
Create-DartFile -FilePath "$basePath/core/utils/formatters.dart" -ClassName "Formatters" -Description "Data formatting utilities"
Create-DartFile -FilePath "$basePath/core/utils/date_utils.dart" -ClassName "DateUtils" -Description "Date utility functions"
Create-DartFile -FilePath "$basePath/core/utils/image_utils.dart" -ClassName "ImageUtils" -Description "Image processing utilities"
Create-DartFile -FilePath "$basePath/core/utils/error_handler.dart" -ClassName "ErrorHandler" -Description "Error handling utilities"

# Core Widgets - Create with widget template
$coreWidgets = @(
    @{File="avatar_ring.dart"; Class="AvatarRing"; Desc="Avatar with gradient ring"},
    @{File="discovery_card.dart"; Class="DiscoveryCard"; Desc="Swipeable profile card"},
    @{File="chat_list_tile.dart"; Class="ChatListTile"; Desc="Chat list item"},
    @{File="gradient_pill_button.dart"; Class="GradientPillButton"; Desc="Primary CTA button"},
    @{File="bottom_glass_nav.dart"; Class="BottomGlassNav"; Desc="Bottom navigation"},
    @{File="profile_stats_card.dart"; Class="ProfileStatsCard"; Desc="Stats display card"},
    @{File="interest_tag.dart"; Class="InterestTag"; Desc="Interest tag with icon"},
    @{File="typing_indicator.dart"; Class="TypingIndicator"; Desc="Animated typing indicator"},
    @{File="match_animation.dart"; Class="MatchAnimation"; Desc="Match celebration"},
    @{File="story_carousel.dart"; Class="StoryCarousel"; Desc="Stories horizontal list"},
    @{File="loading_indicator.dart"; Class="LoadingIndicator"; Desc="Loading states"},
    @{File="empty_state.dart"; Class="EmptyState"; Desc="Empty state widget"}
)

foreach ($widget in $coreWidgets) {
    $filePath = "$basePath/core/widgets/$($widget.File)"
    $directory = Split-Path -Parent $filePath
    if (-not (Test-Path $directory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }
    
    $content = @"
// $($widget.Desc)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// $($widget.Desc)
class $($widget.Class) extends ConsumerWidget {
  const $($widget.Class)({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      // TODO: Implement widget
    );
  }
}
"@
    Set-Content -Path $filePath -Value $content -Encoding UTF8
}

Write-Host "Core files created successfully!"

