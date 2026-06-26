// Widget: MatchScreen
// Match celebration screen with animations
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';
import '../../widgets/buttons/gradient_button.dart';
import '../../core/widgets/premium/premium_design_system.dart';
import '../../features/matching/data/models/match.dart';
import '../../core/utils/app_icons.dart';
import '../../core/widgets/avatar_widget.dart';
import '../../core/constants/animation_constants.dart';
import '../../features/auth/providers/auth_provider.dart';

/// Match screen - Celebration screen when a match is detected
class MatchScreen extends ConsumerStatefulWidget {
  final Match match;
  final VoidCallback? onSendMessage;
  final VoidCallback? onKeepSwiping;

  const MatchScreen({
    Key? key,
    required this.match,
    this.onSendMessage,
    this.onKeepSwiping,
  }) : super(key: key);

  @override
  ConsumerState<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends ConsumerState<MatchScreen>
    with TickerProviderStateMixin {
  late AnimationController _heartController;
  late AnimationController _confettiController;
  late AnimationController _scaleController;
  late Animation<double> _heartAnimation;
  late Animation<double> _confettiAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Haptic feedback
    HapticFeedback.mediumImpact();
    
    // Short celebration burst (~1–1.2 s total), minimal — no bounce
    _heartController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _heartAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _heartController, curve: AppAnimations.curveDefault),
    );

    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _confettiAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _confettiController, curve: AppAnimations.curveDefault),
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: AppAnimations.curveDefault),
    );
    
    // Start animations
    _heartController.forward();
    _confettiController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _heartController.dispose();
    _confettiController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    // Get user data from auth provider
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.lgbtGradient[0].withValues(alpha: 0.12),
              AppColors.lgbtGradient[2].withValues(alpha: 0.08),
              AppColors.lgbtGradient[4].withValues(alpha: 0.1),
              backgroundColor,
            ],
            stops: const [0.0, 0.35, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Celebration icon — fade + slight scale, minimal
              AnimatedBuilder(
                animation: _confettiAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _confettiAnimation.value,
                    child: Transform.scale(
                      scale: 0.98 + (_confettiAnimation.value * 0.04),
                      child: AppSvgIcon(
                        assetPath: AppIcons.getIconPath('magic-star'),
                        size: 160,
                        color: AppColors.accentViolet.withValues(alpha: 0.22),
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: AppSpacing.spacingXXL),
              // Match percentage badge
              AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.spacingLG,
                        vertical: AppSpacing.spacingSM,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.radiusRound),
                        gradient: AppColors.brandGradient,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accentViolet.withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        '100% Match',
                        style: AppTypography.h3.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: AppSpacing.spacingXXL),
              // "It's a Match!" heading
              AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Text(
                      'It\'s a Match! 🎉',
                      style: AppTypography.h1Large.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                },
              ),
              SizedBox(height: AppSpacing.spacingMD),
              Text(
                'You and ${widget.match.firstName} liked each other!',
                style: AppTypography.body.copyWith(
                  color: secondaryTextColor,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSpacing.spacingXXL),
              // Profile images with heart frames
              AnimatedBuilder(
                animation: _heartAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 0.8 + (_heartAnimation.value * 0.2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // User's profile image
                        _buildProfileImage(
                          imageUrl: user?.images != null && user!.images!.isNotEmpty
                              ? user.images!.first.toString()
                              : null,
                          isDark: isDark,
                          fallbackInitial: user?.firstName,
                        ),
                        SizedBox(width: AppSpacing.spacingLG),
                        // Heart icon
                        AnimatedBuilder(
                          animation: _heartAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: 0.5 + (_heartAnimation.value * 0.5),
                              child: Container(
                                padding: EdgeInsets.all(AppSpacing.spacingMD),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: AppColors.brandGradient,
                                ),
                                child: AppSvgIcon(
                                  assetPath: AppIcons.heart,
                                  size: 40,
                                  color: Colors.white,
                                ),
                              ),
                            );
                          },
                        ),
                        SizedBox(width: AppSpacing.spacingLG),
                        // Matched user's profile image
                        _buildProfileImage(
                          imageUrl: widget.match.primaryImageUrl,
                          isDark: isDark,
                          fallbackInitial: widget.match.firstName,
                        ),
                      ],
                    ),
                  );
                },
              ),
              SizedBox(height: AppSpacing.spacingXXL),
              // Action buttons
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.spacingXXL),
                child: PremiumShell(
                  margin: EdgeInsets.zero,
                  child: Column(
                    children: [
                      GradientButton(
                        text: 'Say Hello',
                        onPressed: widget.onSendMessage,
                        isFullWidth: true,
                        iconPath: AppIcons.chatBubbleOutline,
                      ),
                      SizedBox(height: AppSpacing.spacingMD),
                      PremiumTapScale(
                        onTap: widget.onKeepSwiping ?? () {},
                        semanticLabel: 'Keep swiping',
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            vertical: AppSpacing.spacingMD,
                          ),
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(AppRadius.radiusMD),
                            border: Border.all(
                              color: AppColors.accentViolet.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Text(
                            'Keep Swiping',
                            style: AppTypography.button.copyWith(
                              color: AppColors.accentViolet,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImage({
    String? imageUrl,
    required bool isDark,
    String? fallbackInitial,
  }) {
    return Container(
      width: 120,
      height: 120,
      padding: const EdgeInsets.all(3),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.brandGradient,
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark ? AppColors.cardBackgroundDark : AppColors.cardBackgroundLight,
        ),
        child: ClipOval(
          child: imageUrl != null
              ? AvatarWidget(
                  imageUrl: imageUrl,
                  radius: 56,
                  fallbackInitial: fallbackInitial,
                )
              : Center(
                  child: AppSvgIcon(
                    assetPath: AppIcons.user,
                    size: 48,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
        ),
      ),
    );
  }
}

