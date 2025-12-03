// Screen: WelcomeScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';
import '../../widgets/buttons/gradient_button.dart';
import '../../widgets/buttons/animated_button.dart';
import '../../widgets/navbar/lgbtinder_logo.dart';
import 'package:go_router/go_router.dart';

/// Welcome screen - First screen for authentication flow
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Rainbow gradient colors (LGBTQ+ Pride flag colors)
    final rainbowGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFE40303), // Red
        Color(0xFFFF8C00), // Orange
        Color(0xFFFFED00), // Yellow
        Color(0xFF008026), // Green
        Color(0xFF004DFF), // Blue
        Color(0xFF750787), // Purple
      ],
      stops: const [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
    );

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: rainbowGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.spacingXXL),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                // App logo
                Container(
                  padding: EdgeInsets.all(AppSpacing.spacingXL),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: LGBTinderLogo(size: 80),
                ),
                SizedBox(height: AppSpacing.spacingXXL),
                // App name
                Text(
                  'LGBTinder',
                  style: AppTypography.h1Large.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                SizedBox(height: AppSpacing.spacingMD),
                Text(
                  'Find your perfect match',
                  style: AppTypography.h3.copyWith(
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSpacing.spacingXXL),
                Text(
                  'A safe and inclusive space to connect with like-minded people',
                  style: AppTypography.body.copyWith(
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                // Buttons
                GradientButton(
                  text: 'Create Account',
                  onPressed: () {
                    context.go('/register');
                  },
                  isFullWidth: true,
                ),
                SizedBox(height: AppSpacing.spacingMD),
                AnimatedButton(
                  text: 'Sign In',
                  onPressed: () {
                    context.go('/login');
                  },
                  backgroundColor: Colors.white,
                  textColor: AppColors.accentPurple,
                  isFullWidth: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
