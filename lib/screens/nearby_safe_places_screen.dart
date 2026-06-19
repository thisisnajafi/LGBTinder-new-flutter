import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/typography.dart';
import '../../core/utils/app_icons.dart';
import '../../core/widgets/app_page_scaffold.dart';
import '../../core/location/location_providers.dart';
import '../../core/location/location_required_exception.dart';
import '../../core/location/widgets/location_permission_sheet.dart';
import '../../features/safety/data/models/safe_place.dart';

/// Lists hospitals, police, and fire stations near the user's GPS position.
class NearbySafePlacesScreen extends ConsumerStatefulWidget {
  const NearbySafePlacesScreen({super.key});

  @override
  ConsumerState<NearbySafePlacesScreen> createState() =>
      _NearbySafePlacesScreenState();
}

class _NearbySafePlacesScreenState extends ConsumerState<NearbySafePlacesScreen> {
  List<SafePlace> _places = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPlaces());
  }

  Future<void> _loadPlaces() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final places = await ref
          .read(safetyLocationServiceProvider)
          .getNearbySafePlaces(radiusKm: 10);
      if (!mounted) return;
      setState(() {
        _places = places;
        _isLoading = false;
      });
    } on LocationRequiredException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.message;
      });
      await _promptLocation(permanentlyDenied: e.permanentlyDenied);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _promptLocation({bool permanentlyDenied = false}) async {
    await LocationPermissionSheet.show(
      context,
      permanentlyDenied: permanentlyDenied,
      onEnable: _loadPlaces,
    );
  }

  Future<void> _openMaps(SafePlace place) async {
    final uri = Uri.parse(place.mapsUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'medical':
        return Icons.local_hospital_outlined;
      case 'emergency':
        return Icons.local_police_outlined;
      default:
        return Icons.place_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return AppPageScaffold(
      title: 'Nearby Safe Places',
      showBackButton: true,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError(textColor, secondaryTextColor)
              : _places.isEmpty
                  ? _buildEmpty(textColor, secondaryTextColor)
                  : RefreshIndicator(
                      onRefresh: _loadPlaces,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(AppSpacing.spacingLG),
                        itemCount: _places.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.spacingMD),
                        itemBuilder: (context, index) {
                          final place = _places[index];
                          return _SafePlaceTile(
                            place: place,
                            icon: _iconForType(place.type),
                            textColor: textColor,
                            secondaryTextColor: secondaryTextColor,
                            onTap: () => _openMaps(place),
                          );
                        },
                      ),
                    ),
    );
  }

  Widget _buildError(Color textColor, Color secondaryTextColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.spacingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppSvgIcon(
              assetPath: AppIcons.gpsSlash,
              size: 56,
              color: AppColors.feedbackWarning,
            ),
            const SizedBox(height: AppSpacing.spacingMD),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(color: textColor),
            ),
            const SizedBox(height: AppSpacing.spacingLG),
            FilledButton(
              onPressed: _loadPlaces,
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(Color textColor, Color secondaryTextColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.spacingXL),
        child: Text(
          'No safe places found nearby. Try again or move to a different area.',
          textAlign: TextAlign.center,
          style: AppTypography.body.copyWith(color: secondaryTextColor),
        ),
      ),
    );
  }
}

class _SafePlaceTile extends StatelessWidget {
  const _SafePlaceTile({
    required this.place,
    required this.icon,
    required this.textColor,
    required this.secondaryTextColor,
    required this.onTap,
  });

  final SafePlace place;
  final IconData icon;
  final Color textColor;
  final Color secondaryTextColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.spacingMD),
          child: Row(
            children: [
              Icon(icon, color: AppColors.accentPurple),
              const SizedBox(width: AppSpacing.spacingMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      style: AppTypography.body.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (place.address != null && place.address!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        place.address!,
                        style: AppTypography.caption
                            .copyWith(color: secondaryTextColor),
                      ),
                    ],
                    if (place.distanceLabel != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        place.distanceLabel!,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.accentPurple,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: secondaryTextColor),
            ],
          ),
        ),
      ),
    );
  }
}
