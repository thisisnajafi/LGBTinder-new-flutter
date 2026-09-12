import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/border_radius_constants.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/utils/app_icons.dart';
import '../../../../core/widgets/premium/premium_design_system.dart';
import '../../../../core/responsive/responsive.dart';
import '../../data/models/call.dart';
import '../../utils/call_log_labels.dart';
import '../../utils/messenger_call_groups.dart';

/// Banner at the top of Calls when a call is ringing or active.
class MessengerActiveCallBanner extends StatelessWidget {
  final Call call;
  final int currentUserId;
  final VoidCallback onTap;

  const MessengerActiveCallBanner({
    super.key,
    required this.call,
    required this.currentUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = messengerPeerName(call, currentUserId);
    final connecting = call.status == 'ringing' || call.status == 'initiating';
    final label = connecting ? 'Connecting with $name' : 'On a call with $name';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        PremiumPageHeader.horizontalPadding,
        0,
        PremiumPageHeader.horizontalPadding,
        AppSpacing.spacingSM,
      ),
      child: PremiumTapScale(
        onTap: onTap,
        semanticLabel: label,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.spacingMD,
            vertical: AppSpacing.spacingSM,
          ),
          decoration: BoxDecoration(
            gradient: AppColors.brandGradient,
            borderRadius: BorderRadius.circular(AppRadius.radiusLG),
          ),
          child: Row(
            children: [
              AppSvgIcon(
                assetPath: call.isVideoCall ? AppIcons.video : AppIcons.call,
                size: 20,
                color: Colors.white,
              ),
              const SizedBox(width: AppSpacing.spacingSM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      label,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                      maxLines: 1,
                    ),
                    Text(
                      connecting ? 'Connecting…' : 'Tap to return',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                    ),
                  ],
                ),
              ),
              AppSvgIcon(
                assetPath: AppIcons.arrowRight,
                size: 18,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
