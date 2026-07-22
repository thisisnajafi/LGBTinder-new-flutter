import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/api_providers.dart';
import '../providers/connectivity_provider.dart';
import '../responsive/responsive.dart';
import '../services/connectivity_service.dart';
import '../theme/app_colors.dart';
import '../utils/app_icons.dart';

/// Overlays a floating connectivity pill when offline or weak.
/// [NetworkConnectionState.checking] runs silently — no UI is shown.
class ConnectivityBanner extends ConsumerWidget {
  final Widget child;

  const ConnectivityBanner({required this.child, super.key});

  static bool _shouldShowBanner(NetworkConnectionState state) {
    return state == NetworkConnectionState.disconnected ||
        state == NetworkConnectionState.weak;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(connectivityServiceBindingProvider);
    final connectivity = ref.watch(connectivityProvider);

    return connectivity.when(
      loading: () => child,
      error: (_, __) => child,
      data: (state) {
        final visible = _shouldShowBanner(state);

        return Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            child,
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                ignoring: !visible,
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  offset: visible ? Offset.zero : const Offset(0, -1.2),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 250),
                    opacity: visible ? 1 : 0,
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: ResponsivePadding.horizontal(context).copyWith(
                          top: 8,
                        ),
                        child: visible
                            ? _FloatingBanner(state: state)
                            : const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FloatingBanner extends StatelessWidget {
  final NetworkConnectionState state;

  const _FloatingBanner({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final (Color bgColor, String icon, String message) = switch (state) {
      NetworkConnectionState.disconnected => (
          colorScheme.errorContainer,
          AppIcons.wifiOff,
          'No internet connection',
        ),
      NetworkConnectionState.weak => (
          AppColors.feedbackWarning.withValues(alpha: 0.92),
          AppIcons.wifiWeak,
          'Connection is slow — retrying...',
        ),
      NetworkConnectionState.checking ||
      NetworkConnectionState.connected =>
        throw StateError('Only offline/weak states render the floating banner'),
    };

    final onBannerColor = state == NetworkConnectionState.weak
        ? colorScheme.onSurface
        : colorScheme.onErrorContainer;

    return Material(
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha: 0.18),
      color: bgColor,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            AppSvgIcon(
              assetPath: icon,
              size: 18,
              color: onBannerColor,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppText(
                message,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: onBannerColor,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
              ),
            ),
            if (state == NetworkConnectionState.disconnected)
              TextButton(
                onPressed: () =>
                    ConnectivityService.instance.verifyConnection(),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: AppText(
                  'Retry',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: onBannerColor,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
