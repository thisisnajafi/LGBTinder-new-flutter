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
import '../../features/matching/data/models/match.dart';
import '../../core/utils/app_icons.dart';
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
    
    // Heart animation
    _heartController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _heartAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _heartController, curve: Curves.elasticOut),
    );
    
    // Confetti animation
    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _confettiAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _confettiController, curve: Curves.easeOut),
    );
    
    // Scale animation
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
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
              AppColors.accentPurple.withOpacity(0.1),
              AppColors.accentPink.withOpacity(0.1),
              backgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Confetti effect (simplified)
              AnimatedBuilder(
                animation: _confettiAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _confettiAnimation.value,
                    child: Transform.scale(
                      scale: 1.0 + (_confettiAnimation.value * 0.5),
                      child: Icon(
                        Icons.celebration,
                        size: 200,
                        color: AppColors.accentPink.withOpacity(0.3),
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
                        color: AppColors.accentPurple,
                        borderRadius: BorderRadius.circular(AppRadius.radiusRound),
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
                                decoration: BoxDecoration(
                                  color: AppColors.accentPink,
                                  shape: BoxShape.circle,
                                ),
                                child: AppSvgIcon(
                                  assetPath: AppIcons.favorite,
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
                child: Column(
                  children: [
                    GradientButton(
                      text: 'Hai Hello',
                      onPressed: widget.onSendMessage,
                      isFullWidth: true,
                      iconPath: AppIcons.chatBubbleOutline,
                    ),
                    SizedBox(height: AppSpacing.spacingMD),
                    OutlinedButton(
                      onPressed: widget.onKeepSwiping,
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          vertical: AppSpacing.spacingMD,
                        ),
                        side: BorderSide(color: AppColors.accentPurple),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: Text(
                        'Keep Swiping',
                        style: AppTypography.button.copyWith(
                          color: AppColors.accentPurple,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImage({String? imageUrl, required bool isDark}) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.accentPink,
          width: 4,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentPink.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: ClipOval(
        child: imageUrl != null
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: isDark
                        ? AppColors.surfaceDark
                        : AppColors.surfaceLight,
                    child: Icon(
                      Icons.person,
                      size: 60,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  );
                },
              )
            : Container(
                color: isDark
                    ? AppColors.surfaceDark
                    : AppColors.surfaceLight,
                child: Icon(
                  Icons.person,
                  size: 60,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
      ),
    );
  }
}

