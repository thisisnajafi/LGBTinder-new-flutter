// Widget: MatchCelebration
// Match celebration animation
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';
import '../avatar/avatar_with_status.dart';
import '../buttons/gradient_button.dart';

/// Match celebration animation widget
/// Displays celebration UI when users match
class MatchCelebration extends ConsumerStatefulWidget {
  final String matchedUserName;
  final String? matchedUserAvatarUrl;
  final VoidCallback? onSendMessage;
  final VoidCallback? onKeepSwiping;

  const MatchCelebration({
    Key? key,
    required this.matchedUserName,
    this.matchedUserAvatarUrl,
    this.onSendMessage,
    this.onKeepSwiping,
  }) : super(key: key);

  @override
  ConsumerState<MatchCelebration> createState() => _MatchCelebrationState();
}

class _MatchCelebrationState extends ConsumerState<MatchCelebration>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn,
      ),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return FadeTransition(
      opacity: _opacityAnimation,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.8),
              Colors.black.withOpacity(0.9),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.spacingXXL),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Match text
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Text(
                    'It\'s a Match!',
                    style: AppTypography.h1Large.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: AppSpacing.spacingXXL),
                // Avatars
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AvatarWithStatus(
                      imageUrl: null, // Current user
                      name: 'You',
                      isOnline: false,
                      size: 100.0,
                      showRing: true,
                    ),
                    Container(
                      width: 60,
                      height: 4,
                      margin: EdgeInsets.symmetric(horizontal: AppSpacing.spacingMD),
                      decoration: BoxDecoration(
                        gradient: AppTheme.accentGradient,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    AvatarWithStatus(
                      imageUrl: widget.matchedUserAvatarUrl,
                      name: widget.matchedUserName,
                      isOnline: false,
                      size: 100.0,
                      showRing: true,
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.spacingXXL),
                // Message
                Text(
                  'You and ${widget.matchedUserName} liked each other!',
                  style: AppTypography.h2.copyWith(
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSpacing.spacingXXL),
                // Buttons
                if (widget.onSendMessage != null)
                  GradientButton(
                    text: 'Send Message',
                    onPressed: widget.onSendMessage,
                    isFullWidth: true,
                  ),
                if (widget.onSendMessage != null && widget.onKeepSwiping != null)
                  SizedBox(height: AppSpacing.spacingMD),
                if (widget.onKeepSwiping != null)
                  OutlinedButton(
                    onPressed: widget.onKeepSwiping,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.spacingXXL,
                        vertical: AppSpacing.spacingMD,
                      ),
                      side: BorderSide(color: Colors.white, width: 2),
                    ),
                    child: Text(
                      'Keep Swiping',
                      style: AppTypography.button.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
