// Screen: ProfileVerificationScreen
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/responsive/responsive.dart';
import '../../core/utils/app_icons.dart';
import '../../core/widgets/app_page_scaffold.dart';
import '../../features/profile/data/models/profile_verification.dart';
import '../../features/profile/providers/profile_provider.dart';
import '../../widgets/loading/shimmer_effect.dart';
import '../../widgets/verification/verification_components.dart';
import '../../widgets/verification/verification_type_card.dart';

/// Profile verification — identity trust (photo / ID / video).
class ProfileVerificationScreen extends ConsumerStatefulWidget {
  const ProfileVerificationScreen({super.key});

  @override
  ConsumerState<ProfileVerificationScreen> createState() =>
      _ProfileVerificationScreenState();
}

class _ProfileVerificationScreenState
    extends ConsumerState<ProfileVerificationScreen> {
  bool _historyVisible = false;
  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profileProvider.notifier).loadVerificationStatus();
      ref.read(profileProvider.notifier).loadVerificationGuidelines();
    });
  }

  VerificationCardStatus _statusForType(
    String type,
    ProfileVerification verification,
    List<VerificationHistoryItem> history,
  ) {
    final verified = switch (type) {
      'id' => verification.idVerified,
      'video' => verification.videoVerified,
      _ => verification.photoVerified,
    };
    if (verified) return VerificationCardStatus.approved;

    final pending = verification.pendingVerifications
        ?.where((p) => p.type == type)
        .toList();
    if (pending != null && pending.isNotEmpty) {
      return VerificationCardStatus.pending;
    }

    final latest = history.where((h) => h.type == type).toList();
    if (latest.isNotEmpty && latest.first.status == 'rejected') {
      return VerificationCardStatus.rejected;
    }

    return VerificationCardStatus.notStarted;
  }

  PendingVerification? _pendingForType(
    String type,
    ProfileVerification verification,
  ) {
    final list = verification.pendingVerifications;
    if (list == null) return null;
    for (final pending in list) {
      if (pending.type == type) return pending;
    }
    return null;
  }

  VerificationHistoryItem? _latestHistoryForType(
    String type,
    List<VerificationHistoryItem> history,
  ) {
    for (final item in history) {
      if (item.type == type) return item;
    }
    return null;
  }

  Future<void> _pickAndSubmit(VerificationType type) async {
    String? path;
    switch (type) {
      case VerificationType.photo:
        path = await _pickPhotoSource();
        break;
      case VerificationType.id:
        path = await _pickIdSource();
        break;
      case VerificationType.video:
        path = await _pickVideo();
        break;
    }
    if (path == null || !mounted) return;

    final file = File(path);
    if (!await file.exists()) return;

    final maxBytes = type == VerificationType.video
        ? 50 * 1024 * 1024
        : 10 * 1024 * 1024;
    if (await file.length() > maxBytes) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            type == VerificationType.video
                ? 'File too large. Maximum size is 50MB for videos.'
                : 'File too large. Maximum size is 10MB for photos and documents.',
          ),
        ),
      );
      return;
    }

    try {
      final notifier = ref.read(profileProvider.notifier);
      switch (type) {
        case VerificationType.photo:
          await notifier.submitPhotoVerification(path);
          break;
        case VerificationType.id:
          await notifier.submitIdVerification(path);
          break;
        case VerificationType.video:
          await notifier.submitVideoVerification(path);
          break;
      }
      if (mounted) {
        await notifier.loadVerificationHistory();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<String?> _pickPhotoSource() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: AppSvgIcon(assetPath: AppIcons.camera, size: 22),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: AppSvgIcon(assetPath: AppIcons.gallery, size: 22),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return null;
    final picked = await _imagePicker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1920,
    );
    return picked?.path;
  }

  Future<String?> _pickIdSource() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: AppSvgIcon(assetPath: AppIcons.gallery, size: 22),
              title: const Text('Photo (Gallery)'),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
            ListTile(
              leading: AppSvgIcon(assetPath: AppIcons.camera, size: 22),
              title: const Text('Photo (Camera)'),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            ListTile(
              leading: AppSvgIcon(assetPath: AppIcons.document, size: 22),
              title: const Text('PDF Document'),
              onTap: () => Navigator.pop(ctx, 'pdf'),
            ),
          ],
        ),
      ),
    );
    if (choice == null) return null;
    if (choice == 'pdf') {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
      );
      return result?.files.single.path;
    }
    final source =
        choice == 'camera' ? ImageSource.camera : ImageSource.gallery;
    final picked = await _imagePicker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1920,
    );
    return picked?.path;
  }

  Future<String?> _pickVideo() async {
    final picked = await _imagePicker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 2),
    );
    return picked?.path;
  }

  Future<void> _confirmCancel(int verificationId) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.spacingLG),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Cancel this submission?',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: AppSpacing.spacingSM),
                Text(
                  'Your uploaded file will be deleted.',
                  style: theme.textTheme.bodySmall,
                ),
                SizedBox(height: AppSpacing.spacingLG),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Keep Submission'),
                ),
                SizedBox(height: AppSpacing.spacingSM),
                OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                    side: BorderSide(color: theme.colorScheme.error),
                  ),
                  child: const Text('Yes, Cancel'),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref
          .read(profileProvider.notifier)
          .cancelVerification(verificationId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final isLoading = ref.watch(
      profileProvider.select((s) => s.isVerificationLoading),
    );
    final verification = ref.watch(
      profileProvider.select((s) => s.verification),
    );
    final guidelines = ref.watch(
      profileProvider.select((s) => s.verificationGuidelines),
    );
    final history = ref.watch(
      profileProvider.select((s) => s.verificationHistory),
    );
    final uploadState = ref.watch(
      profileProvider.select((s) => s.verificationUpload),
    );
    final error = ref.watch(profileProvider.select((s) => s.error));

    return AppPageScaffold(
      title: 'Verification',
      showBackButton: true,
      backgroundColor: backgroundColor,
      body: isLoading && verification == null
          ? _buildLoadingShimmer(context)
          : verification == null
              ? _buildErrorState(context, error)
              : _buildContent(
                  context,
                  verification: verification,
                  guidelines: guidelines,
                  history: history,
                  uploadState: uploadState,
                ),
    );
  }

  Widget _buildLoadingShimmer(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.colorScheme.surfaceContainerHighest;
    return ListView(
      padding: ResponsivePadding.page(context),
      children: [
        ShimmerEffect(
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              color: base,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        SizedBox(height: AppSpacing.spacingMD),
        for (var i = 0; i < 3; i++) ...[
          ShimmerEffect(
            child: Container(
              height: 160,
              decoration: BoxDecoration(
                color: base,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          SizedBox(height: AppSpacing.spacingMD),
        ],
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, String? error) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.spacingLG),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppSvgIcon(
              assetPath: AppIcons.danger,
              size: 40,
              color: theme.colorScheme.error,
            ),
            SizedBox(height: AppSpacing.spacingMD),
            Text(
              error ?? 'Failed to load verification status',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            SizedBox(height: AppSpacing.spacingLG),
            FilledButton(
              onPressed: () {
                ref.read(profileProvider.notifier).loadVerificationStatus();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context, {
    required ProfileVerification verification,
    required VerificationGuidelines? guidelines,
    required List<VerificationHistoryItem> history,
    required VerificationUploadState uploadState,
  }) {
    return ListView(
      padding: ResponsivePadding.page(context),
      children: [
        _buildHeader(context, verification),
        SizedBox(height: AppSpacing.spacingLG),
        _buildProgressBar(context, verification),
        SizedBox(height: AppSpacing.spacingXL),
        ...VerificationType.values.map((type) {
          final typeKey = type.name;
          final status = _statusForType(typeKey, verification, history);
          final pending = _pendingForType(typeKey, verification);
          final latest = _latestHistoryForType(typeKey, history);
          final isUploading = uploadState.isUploading &&
              uploadState.activeType == typeKey;

          return VerificationTypeCard(
            type: type,
            status: status,
            adminNotes: latest?.adminNotes,
            submittedAt: pending?.submittedAt,
            reviewedAt: latest?.status == 'approved'
                ? latest?.reviewedAt
                : null,
            pendingVerificationId: pending?.id,
            guidelinesText: guidelines?.descriptionFor(typeKey) ?? '',
            isUploading: isUploading,
            uploadProgress: isUploading ? uploadState.progress : 0,
            onUpload: () => _pickAndSubmit(type),
            onCancel: pending != null
                ? () => _confirmCancel(pending.id)
                : null,
          );
        }),
        _buildHistorySection(context, history),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, ProfileVerification verification) {
    final theme = Theme.of(context);
    final score = verification.verificationScore;
    final tint = verificationScoreTint(context, score);

    return Column(
      children: [
        AppSvgIcon(
          assetPath: AppIcons.shieldTick,
          size: 64,
          color: tint,
        ),
        SizedBox(height: AppSpacing.spacingSM),
        Text(
          verification.verificationBadge,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: tint,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: AppSpacing.spacingXS),
        Text(
          '${verification.verificationScore}/100',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(
    BuildContext context,
    ProfileVerification verification,
  ) {
    final theme = Theme.of(context);
    final animate = !MediaQuery.of(context).disableAnimations;
    final segments = [
      ('Photo', 0.30, verification.photoVerified),
      ('ID', 0.40, verification.idVerified),
      ('Video', 0.30, verification.videoVerified),
    ];

    return Column(
      children: [
        Row(
          children: segments.map((seg) {
            final filled = seg.$3;
            return Expanded(
              flex: (seg.$2 * 100).round(),
              child: Padding(
                padding: EdgeInsets.only(
                  right: seg != segments.last ? 4 : 0,
                ),
                child: AnimatedContainer(
                  duration: animate
                      ? const Duration(milliseconds: 600)
                      : Duration.zero,
                  curve: Curves.easeOutCubic,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    color: filled
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.12),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        SizedBox(height: AppSpacing.spacingSM),
        Row(
          children: segments.map((seg) {
            final filled = seg.$3;
            final points = (seg.$2 * 100).round();
            return Expanded(
              flex: points,
              child: Text(
                '${seg.$1} · ${points}pts',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: filled
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.45),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildHistorySection(
    BuildContext context,
    List<VerificationHistoryItem> history,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Submission History',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() => _historyVisible = !_historyVisible);
                if (!_historyVisible) return;
                ref.read(profileProvider.notifier).loadVerificationHistory();
              },
              child: Text(_historyVisible ? 'Hide' : 'Show'),
            ),
          ],
        ),
        AnimatedSize(
          duration: MediaQuery.of(context).disableAnimations
              ? Duration.zero
              : const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          child: _historyVisible
              ? history.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.spacingLG,
                      ),
                      child: Text(
                        'No previous submissions',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.55),
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        for (var i = 0; i < history.length; i++) ...[
                          VerificationHistoryCard(item: history[i]),
                          if (i < history.length - 1)
                            SizedBox(height: AppSpacing.spacingSM),
                        ],
                      ],
                    )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
