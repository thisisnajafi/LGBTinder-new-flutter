import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/api_providers.dart';
import '../providers/connectivity_provider.dart';
import '../services/connectivity_service.dart';
import '../theme/app_colors.dart';
import '../utils/app_icons.dart';

/// Persistent top banner reflecting real-time connectivity state.
class ConnectivityBanner extends ConsumerWidget {
  final Widget child;

  const ConnectivityBanner({required this.child, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(connectivityServiceBindingProvider);
    final connectivity = ref.watch(connectivityProvider);

    return connectivity.when(
      loading: () => child,
      error: (_, __) => child,
      data: (state) => Column(
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            child: state == NetworkConnectionState.connected
                ? const SizedBox.shrink()
                : _Banner(state: state),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  final NetworkConnectionState state;

  const _Banner({required this.state});

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
          AppColors.feedbackWarning.withValues(alpha: 0.85),
          AppIcons.wifiWeak,
          'Connection is slow — retrying...',
        ),
      NetworkConnectionState.checking => (
          colorScheme.surfaceContainerHighest,
          AppIcons.wifi,
          'Checking connection...',
        ),
      NetworkConnectionState.connected =>
        throw StateError('Connected state hides banner'),
    };

    final onBannerColor = state == NetworkConnectionState.weak
        ? colorScheme.onSurface
        : colorScheme.onErrorContainer;

    return Material(
      color: bgColor,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 8, 8),
          child: Row(
            children: [
              AppSvgIcon(
                assetPath: icon,
                size: 16,
                color: onBannerColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: onBannerColor,
                  ),
                ),
              ),
              if (state == NetworkConnectionState.disconnected)
                TextButton(
                  onPressed: () =>
                      ConnectivityService.instance.verifyConnection(),
                  child: Text(
                    'Retry',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: onBannerColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
