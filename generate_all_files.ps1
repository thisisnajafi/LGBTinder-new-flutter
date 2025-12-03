# Complete file generation script for LGBTinder Flutter app
$basePath = "flutter_app_structure/lib"

# Function to create file with appropriate template
function Create-File {
    param(
        [string]$FilePath,
        [string]$Type,  # "model", "repository", "usecase", "screen", "widget", "provider"
        [string]$Name
    )
    
    $directory = Split-Path -Parent $FilePath
    if (-not (Test-Path $directory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }
    
    $content = switch ($Type) {
        "model" {
            @"
// Model: $Name
class $Name {
  // TODO: Add properties and fromJson/toJson methods
  
  $Name();
  
  factory $Name.fromJson(Map<String, dynamic> json) {
    return $Name();
  }
  
  Map<String, dynamic> toJson() {
    return {};
  }
}
"@
        }
        "repository" {
            @"
// Repository: $Name
import '../models/models.dart';

class $Name {
  // TODO: Implement repository methods
  
  Future<dynamic> getData() async {
    // TODO: Implement
    throw UnimplementedError();
  }
}
"@
        }
        "usecase" {
            @"
// Use Case: $Name
class $Name {
  // TODO: Implement use case
  
  Future<dynamic> execute() async {
    // TODO: Implement
    throw UnimplementedError();
  }
}
"@
        }
        "screen" {
            @"
// Screen: $Name
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class $Name extends ConsumerStatefulWidget {
  const $Name({Key? key}) : super(key: key);

  @override
  ConsumerState<$Name> createState() => _${Name}State();
}

class _${Name}State extends ConsumerState<$Name> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('$Name'),
      ),
      body: const Center(
        child: Text('$Name Screen'),
      ),
    );
  }
}
"@
        }
        "widget" {
            @"
// Widget: $Name
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class $Name extends ConsumerWidget {
  const $Name({Key? key}) : super(key: key);

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
            @"
// Provider: $Name
import 'package:flutter_riverpod/flutter_riverpod.dart';

final ${Name}Provider = StateNotifierProvider<${Name}Notifier, ${Name}State>((ref) {
  return ${Name}Notifier();
});

class ${Name}State {
  // TODO: Add state properties
}

class ${Name}Notifier extends StateNotifier<${Name}State> {
  ${Name}Notifier() : super(${Name}State());
  
  // TODO: Implement state management methods
}
"@
        }
    }
    
    Set-Content -Path $FilePath -Value $content -Encoding UTF8
}

# Auth Feature Files
Write-Host "Creating Auth feature files..."
$authFiles = @(
    @{Path="features/auth/data/models/auth_user.dart"; Type="model"; Name="AuthUser"},
    @{Path="features/auth/data/models/login_request.dart"; Type="model"; Name="LoginRequest"},
    @{Path="features/auth/data/models/register_request.dart"; Type="model"; Name="RegisterRequest"},
    @{Path="features/auth/data/models/otp_request.dart"; Type="model"; Name="OtpRequest"},
    @{Path="features/auth/data/models/social_auth_request.dart"; Type="model"; Name="SocialAuthRequest"},
    @{Path="features/auth/data/repositories/auth_repository.dart"; Type="repository"; Name="AuthRepository"},
    @{Path="features/auth/domain/use_cases/login_use_case.dart"; Type="usecase"; Name="LoginUseCase"},
    @{Path="features/auth/domain/use_cases/register_use_case.dart"; Type="usecase"; Name="RegisterUseCase"},
    @{Path="features/auth/domain/use_cases/logout_use_case.dart"; Type="usecase"; Name="LogoutUseCase"},
    @{Path="features/auth/domain/use_cases/verify_email_use_case.dart"; Type="usecase"; Name="VerifyEmailUseCase"},
    @{Path="features/auth/domain/use_cases/send_otp_use_case.dart"; Type="usecase"; Name="SendOtpUseCase"},
    @{Path="features/auth/domain/use_cases/verify_otp_use_case.dart"; Type="usecase"; Name="VerifyOtpUseCase"},
    @{Path="features/auth/domain/use_cases/reset_password_use_case.dart"; Type="usecase"; Name="ResetPasswordUseCase"},
    @{Path="features/auth/domain/use_cases/social_login_use_case.dart"; Type="usecase"; Name="SocialLoginUseCase"},
    @{Path="features/auth/presentation/screens/welcome_screen.dart"; Type="screen"; Name="WelcomeScreen"},
    @{Path="features/auth/presentation/screens/login_screen.dart"; Type="screen"; Name="LoginScreen"},
    @{Path="features/auth/presentation/screens/register_screen.dart"; Type="screen"; Name="RegisterScreen"},
    @{Path="features/auth/presentation/screens/email_verification_screen.dart"; Type="screen"; Name="EmailVerificationScreen"},
    @{Path="features/auth/presentation/screens/otp_verification_screen.dart"; Type="screen"; Name="OtpVerificationScreen"},
    @{Path="features/auth/presentation/screens/forgot_password_screen.dart"; Type="screen"; Name="ForgotPasswordScreen"},
    @{Path="features/auth/presentation/screens/social_auth_screen.dart"; Type="screen"; Name="SocialAuthScreen"},
    @{Path="features/auth/presentation/widgets/auth_text_field.dart"; Type="widget"; Name="AuthTextField"},
    @{Path="features/auth/presentation/widgets/social_login_button.dart"; Type="widget"; Name="SocialLoginButton"},
    @{Path="features/auth/presentation/widgets/password_field.dart"; Type="widget"; Name="PasswordField"},
    @{Path="features/auth/providers/auth_provider.dart"; Type="provider"; Name="AuthProvider"}
)

foreach ($file in $authFiles) {
    Create-File -FilePath "$basePath/$($file.Path)" -Type $file.Type -Name $file.Name
}

Write-Host "Auth files created!"

# Continue with other features...
Write-Host "Creating remaining feature files (this will take a moment)..."

# Shared files
$sharedFiles = @(
    @{Path="shared/models/api_response.dart"; Type="model"; Name="ApiResponse"},
    @{Path="shared/models/api_error.dart"; Type="model"; Name="ApiError"},
    @{Path="shared/models/pagination.dart"; Type="model"; Name="Pagination"},
    @{Path="shared/services/api_service.dart"; Type="repository"; Name="ApiService"},
    @{Path="shared/services/storage_service.dart"; Type="repository"; Name="StorageService"},
    @{Path="shared/services/websocket_service.dart"; Type="repository"; Name="WebSocketService"},
    @{Path="shared/services/notification_service.dart"; Type="repository"; Name="NotificationService"},
    @{Path="shared/widgets/error_widget.dart"; Type="widget"; Name="ErrorWidget"},
    @{Path="shared/widgets/loading_widget.dart"; Type="widget"; Name="LoadingWidget"}
)

foreach ($file in $sharedFiles) {
    Create-File -FilePath "$basePath/$($file.Path)" -Type $file.Type -Name $file.Name
}

# Routes
$routeFiles = @(
    @{Path="routes/app_router.dart"; Type="repository"; Name="AppRouter"},
    @{Path="routes/route_names.dart"; Type="repository"; Name="RouteNames"},
    @{Path="routes/route_guards.dart"; Type="repository"; Name="RouteGuards"}
)

foreach ($file in $routeFiles) {
    Create-File -FilePath "$basePath/$($file.Path)" -Type $file.Type -Name $file.Name
}

# Main file
$mainContent = @"
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LGBTinder',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const Scaffold(
        body: Center(
          child: Text('LGBTinder App'),
        ),
      ),
    );
  }
}
"@
Set-Content -Path "$basePath/main.dart" -Value $mainContent -Encoding UTF8

Write-Host "All files created successfully!"
Write-Host "Note: Feature files for other modules (profile, discover, chat, etc.) should be created following the same pattern."
Write-Host "See ALL_FLUTTER_FILES_LIST.md for complete file list."

