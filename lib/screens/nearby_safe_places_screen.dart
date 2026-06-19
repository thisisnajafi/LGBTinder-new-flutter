import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/typography.dart';
import '../../core/utils/app_icons.dart';
import '../../core/widgets/app_settings_detail.dart';
import '../../core/widgets/premium/premium_design_system.dart';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return AppSettingsDetailScaffold(
      title: 'Nearby safe places',
      subtitle: 'Hospitals, police, and fire stations near you',
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError(textColor, secondaryTextColor)
              : _places.isEmpty
                  ? _buildEmpty(textColor, secondaryTextColor)
                  : RefreshIndicator(
                      onRefresh: _loadPlaces,
                      child: AppSettingsDetailList(
                        children: [
                          PremiumSettingsGroup(
                            title: 'Places near you',
                            children: [
                              for (final place in _places)
                                PremiumSettingsTile(
                                  iconPath: AppIcons.location,
                                  title: place.name,
                                  subtitle: [
                                    if (place.address != null &&
                                        place.address!.isNotEmpty)
                                      place.address,
                                    if (place.distanceLabel != null)
                                      place.distanceLabel,
                                  ].whereType<String>().join(' · '),
                                  onTap: () => _openMaps(place),
                                ),
                            ],
                          ),
                        ],
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
